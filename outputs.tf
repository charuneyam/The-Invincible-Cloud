output "aws_vpn_public_ip" {
  value       = aws_eip.aws_vpn.public_ip
  description = "AWS VPN EC2 public IP (Elastic IP)"
}

output "aws_vpn_private_ip" {
  value       = aws_instance.aws_vpn.private_ip
  description = "AWS VPN EC2 private IP"
}

output "gcp_vpn_public_ip" {
  value       = google_compute_address.gcp_vpn.address
  description = "GCP VPN VM public IP (static)"
}

output "gcp_vpn_private_ip" {
  value       = google_compute_instance.gcp_vpn.network_interface[0].network_ip
  description = "GCP VPN VM private IP"
}

output "aws_k8s_master_public_ip" {
  value       = aws_instance.aws_k8s_master.public_ip
  description = "AWS Kubernetes master public IP"
}

output "aws_k8s_master_private_ip" {
  value       = aws_instance.aws_k8s_master.private_ip
  description = "AWS Kubernetes master private IP"
}
