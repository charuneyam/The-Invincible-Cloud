resource "aws_db_instance" "postgres" {
  identifier = "rohith-task2-postgres"

  engine            = "postgres"
  engine_version    = "15"
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  publicly_accessible = false
  skip_final_snapshot = true
  deletion_protection = false

  apply_immediately = true
}

# data "aws_instance" "vivin_k3s_master" {
#   provider = aws.account_c

#   filter {
#     name   = "tag:Name"
#     values = ["aws-k8s-master-vivin"]
#   }
# }

# output "vivin_ec2_public_ip" {
#   value = data.aws_instance.vivin_k3s_master.public_ip
# }

