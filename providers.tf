# Primary AWS provider (account_c) - for all infrastructure resources in ap-south-1
provider "aws" {
  profile = "account_a"
  region  = "us-east-1"
}

# Secondary AWS provider (account_a) - for S3 backend and state locking in us-east-1
provider "aws" {
  alias   = "account_c"
  profile = "account_c"
  region  = "ap-south-1"
}

# GCP provider
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}
