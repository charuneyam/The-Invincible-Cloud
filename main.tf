# provider "digitalocean" {
#   token = var.do_token
# }

# resource "aws_security_group" "allow_ssh" {
#  name        = "allow_ssh"
#  description = "Allow SSH inbound traffic"

#  ingress {
#    from_port   = 22
#    to_port     = 22
#    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
# }

# resource "aws_instance" "app_server" {
#  ami                    = "ami-082835799e9b652df"
# instance_type          = "t3.small"
# key_name               = "ec2-virginia"
# vpc_security_group_ids = [aws_security_group.allow_ssh.id]

# tags = {
#  Name = "learn-terraform"
# }
# }

# data "aws_ami" "ubuntu" {
#   most_recent = true

#   filter {
#     name = "name"
#     values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
#   }

#   owners = ["099720109477"] # Canonical
# }

resource "google_container_cluster" "autopilot_cluster" {
  name             = "invincible-gke-autopilot"
  location         = "asia-south1"
  enable_autopilot = true
  
  network = "projects/${var.gcp_project_id}/global/networks/gcp-vpc-vivin"
  subnetwork = "projects/${var.gcp_project_id}/regions/${var.gcp_region}/subnetworks/gcp-subnet-vivin"
  deletion_protection = false 
}

