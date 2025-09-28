
terraform {
  required_version = ">= 1.6.0"
  required_providers { google = { source = "hashicorp/google", version = ">= 5.0" } }
}
provider "google" { project = var.project_id region = var.region zone = var.zone }
resource "google_compute_network" "vpc" { name = "${var.prefix}-vpc" auto_create_subnetworks = true }
resource "google_compute_instance" "vm" {
  name = "${var.prefix}-vm"
  machine_type = var.machine_type
  zone = var.zone
  boot_disk { initialize_params { image = var.image size = 64 type = "pd-balanced" } }
  metadata = { ssh-keys = "${var.admin_username}:${file(var.ssh_public_key)}" }
  network_interface { network = google_compute_network.vpc.name access_config {} }
  tags = ["hybridops-studio","control-node","failover"]
  labels = { project = "hybridops-studio", component = "control-node", stage = "failover" }
}
