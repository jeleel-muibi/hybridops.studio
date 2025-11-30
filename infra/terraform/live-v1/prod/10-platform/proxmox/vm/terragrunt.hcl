// file: infra/terraform/live-v1/prod/10-platform/proxmox/vm/terragrunt.hcl
// purpose: Proxmox VM cluster for prod environment
// author: Jeleel Muibi
// date: 2025-11-29

include "env" {
  path = find_in_parent_folders("terragrunt.hcl")
}

dependency "sdn" {
  config_path = "../../00-foundation/proxmox/sdn"
}

terraform {
  source = "../../../../modules/proxmox/vm"
}

locals {
  vnet           = dependency.sdn.outputs.vnet_names["vnet-prod-linux"]
  vm_name_prefix = "prod-k3s-"
}

inputs = {
  proxmox_endpoint  = include.env.locals.proxmox_endpoint
  proxmox_api_token = "${include.env.locals.proxmox_token_id}=${include.env.locals.proxmox_token_secret}"

  target_node    = include.env.locals.proxmox_node
  datastore_id   = include.env.locals.proxmox_datastore_vm
  template_vm_id = 9003

  vm_count       = 3
  vm_name_prefix = local.vm_name_prefix

  environment = include.env.locals.environment
  role        = "k3s-node"

  os_family = "linux"
  os_name   = "rocky-10"

  bridge  = local.vnet.name
  vlan_id = local.vnet.vlan_id

  cpu_cores    = 2
  memory_mb    = 4096
  disk_size_gb = 40

  extra_tags = ["terraform", "k3s", "prod"]
}
