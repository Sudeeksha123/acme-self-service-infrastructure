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
}

# Verify Terraform can authenticate to AWS
data "aws_caller_identity" "current" {}

output "aws_account_id" {
  description = "AWS account connected to HCP Terraform"
  value       = data.aws_caller_identity.current.account_id
}
