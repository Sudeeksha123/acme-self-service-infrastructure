terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "acme_demo" {
  bucket_prefix = "acme-self-service-demo-"

  tags = {
    Name        = "Acme Demo Storage"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Project     = "acme-self-service"
  }
}

resource "aws_s3_bucket_public_access_block" "acme_demo" {
  bucket = aws_s3_bucket.acme_demo.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "s3_bucket_name" {
  value = aws_s3_bucket.acme_demo.bucket
}
