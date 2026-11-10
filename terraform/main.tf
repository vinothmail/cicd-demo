terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
 backend "s3" {
    bucket       = "vinoth-cicd-tfstate-101126"
    key          = "cicd-demo/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "ap-south-1"   # Mumbai; change if you prefer another region
}

# Latest Ubuntu 24.04 AMI from Canonical
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "web" {
  key_name   = "web-key"
  public_key = file("/var/lib/jenkins/.ssh/devops-key.pub")
}

resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Allow SSH and HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # learning only; restrict later
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]   # only machines inside your VPC, such as Jenkins
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.web.key_name
  vpc_security_group_ids = [aws_security_group.web.id]

  tags = {
    Name = "web-server"
  }
}

output "web_public_ip" {
  value = aws_instance.web.public_ip
}

output "web_private_ip" {
  value = aws_instance.web.private_ip
}
