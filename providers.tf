provider "aws" {
  region = "us-east-1"
  profile = "account_b" 
}

provider "google" {
  project = "the-invincible-cloud"
  region  = "us-central1"
}
