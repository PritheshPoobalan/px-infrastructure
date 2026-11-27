# Terraform module: AWS RDS (PostgreSQL)
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "identifier" {
  description = "RDS instance identifier"
  type        = string
  default     = "px-rds"
}

variable "engine" {
  description = "Database engine"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = "15.7"
}

variable "instance_class" {
  description = "Instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type"
  type        = string
  default     = "gp3"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "pxdb"
}

variable "username" {
  description = "Master username"
  type        = string
  default     = "admin"
}

variable "password" {
  description = "Master password"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs"
  type        = list(string)
  default     = []
}

variable "multi_az" {
  description = "Enable Multi-AZ"
  type        = bool
  default     = true
}

variable "backup_retention" {
  description = "Backup retention in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_db_instance" "this" {
  identifier       = var.identifier
  engine           = var.engine
  engine_version   = var.engine_version
  instance_class   = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = var.storage_type
  db_name           = var.db_name
  username          = var.username
  password          = var.password
  db_subnet_group_name = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.security_group_ids
  multi_az            = var.multi_az
  backup_retention_period = var.backup_retention
  skip_final_snapshot   = true
  deletion_protection   = false
  tags                  = var.tags
}

output "endpoint" {
  value       = aws_db_instance.this.endpoint
  sensitive   = true
}

output "port" {
  value = aws_db_instance.this.port
}

output "address" {
  value       = aws_db_instance.this.address
  sensitive   = true
}
