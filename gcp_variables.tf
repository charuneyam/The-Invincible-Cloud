variable "gcp_db_password" {
  sensitive = true
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "asia-south1"
}

variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
}
