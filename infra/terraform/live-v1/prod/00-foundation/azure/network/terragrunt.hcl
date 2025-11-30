// file: infra/terraform/live-v1/prod/00-foundation/azure/network/terragrunt.hcl
// purpose: Azure virtual network for prod environment
// author: Jeleel Muibi
// date: 2025-11-29

include "env" {
  path = find_in_parent_folders("terragrunt.hcl")
}

terraform {
  source = "../../../../modules/azure/network"
}

inputs = {
  environment       = include.env.locals.environment
  location          = "uksouth"
  address_space     = ["10.12.0.0/16"]
  kube_subnet_cidr  = "10.12.1.0/24"
  vm_subnet_cidr    = "10.12.2.0/24"
}
