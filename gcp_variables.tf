variable "gcp_project_id" {}
variable "gcp_region" {
  default = "asia-south1"
}

variable "gcp_db_password" {
  sensitive = true
}
