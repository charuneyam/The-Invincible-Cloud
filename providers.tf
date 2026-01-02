provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn     = "arn:aws:iam::215446238483:role/TerraformRDSRole"
    session_name = "TerraformSession"
  }
}

provider "google" {
  project = "the-invincible-cloud"
  region  = "us-central1"
}
