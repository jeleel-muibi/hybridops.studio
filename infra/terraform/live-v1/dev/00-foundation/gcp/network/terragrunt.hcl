// file: infra/terraform/live-v1/dev/00-foundation/gcp/network/terragrunt.hcl
// purpose: GCP VPC network for dev environment
// author: Jeleel Muibi
// date: 2025-11-29

include "env" {
  path = find_in_parent_folders("terragrunt.hcl")
}

terraform {
  source = "../../../../modules/gcp/network"
}

inputs = {
  environment      = include.env.locals.environment
  project_id       = get_env("GCP_PROJECT_ID", "")
  region           = "europe-west2"
  vpc_cidr         = "10.20.0.0/16"
  kube_subnet_cidr = "10.20.1.0/24"
}
