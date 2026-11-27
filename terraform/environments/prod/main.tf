# Production environment - orchestrates all modules
module "eks" {
  source          = "../../modules/k8s-eks"
  cluster_name    = "px-eks-prod"
  region          = "us-east-1"
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids
  node_instance_type = var.node_instance_type
  desired_size    = 3
  max_size        = 6
  min_size        = 2
  tags            = var.common_tags
}

module "rds" {
  source = "../../modules/rds"
  identifier         = "px-rds-prod"
  engine             = "postgres"
  engine_version     = "15.7"
  instance_class     = "db.t3.medium"
  allocated_storage  = 200
  storage_type       = "gp3"
  db_name            = "pxdb"
  username           = var.db_username
  password           = var.db_password
  subnet_ids         = var.subnet_ids
  security_group_ids = var.database_security_group_ids
  multi_az           = true
  backup_retention   = 7
  tags               = var.common_tags
}

module "elasticache" {
  source = "../../modules/elasticache"
  cluster_id         = "px-redis-prod"
  engine             = "redis"
  node_type          = "cache.t3.micro"
  num_cache_nodes    = 2
  parameter_group    = "default.redis7"
  subnet_ids         = var.subnet_ids
  security_group_ids = var.cache_security_group_ids
  transit_encryption_enabled    = true
  at_rest_encryption_enabled    = true
  tags               = var.common_tags
}

module "s3" {
  source  = "../../modules/s3"
  bucket  = var.assets_bucket
  acl     = "private"
  versioning = true
  tags    = var.common_tags
}

module "cloudfront" {
  source = "../../modules/cloudfront"
  origin_domain = module.s3.bucket_domain_name
  origin_id     = "S3-px-assets"
  aliases       = var.cloudfront_aliases
  certificate_arn = var.acm_certificate_arn
  tags          = var.common_tags
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "node_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "database_security_group_ids" {
  type = list(string)
  default = []
}

variable "cache_security_group_ids" {
  type = list(string)
  default = []
}

variable "assets_bucket" {
  type = string
}

variable "cloudfront_aliases" {
  type    = list(string)
  default = []
}

variable "acm_certificate_arn" {
  type    = string
  default = ""
}

variable "common_tags" {
  type    = map(string)
  default = {
    environment = "production"
    managed-by  = "terraform"
    project     = "px-infrastructure"
  }
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "rds_endpoint" {
  value     = module.rds.endpoint
  sensitive = true
}

output "redis_endpoint" {
  value     = module.elasticache.primary_endpoint
  sensitive = true
}

output "cloudfront_domain" {
  value = module.cloudfront.domain_name
}
