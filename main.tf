## AWS - K3s Master Node for Kubernetes

resource "aws_instance" "k3s_master" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.small"
  subnet_id                   = data.aws_subnet.default.id
  key_name                    = aws_key_pair.ec2_key.key_name
  vpc_security_group_ids      = [aws_security_group.k3s_sg.id]
  associate_public_ip_address = true

  # Install K3s on instance startup
  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -e
              echo "Starting K3s installation..."
              curl -sfL https://get.k3s.io | sh -
              echo "K3s installation complete"
              EOF
  )

  tags = {
    Name        = "k3s-master-rohith"
    Environment = "Production"
    Role        = "K8s-Master"
    Owner       = "Rohith"
  }
}

# Data source for Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Data source for default subnet
data "aws_subnet" "default" {
  availability_zone = data.aws_availability_zones.available.names[0]
  vpc_id            = data.aws_vpc.default.id
  default_for_az    = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "default" {
  default = true
}

# K3s Security Group
resource "aws_security_group" "k3s_sg" {
  name        = "k3s-master-sg"
  description = "Security group for K3s Master Node"
  vpc_id      = data.aws_vpc.default.id

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # K8s API Server
  ingress {
    description = "K8s API Server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubelet API
  ingress {
    description = "Kubelet API"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # K3s agent port
  ingress {
    description = "K3s Agent"
    from_port   = 6784
    to_port     = 6785
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Database access from GCP CIDR
  ingress {
    description = "Database from GCP"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
  }

  # Allow all egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## GCP - GKE Autopilot Cluster

resource "google_container_cluster" "autopilot_cluster" {
  name             = "invincible-gke-autopilot"
  location         = var.gcp_region
  enable_autopilot = true
  deletion_protection = false

  # Use the VPC created by Vivin
  network    = "projects/${var.gcp_project_id}/global/networks/default"
  subnetwork = "projects/${var.gcp_project_id}/regions/${var.gcp_region}/subnetworks/default"

  # Release channel for stability
  release_channel {
    channel = "REGULAR"
  }

  # Enable necessary monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Labels for organization
  resource_labels = {
    environment = "production"
    owner       = "rohith"
    phase       = "2"
  }
}

# provider "digitalocean" {
#   token = var.do_token
# }


# # Look up existing VPC
# data "digitalocean_vpc" "invincible" {
#   name = "Invincible"
# }

# data "digitalocean_kubernetes_versions" "current" {
# }

# resource "digitalocean_kubernetes_cluster" "do_k8s" {
#   name    = "do-cluster"
#   region  = data.digitalocean_vpc.invincible.region
#   version = data.digitalocean_kubernetes_versions.current.latest_version

#   vpc_uuid = data.digitalocean_vpc.invincible.id

#   node_pool {
#     name       = "worker-pool"
#     size       = "s-2vcpu-2gb"
#     node_count = 1
#   }

#   tags = ["invincible-cloud", "k8s"]
# }

# output "do_cluster_endpoint" {
#   value = digitalocean_kubernetes_cluster.do_k8s.endpoint
# }
