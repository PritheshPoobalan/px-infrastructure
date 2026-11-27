# Terraform module: AWS CloudFront distribution
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "origin_domain" {
  description = "Origin domain name (S3 website or ALB)"
  type        = string
}

variable "origin_id" {
  description = "Origin identifier"
  type        = string
  default     = "S3-px"
}

variable "aliases" {
  description = "CNAME aliases (custom domains)"
  type        = list(string)
  default     = []
}

variable "certificate_arn" {
  description = "ACM certificate ARN for custom domain"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

resource "aws_cloudfront_origin_access_identity" "this" {
  comment = "OAI for ${var.origin_id}"
}

resource "aws_cloudfront_distribution" "this" {
  origin {
    domain_name = var.origin_domain
    origin_id   = var.origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = var.aliases

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.origin_id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.certificate_arn == ""
    acm_certificate_arn            = var.certificate_arn != "" ? var.certificate_arn : null
    ssl_support_method             = "sni-only"
  }

  tags = var.tags
}

output "domain_name" {
  value = aws_cloudfront_distribution.this.domain_name
}
