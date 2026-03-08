# AWS Outputs
output "k3s_master_public_ip" {
  value       = aws_instance.k3s_master.public_ip
  description = "K3s Master Node Public IP"
}

output "k3s_master_private_ip" {
  value       = aws_instance.k3s_master.private_ip
  description = "K3s Master Node Private IP"
}

output "aws_rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

# GCP Outputs
output "gcp_gke_cluster_name" {
  value       = try(google_container_cluster.autopilot_cluster.name, "")
  description = "GCP GKE Autopilot cluster name"
}

output "gcp_gke_endpoint" {
  value       = try(google_container_cluster.autopilot_cluster.endpoint, "")
  description = "GCP GKE cluster endpoint"
}

output "gcp_gke_region" {
  value       = try(google_container_cluster.autopilot_cluster.location, "")
  description = "GCP GKE cluster region"
}

# GCP Cloud SQL Database Outputs
output "gcp_sql_instance_name" {
  value       = try(google_sql_database_instance.postgres.name, "")
  description = "GCP Cloud SQL instance name"
}

output "gcp_sql_connection_name" {
  value       = try(google_sql_database_instance.postgres.connection_name, "")
  description = "GCP Cloud SQL connection name (for Cloud SQL Proxy)"
}

output "gcp_sql_private_ip" {
  value       = try(google_sql_database_instance.postgres.private_ip_address, "")
  description = "GCP Cloud SQL private IP address"
}

output "gcp_sql_database_name" {
  value       = try(google_sql_database.appdb.name, "appdb")
  description = "GCP Cloud SQL database name"
}

output "gcp_sql_master_username" {
  value       = try(google_sql_user.postgres.name, "postgres")
  description = "GCP Cloud SQL master username"
  sensitive   = true
}
