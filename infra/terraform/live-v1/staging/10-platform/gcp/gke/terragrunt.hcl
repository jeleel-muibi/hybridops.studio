// file: infra/terraform/live-v1/staging/10-platform/gcp/gke/terragrunt.hcl
// purpose: GKE cluster for staging environment
// author: Jeleel Muibi
// date: 2025-11-29

include "env" {
  path = find_in_parent_folders("terragrunt.hcl")
}

dependency "network" {
  config_path = "../../00-foundation/gcp/network"
}

terraform {
  source = "../../../../modules/gcp/gke"
}

inputs = {
  environment  = include.env.locals.environment
  project_id   = get_env("GCP_PROJECT_ID", "")
  region       = "europe-west2"
  network_name = dependency.network.outputs.vpc_name
  subnet_name  = dependency.network.outputs.kube_subnet_name
  cluster_name = "ho-staging-gke"
  min_nodes    = 1
  max_nodes    = 3
  machine_type = "e2-standard-4"
}
