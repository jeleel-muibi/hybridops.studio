// file: infra/terraform/modules/gcp/gke/main.tf
// purpose: Provision a regional GKE cluster
// Maintainer: HybridOps.Studio
// date: 2025-11-29

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }
}

provider "google" {}

variable "environment" {
  type        = string
  description = "Logical environment name"
}

variable "project_id" {
  type        = string
  description = "GCP project identifier"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "network_name" {
  type        = string
  description = "Existing VPC name"
}

variable "subnet_name" {
  type        = string
  description = "Existing subnet name"
}

variable "cluster_name" {
  type        = string
  description = "GKE cluster name"
}

variable "min_nodes" {
  type        = number
  description = "Minimum nodes per default node pool"
}

variable "max_nodes" {
  type        = number
  description = "Maximum nodes per default node pool"
}

variable "machine_type" {
  type        = string
  description = "Node machine type"
}

resource "google_container_cluster" "gke" {
  name     = var.cluster_name
  project  = var.project_id
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network_name
  subnetwork = var.subnet_name
}

resource "google_container_node_pool" "default" {
  name       = "default-pool"
  project    = var.project_id
  location   = var.region
  cluster    = google_container_cluster.gke.name

  node_count = var.min_nodes

  autoscaling {
    min_node_count = var.min_nodes
    max_node_count = var.max_nodes
  }

  node_config {
    machine_type = var.machine_type
  }
}

output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.gke.name
}
