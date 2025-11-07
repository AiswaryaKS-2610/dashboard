terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.4.0"
}

provider "aws" {
  region = "eu-north-1"
}

# SSH key (stored inside terraform/keys)
resource "aws_key_pair" "deploy_key" {
  key_name   = "sample-key"
  public_key = file("${path.module}/keys/sample-key.pub")
}

# Security group for SSH (22) and HTTP (80)
resource "aws_security_group" "web_sg" {
  name        = "sample-web-sg"
  description = "Allow SSH and HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instance
resource "aws_instance" "web" {
  ami                    = "ami-00d87e4f3b92e2b53"  # ✅ Ubuntu 22.04 LTS for eu-north-1
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deploy_key.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "sample-ec2"
  }
}

# Output public IP
output "public_ip" {
  value = aws_instance.web.public_ip
}
