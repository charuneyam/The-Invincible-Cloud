provider "aws" {
  region  = "ap-south-1"
}

# GCP provider
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}
