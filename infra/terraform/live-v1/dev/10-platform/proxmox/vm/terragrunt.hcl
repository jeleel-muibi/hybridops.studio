// file: infra/terraform/live-v1/dev/10-platform/proxmox/vm/terragrunt.hcl
// purpose: Proxmox k3s node VMs for dev environment

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "sdn" {
  config_path = "../../../00-foundation/proxmox/sdn"
}

terraform {
  source = "../../../../../modules/proxmox/vm"
}

locals {
  # Environment metadata
  env_cfg     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment = local.env_cfg.locals.environment
  site        = local.env_cfg.locals.site

  # SDN vnet key (must match what SDN module creates)
  vnet_name = "vnetdev1"

  # VM layout
  vm_name_prefix = "${local.environment}-k3s-"

  # Node and datastore from env
  target_node  = get_env("PROXMOX_NODE", "hybridhub")
  datastore_id = get_env("PROXMOX_STORAGE_VM", "local-lvm")
}

inputs = {
  # Proxmox VM placement
  target_node    = local.target_node
  template_vm_id = 9003
  datastore_id   = local.datastore_id

  vm_count       = 3
  vm_name_prefix = local.vm_name_prefix

  environment = local.environment
  site        = local.site
  role        = "k3s-node"

  os_family = "linux"
  os_name   = "ubuntu-24.04"

  # Network from SDN dependency
  bridge  = dependency.sdn.outputs.zone_bridge
  vlan_id = dependency.sdn.outputs.vnet_details[local.vnet_name].tag

  cpu_cores    = 2
  memory_mb    = 4096
  disk_size_gb = 40

  extra_tags = ["terraform", "k3s", local.environment]
}
