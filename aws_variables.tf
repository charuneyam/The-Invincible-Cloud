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
