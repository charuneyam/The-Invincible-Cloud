terraform {
  backend "s3" {
    bucket         = "invincible-cloud-terraform-state" # Bucket name
    key            = "terraformroh.tfstate"
    region         = "us-east-1"
    dynamodb_table = "invincible-cloud-lock-table"
    encrypt        = true
    profile        = "account_a"
      
  }
}