variable "db_name" {
  default = "appdb"
}

variable "db_username" {
  default = "postgres"
}

variable "db_password" {
  description = "RDS master password"
  sensitive   = true
}

variable "db_instance_class" {
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  default = 20
}

variable "aws_key_pair_name" {
  description = "Name of the EC2 key pair to use for SSH access"
  type        = string
  default     = "ec2-virginia"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
