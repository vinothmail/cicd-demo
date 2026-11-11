variable "worker_count" {
  description = "Number of k3s worker nodes (0 = single-node cluster)"
  type        = number
  default     = 1
}

resource "aws_security_group" "k3s" {
  name        = "k3s-sg"
  description = "k3s cluster nodes"

  # SSH from inside the VPC (Jenkins runs Ansible over the private IP)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  # Kubernetes API, from inside the VPC (kubectl from Jenkins)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  # Node Exporter, from inside the VPC (Prometheus)
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  # The app, exposed later as a NodePort
  ingress {
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All traffic between members of this group (node-to-node)
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "k3s_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  key_name               = aws_key_pair.web.key_name
  vpc_security_group_ids = [aws_security_group.k3s.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "k3s-server"
  }
}

resource "aws_instance" "k3s_worker" {
  count                  = var.worker_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  key_name               = aws_key_pair.web.key_name
  vpc_security_group_ids = [aws_security_group.k3s.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "k3s-worker-${count.index + 1}"
  }
}

output "k3s_server_public_ip" {
  value = aws_instance.k3s_server.public_ip
}

output "k3s_server_private_ip" {
  value = aws_instance.k3s_server.private_ip
}

output "k3s_worker_private_ips" {
  value = aws_instance.k3s_worker[*].private_ip
}
