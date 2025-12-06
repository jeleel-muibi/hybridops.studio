// file: infra/terraform/live-v1/staging/00-foundation/azure/network/terragrunt.hcl
// purpose: Azure virtual network for staging environment
// Maintainer: HybridOps.Studio
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
  address_space     = ["10.11.0.0/16"]
  kube_subnet_cidr  = "10.11.1.0/24"
  vm_subnet_cidr    = "10.11.2.0/24"
}
