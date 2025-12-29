terraform {
  backend "s3" {
    bucket         = "invincible-cloud-terraform-state" # Bucket name
    key            = "terraform.tfstate"                # The path inside the bucket
    region         = "us-east-1"
    dynamodb_table = "invincible-cloud-lock-table"
    encrypt        = true
  }
}