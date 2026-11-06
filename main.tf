terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# AWS Provider
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      owner       = "acme-dev-team"
      environment = "dev"
      cost_center = "engineering"
      managed_by  = "terraform"
      project     = "acme-self-service"
    }
  }
}

# Verify AWS Authentication
data "aws_caller_identity" "current" {}

# ==========================================
# STAGE 1: NETWORK PROVISIONING
# ==========================================

# Create VPC
resource "aws_vpc" "acme" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "acme-dev-vpc"
  }
}

# Create Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.acme.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "acme-dev-public-subnet"
  }
}

# ==========================================
# OUTPUTS
# ==========================================

output "aws_account_id" {
  description = "AWS account connected to HCP Terraform"
  value       = data.aws_caller_identity.current.account_id
}

output "vpc_id" {
  description = "ID of the provisioned Acme VPC"
  value       = aws_vpc.acme.id
}

output "subnet_id" {
  description = "ID of the provisioned public subnet"
  value       = aws_subnet.public.id
}
