resource "aws_db_instance" "postgres" {
  identifier = "rohith-task2-postgres"

  engine            = "postgres"
  engine_version    = "15.4"
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  publicly_accessible = true
  skip_final_snapshot = true
  deletion_protection = false

  parameter_group_name = aws_db_parameter_group.postgres.name
}

resource "aws_db_parameter_group" "postgres" {
  name   = "rohith-postgres-params"
  family = "postgres15"

  parameter {
    name  = "logical_replication"
    value = "1"
  }
}
