resource "google_compute_global_address" "cloudsql_private_ip_range" {
  name          = "cloudsql-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.gcp_vpc.id
}

resource "google_service_networking_connection" "cloudsql_vpc_connection" {
  network                 = google_compute_network.gcp_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.cloudsql_private_ip_range.name]
}

resource "google_compute_firewall" "allow_postgres_from_aws" {
  name    = "allow-postgres-from-aws"
  network = google_compute_network.gcp_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges = ["10.0.0.0/16"]
  target_tags   = ["cloudsql"]
}

resource "google_sql_database_instance" "postgres" {
  name             = "postgres"
  database_version = "POSTGRES_15"
  region           = var.gcp_region

  settings {
    tier = "db-f1-micro"

    database_flags {
      name  = "cloudsql.logical_decoding"
      value = "on"
    }

    backup_configuration {
      enabled = false
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.gcp_vpc.id
    }
  }

  deletion_protection = false

  depends_on = [google_service_networking_connection.cloudsql_vpc_connection]
}

resource "google_sql_database" "appdb" {
  name     = "appdb"
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "postgres" {
  name     = "postgres"
  instance = google_sql_database_instance.postgres.name
  password = var.gcp_db_password
}
