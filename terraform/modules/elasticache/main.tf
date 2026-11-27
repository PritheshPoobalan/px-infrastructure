# Terraform module: AWS ElastiCache (Redis)
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "cluster_id" {
  description = "Replication cluster ID"
  type        = string
  default     = "px-redis"
}

variable "engine" {
  description = "Engine (redis or memcached)"
  type        = string
  default     = "redis"
}

variable "node_type" {
  description = "Cache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "num_cache_nodes" {
  description = "Number of cache nodes"
  type        = number
  default     = 1
}

variable "parameter_group" {
  description = "Parameter group family"
  type        = string
  default     = "default.redis7"
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs"
  type        = list(string)
  default     = []
}

variable "transit_encryption" {
  description = "Enable encryption in transit"
  type        = bool
  default     = true
}

variable "at_rest_encryption" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.cluster_id}-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id          = var.cluster_id
  replication_group_description = "Px Redis cache"
  engine                        = var.engine
  node_type                     = var.node_type
  number_cache_clusters         = var.num_cache_nodes
  parameter_group_name          = var.parameter_group
  subnet_group_name             = aws_elasticache_subnet_group.this.name
  security_group_ids            = var.security_group_ids
  transit_encryption_enabled    = var.transit_encryption
  at_rest_encryption_enabled    = var.at_rest_encryption
  automatic_failover_enabled    = var.num_cache_nodes > 1
  multi_zone_enabled            = var.num_cache_nodes > 1
  tags                          = var.tags
}

output "primary_endpoint" {
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
  sensitive   = true
}

output "port" {
  value = aws_elasticache_replication_group.this.primary_endpoint_port
}
