# 1. Create the VPC
resource "aws_vpc" "aws_main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "aws-vpc-vivin" }
}

# 2. Create the Internet Gateway 
resource "aws_internet_gateway" "aws_igw" {
  vpc_id = aws_vpc.aws_main.id
}

# 3. Create the Public Subnet
resource "aws_subnet" "aws_pub_subnet" {
  vpc_id                  = aws_vpc.aws_main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # Gives EC2 a public IP
  availability_zone       = "ap-south-1a"
}

# 4. Route Table (Sends traffic to Internet Gateway)
resource "aws_route_table" "aws_rt" {
  vpc_id = aws_vpc.aws_main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aws_igw.id
  }
}

resource "aws_route_table_association" "aws_assoc" {
  subnet_id      = aws_subnet.aws_pub_subnet.id
  route_table_id = aws_route_table.aws_rt.id
}

# Route AWS->GCP private traffic to the VPN instance (so it enters the tunnel)
resource "aws_route" "to_gcp_vpc" {
  route_table_id         = aws_route_table.aws_rt.id
  destination_cidr_block = "10.1.0.0/16"
  
  # Change instance_id to network_interface_id
  network_interface_id   = aws_instance.aws_vpn.primary_network_interface_id
}

# VPN EC2 endpoint (StrongSwan) 

data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "vpn_key" {
  key_name   = "vivin-vpn-key"
  public_key = var.ssh_public_key
}

resource "aws_security_group" "aws_vpn_sg" {
  name        = "aws-vpn-sg-vivin"
  description = "Allow SSH + IPsec for StrongSwan"
  vpc_id      = aws_vpc.aws_main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # IKE
  ingress {
    description = "IPsec IKE (UDP 500)"
    from_port   = 500
    to_port     = 500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NAT-T
  ingress {
    description = "IPsec NAT-T (UDP 4500)"
    from_port   = 4500
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ESP (protocol 50)
  ingress {
    description = "IPsec ESP"
    from_port   = 0
    to_port     = 0
    protocol    = "50"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP (ping) from GCP VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.1.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "aws-vpn-sg-vivin" }
}

resource "aws_security_group" "aws_k8s_master_sg" {
  name        = "aws-k8s-master-sg-vivin"
  description = "Allow SSH and Kubernetes API from GCP"
  vpc_id      = aws_vpc.aws_main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "Kubernetes API (6443) from GCP"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.gcp_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "aws-k8s-master-sg-vivin" }
}

# Reserve a static public IP up front (lets GCP reference it without cycles).
resource "aws_eip" "aws_vpn" {
  domain = "vpc"
  tags   = { Name = "aws-vpn-eip-vivin" }
}

resource "aws_instance" "aws_vpn" {
  ami                         = data.aws_ami.ubuntu_2204.id
  instance_type               = var.aws_instance_type
  subnet_id                   = aws_subnet.aws_pub_subnet.id
  private_ip                  = var.aws_vpn_private_ip
  vpc_security_group_ids      = [aws_security_group.aws_vpn_sg.id]
  key_name                    = aws_key_pair.vpn_key.key_name
  associate_public_ip_address = true
  source_dest_check           = false

  user_data = <<-EOF
              #!/usr/bin/env bash
              set -euxo pipefail

              export DEBIAN_FRONTEND=noninteractive
              apt-get update
              apt-get install -y strongswan

              cat > /etc/ipsec.conf <<'CONF'
              config setup
                uniqueids=no

              conn aws-gcp
                auto=start
                type=tunnel
                keyexchange=ikev2
                authby=psk

                left=%defaultroute
                leftid=${aws_eip.aws_vpn.public_ip}
                leftsubnet=10.0.0.0/16

                right=${google_compute_address.gcp_vpn.address}
                rightid=${google_compute_address.gcp_vpn.address}
                rightsubnet=10.1.0.0/16

                ike=aes256-sha256-modp2048!
                esp=aes256-sha256!
                dpdaction=restart
                dpddelay=30s
                dpdtimeout=120s
              CONF

              cat > /etc/ipsec.secrets <<'SECRETS'
              ${aws_eip.aws_vpn.public_ip} ${google_compute_address.gcp_vpn.address} : PSK "${var.ipsec_psk}"
              SECRETS

              sysctl -w net.ipv4.ip_forward=1
              printf 'net.ipv4.ip_forward=1\n' > /etc/sysctl.d/99-ipsec.conf

              systemctl enable --now strongswan-starter || true
              systemctl restart strongswan-starter || true
              EOF

  tags = { Name = "aws-vpn-vivin" }
}

resource "aws_instance" "aws_k8s_master" {
  ami                         = data.aws_ami.ubuntu_2204.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.aws_pub_subnet.id
  vpc_security_group_ids      = [aws_security_group.aws_k8s_master_sg.id]
  key_name                    = aws_key_pair.vpn_key.key_name
  associate_public_ip_address = true

  tags = { Name = "aws-k8s-master-vivin" }
}

resource "aws_eip_association" "aws_vpn" {
  instance_id   = aws_instance.aws_vpn.id
  allocation_id = aws_eip.aws_vpn.id
}