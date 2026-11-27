# Terraform module: Amazon EKS cluster
# Provision an EKS cluster with a managed node group and OIDC provider.
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.13"
    }
  }
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "px-eks"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID to deploy the cluster into"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for cluster nodes"
  type        = list(string)
}

variable "node_instance_type" {
  description = "EC2 instance type for managed node group"
  type        = string
  default     = "t3.medium"
}

variable "node_capacity_type" {
  description = "Capacity type: ON_DEMAND or SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 4
}

variable "min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

resource "aws_iam_role" "cluster" {
  name               = "${var.cluster_name}-cluster"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "eks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster" {
  for_each = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ]
  role       = aws_iam_role.cluster.name
  policy_arn = each.value
}

resource "aws_iam_role" "nodes" {
  name               = "${var.cluster_name}-nodes"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "nodes" {
  for_each = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
  role       = aws_iam_role.nodes.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "nodes" {
  name = "${var.cluster_name}-nodes"
  role = aws_iam_role.nodes.name
}

resource "aws_security_group" "cluster" {
  name_prefix = "${var.cluster_name}-"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from the internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.cluster_name}-cluster" })
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = "1.29"

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.cluster.id]
    endpoint_private_access = false
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster
  ]

  tags = var.tags
}

resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = var.subnet_ids

  instance_types = [var.node_instance_type]
  capacity_type  = var.node_capacity_type

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  tags = merge(var.tags, { Name = "${var.cluster_name}-nodes" })

  depends_on = [
    aws_iam_role_policy_attachment.nodes
  ]
}

resource "aws_iam_oidc_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [aws_eks_cluster.this.identity[0].oidc[0].thumbprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "kubernetes_deployment" "metallb" {
  metadata {
    name      = "metallb-controller"
    namespace = "metallb-system"
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "metallb-controller" }
    }
    template {
      metadata {
        labels = { app = "metallb-controller" }
      }
      spec {
        container {
          image = "registry.k8s.io/metallb/controller:v0.14.2"
          name  = "controller"
        }
      }
    }
  }
}

output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  value     = aws_eks_cluster.this.certificate_authority[0].data
  sensitive = true
}

output "oidc_provider_arn" {
  value = aws_iam_oidc_provider.cluster.arn
}
