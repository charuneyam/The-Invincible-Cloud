provider "aws" {
  profile = "account_c"
  region  = var.aws_region
}

provider "aws" {
  alias   = "account_a"
  profile = "account_a"
  region  = "us-east-1"
}

provider "google" {
  # credentials = file(pathexpand(var.gcp_credentials_file))
  project     = var.gcp_project_id
  region      = "asia-south1"
  zone        = var.gcp_zone
}
