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

# SSHkey (stored inside terraform/keys)
resource "aws_key_pair" "deploy_key" {
  key_name   = "sample-key"
  public_key = file("${path.module}/keys/sample-key.pub")
}

# Security group for SSH (22) and HTTP (80)
resource "aws_security_group" "web_sg" {
  name        = "sample-web-sg-1"
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

# EC2 instance with Amazon Linux 2
resource "aws_instance" "web" {
  ami                    = "ami-001db41e42e1ff69f"  # ✅ Latest Amazon Linux 2 in eu-north-1
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.deploy_key.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "sample-ec2"
  }

  # Provisioner to create user "hanubunu" and copy SSH key
  provisioner "remote-exec" {
    inline = [
      "sudo adduser hanubunu",
      "sudo mkdir -p /home/hanubunu/.ssh",
      "sudo cp /home/ec2-user/.ssh/authorized_keys /home/hanubunu/.ssh/",
      "sudo chown -R hanubunu:hanubunu /home/hanubunu/.ssh",
      "sudo chmod 700 /home/hanubunu/.ssh",
      "sudo chmod 600 /home/hanubunu/.ssh/authorized_keys"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"  # default Amazon Linux user
      private_key = file("${path.module}/keys/sample-key")
      host        = self.public_ip
    }
  }
}

# Output public IP
output "public_ip" {
  value = aws_instance.web.public_ip
}
