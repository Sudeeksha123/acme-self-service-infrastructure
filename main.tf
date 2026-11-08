
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

# S3 bucket for ACME self-service provisioning
resource "aws_s3_bucket" "acme_demo" {
  bucket_prefix = "acme-self-service-demo-"

  tags = {
    Name        = "Acme Demo Storage"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Project     = "acme-self-service"
    Owner       = "Platform-Team"
    CostCenter  = "Engineering"
  }
}

# Prevent public access to the S3 bucket
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

# Find Amazon Linux 2023 AMI
data "aws_ami" "acme_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Provision ACME development server
resource "aws_instance" "acme_dev" {
  ami           = data.aws_ami.acme_linux.id
  instance_type = "t3.micro"

  # Reuse existing AWS networking
  subnet_id = "subnet-00d25d7f3eef41262"

  # No public IP or inbound access needed for demo
  associate_public_ip_address = false

  tags = {
    Name        = "acme-dev-server"
    Environment = "dev"
    Project     = "acme-self-service"
    ManagedBy   = "terraform"
    Owner       = "Platform-Team"
    CostCenter  = "Engineering"
  }
}

# Output EC2 instance details
output "ec2_instance_id" {
  value = aws_instance.acme_dev.id
}

output "ec2_private_ip" {
  value = aws_instance.acme_dev.private_ip
}
