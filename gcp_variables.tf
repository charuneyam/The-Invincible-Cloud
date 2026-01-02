variable "gcp_project_id" {}
variable "gcp_region" {
  default = "us-central1"
}

variable "gcp_db_password" {
  sensitive = true
}
