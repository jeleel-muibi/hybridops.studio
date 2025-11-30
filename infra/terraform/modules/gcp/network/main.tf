// file: infra/terraform/modules/gcp/network/main.tf
// purpose: Provision a GCP VPC and subnet for GKE
// author: Jeleel Muibi
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

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "kube_subnet_cidr" {
  type        = string
  description = "Subnet CIDR for GKE nodes"
}

resource "google_compute_network" "vpc" {
  name                    = "ho-${var.environment}-vpc"
  project                 = var.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "kube" {
  name          = "kube"
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.kube_subnet_cidr
}

output "vpc_name" {
  description = "VPC name"
  value       = google_compute_network.vpc.name
}

output "kube_subnet_name" {
  description = "Subnet name for GKE"
  value       = google_compute_subnetwork.kube.name
}
