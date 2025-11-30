// file: infra/terraform/live-v1/dev/10-platform/azure/aks/terragrunt.hcl
// purpose: Azure AKS cluster for dev environment
// author: Jeleel Muibi
// date: 2025-11-29

include "env" {
  path = find_in_parent_folders("terragrunt.hcl")
}

dependency "network" {
  config_path = "../../00-foundation/azure/network"
}

terraform {
  source = "../../../../modules/azure/aks"
}

inputs = {
  environment      = include.env.locals.environment
  location         = "uksouth"
  resource_group   = dependency.network.outputs.resource_group_name
  vnet_name        = dependency.network.outputs.vnet_name
  subnet_id        = dependency.network.outputs.kube_subnet_id
  kubernetes_version = "1.30.0"
  node_count       = 1
  node_vm_size     = "Standard_D4s_v5"
}
