resource "aws_db_parameter_group" "postgres_logical_replication" {
  name   = "postgres-pg"
  family = "postgres15"

  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }
}

resource "aws_db_subnet_group" "postgres" {
  name       = "postgres-subnet-group"
  subnet_ids = [aws_subnet.aws_pub_subnet.id]

  tags = {
    Name = "postgres-subnet-group"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow PostgreSQL from GCP VPC via VPN tunnel"
  vpc_id      = aws_vpc.aws_main.id

  ingress {
    description = "PostgreSQL from GCP VPC (via VPN)"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.gcp_vpc_cidr]
  }

  ingress {
    description = "PostgreSQL from local VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "rds-sg" }
}

resource "aws_db_instance" "postgres" {
  identifier = "postgres"

  engine            = "postgres"
  engine_version    = "15"
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  parameter_group_name   = aws_db_parameter_group.postgres_logical_replication.name
  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

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

