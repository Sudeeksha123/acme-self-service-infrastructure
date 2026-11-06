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
      cost_center = "engineering"
      managed_by  = "terraform"
      project     = "acme-self-service"
    }
  }
}

# Verify AWS authentication
data "aws_caller_identity" "current" {}

# Find a current Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 1. Create VPC
resource "aws_vpc" "acme" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "acme-dev-vpc"
  }
}

# 2. Create public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.acme.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "acme-dev-subnet"
  }
}

# 3. Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.acme.id

  tags = {
    Name = "acme-dev-igw"
  }
}

# 4. Public routing
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.acme.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "acme-dev-routes"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# 5. Allow HTTP access
resource "aws_security_group" "web" {
  name_prefix = "acme-dev-web-"
  description = "Allow HTTP for Acme demo"
  vpc_id      = aws_vpc.acme.id

  ingress {
    description = "Public HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "acme-dev-web-sg"
  }
}

# 6. Provision EC2 and install website
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    set -eux
    dnf install -y httpd
    systemctl enable httpd

    cat > /var/www/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html>
    <head>
      <title>Acme Development Environment</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          background: #101827;
          color: white;
          text-align: center;
          padding: 100px 20px;
        }
        h1 { color: #63e6be; }
        p { font-size: 20px; }
      </style>
    </head>
    <body>
      <h1>Acme Development Environment</h1>
      <h2>Infrastructure Provisioned Successfully!</h2>
      <p>Powered by HashiCorp Terraform and AWS</p>
      <p>Environment: Development</p>
      <p>Managed through Infrastructure as Code</p>
    </body>
    </html>
    HTML

    systemctl start httpd
  EOF

  tags = {
    Name = "acme-dev-web-server"
  }
}

# Outputs
output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "vpc_id" {
  value = aws_vpc.acme.id
}

output "website_url" {
  description = "Acme development website"
  value       = "http://${aws_instance.web.public_ip}"
}
# Trigger HCP Terraform infrastructure provisioning
