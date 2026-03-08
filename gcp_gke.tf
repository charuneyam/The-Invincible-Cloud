## GCP - GKE Autopilot Cluster

resource "google_container_cluster" "autopilot_cluster" {
  name                = "invincible-gke-autopilot"
  location            = var.gcp_region
  enable_autopilot    = true
  deletion_protection = false

  # Use the VPC
  network    = google_compute_network.gcp_vpc.id
  subnetwork = google_compute_subnetwork.gcp_subnet.id

  # Release channel for stability
  release_channel {
    channel = "REGULAR"
  }

  # Enable necessary monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Labels for organization
  resource_labels = {
    environment = "production"
    owner       = "cloud"
    phase       = "2"
  }
}
