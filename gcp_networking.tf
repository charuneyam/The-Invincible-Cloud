# 1. Create the VPC
resource "google_compute_network" "gcp_vpc" {
  name                    = "gcp-vpc-vivin"
  auto_create_subnetworks = false 
}

# 2. Create the Subnet
resource "google_compute_subnetwork" "gcp_subnet" {
  name          = "gcp-subnet-vivin"
  ip_cidr_range = "10.1.1.0/24"
  region        = "asia-south1"
  network       = google_compute_network.gcp_vpc.id
}

#  VPN VM endpoint (StrongSwan) 

resource "google_compute_address" "gcp_vpn" {
  name   = "gcp-vpn-ip-vivin"
  region = var.gcp_region
}

resource "google_compute_firewall" "gcp_allow_ssh" {
  name    = "allow-ssh-vivin"
  network = google_compute_network.gcp_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.allowed_ssh_cidr]
  target_tags   = ["vpn"]
}

resource "google_compute_firewall" "gcp_allow_ipsec" {
  name    = "allow-ipsec-vivin"
  network = google_compute_network.gcp_vpc.name

  allow {
    protocol = "udp"
    ports    = ["500", "4500"]
  }

  allow {
    protocol = "esp"
  }

  # Only AWS VPN's public IP should be talking IPsec to this VM.
  source_ranges = ["${aws_eip.aws_vpn.public_ip}/32"]
  target_tags   = ["vpn"]
}

resource "google_compute_firewall" "gcp_allow_icmp" {
  name    = "allow-icmp-from-aws-vivin"
  network = google_compute_network.gcp_vpc.name

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/16"]
  target_tags   = ["vpn"]
}

data "google_compute_image" "ubuntu_2204" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_instance" "gcp_vpn" {
  name         = "gcp-vpn-vivin"
  machine_type = var.gcp_machine_type
  zone         = var.gcp_zone

  can_ip_forward = true
  tags           = ["vpn"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu_2204.self_link
      size  = 10
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = google_compute_network.gcp_vpc.id
    subnetwork = google_compute_subnetwork.gcp_subnet.id
    network_ip = var.gcp_vpn_private_ip

    access_config {
      nat_ip = google_compute_address.gcp_vpn.address
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_username}:${var.ssh_public_key}"
  }

  # --- CRITICAL FIX START ---
  # The 'replace' function removes the Windows '\r' characters automatically.
  metadata_startup_script = replace(<<-EOF
    #!/bin/bash
    set -e
    
    # 1. PREVENT INTERACTIVE PROMPTS
    export DEBIAN_FRONTEND=noninteractive

    # 2. WAIT FOR BOOT LOCKS (Robust Wait Loop)
    echo "Waiting for apt locks..."
    MAX_RETRIES=50
    COUNT=0
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
          fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
      sleep 5
      COUNT=$((COUNT+1))
      if [ $COUNT -ge $MAX_RETRIES ]; then break; fi
    done

    # 3. INSTALL STRONG SWAN
    # 'update' is essential to find the package in a fresh VM
    apt-get update -y
    apt-get install -y --no-install-recommends strongswan strongswan-pki

    # 4. CONFIGURE IPSEC (Using Cat with Heredoc)
    cat > /etc/ipsec.conf <<CONF
    config setup
      charondebug="ike 1, knl 1, cfg 0"
      uniqueids=no

    conn aws-gcp
      auto=start
      type=tunnel
      keyexchange=ikev2
      authby=psk
      
      left=%defaultroute
      leftid=${google_compute_address.gcp_vpn.address}
      leftsubnet=10.1.0.0/16

      right=${aws_eip.aws_vpn.public_ip}
      rightid=${aws_eip.aws_vpn.public_ip}
      rightsubnet=10.0.0.0/16

      ike=aes256-sha256-modp2048!
      esp=aes256-sha256!
      
      dpdaction=restart
      dpddelay=30s
      dpdtimeout=120s
    CONF

    cat > /etc/ipsec.secrets <<SECRETS
    ${google_compute_address.gcp_vpn.address} ${aws_eip.aws_vpn.public_ip} : PSK "${var.ipsec_psk}"
    SECRETS

    # 5. ENABLE ROUTING
    sysctl -w net.ipv4.ip_forward=1
    echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-gcp-vpn.conf

    # 6. RESTART AND VERIFY
    systemctl restart strongswan-starter
    sleep 2
    ipsec status
  EOF
  , "\r", "")
  # --- CRITICAL FIX END ---
}

resource "google_compute_route" "to_aws_vpc" {
  name             = "route-to-aws-vpc-vivin"
  network          = google_compute_network.gcp_vpc.name
  dest_range       = "10.0.0.0/16"
  priority         = 1000
  next_hop_instance = google_compute_instance.gcp_vpn.self_link
  next_hop_instance_zone = var.gcp_zone
}