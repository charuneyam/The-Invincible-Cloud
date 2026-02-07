provider "aws" {
  region = "us-east-1"
}

# EC2 Instance
resource "aws_instance" "k3s_master" {
  ami                         = "ami-046985b76608d68cb"
  instance_type               = "t3.small"
  subnet_id                   = "subnet-06c824570449a79d1"
  key_name                    = "ec2-virginia"
  vpc_security_group_ids      = [aws_security_group.k3s_sg.id]
  associate_public_ip_address = true

  tags = {
    Name        = "k3s-master"
    Environment = "Production"
    Role        = "K8s-Master"
  }
}

# Security Group
resource "aws_security_group" "k3s_sg" {
  name        = "k3s-master-sg"
  description = "Security group for K3s Master Node"
  vpc_id      = "vpc-0e76ba8205bd14a41"

  # Rule 1: SSH (Existing)
  ingress {
    description = "SSH from World"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Rule 2: K8s API from DigitalOcean
  ingress {
    description = "K8s API from DigitalOcean"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 192.168.96.0/20
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

provider "digitalocean" {
  token = var.do_token
}


# Look up existing VPC
data "digitalocean_vpc" "invincible" {
  name = "Invincible"
}

data "digitalocean_kubernetes_versions" "current" {
}

resource "digitalocean_kubernetes_cluster" "do_k8s" {
  name    = "do-cluster"
  region  = data.digitalocean_vpc.invincible.region
  version = data.digitalocean_kubernetes_versions.current.latest_version

  vpc_uuid = data.digitalocean_vpc.invincible.id

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-2gb"
    node_count = 1
  }

  tags = ["invincible-cloud", "k8s"]
}

output "do_cluster_endpoint" {
  value = digitalocean_kubernetes_cluster.do_k8s.endpoint
}