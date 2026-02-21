terraform {
  backend "s3" {
    bucket         = "invincible-cloud-terraform-state-asia" # Bucket name
    key            = "terraformroh.tfstate"
    region         = "ap-south-1"
    encrypt        = true
  }
}
