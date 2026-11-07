
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      owner       = "acme-dev-team"
      environment = "dev"
      managed_by  = "terraform"
      project     = "acme-self-service"
    }
  }
}

# Verify AWS authentication
data "aws_caller_identity" "current" {}

# Provision an S3 bucket
resource "aws_s3_bucket" "acme_demo" {
  bucket_prefix = "acme-self-service-demo-"

  tags = {
    Name = "Acme Self-Service Demo"
  }
}

# Prevent public access
resource "aws_s3_bucket_public_access_block" "acme_demo" {
  bucket = aws_s3_bucket.acme_demo.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Display the AWS account
output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

# Display the created bucket
output "s3_bucket_name" {
  value = aws_s3_bucket.acme_demo.id
}

output "s3_bucket_region" {
  value = aws_s3_bucket.acme_demo.region
}
