// purpose: Proxmox SDN vnets for staging environment

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../modules/proxmox/sdn"
}

locals {
  env_cfg     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment = local.env_cfg.locals.environment
  site        = local.env_cfg.locals.site

  uplink_bridge   = get_env("PROXMOX_BRIDGE", "vmbr0")
  linux_vnet_name = "vnetstg1"
  linux_vlan_id   = 30
}

inputs = {
  environment   = local.environment
  site          = local.site
  uplink_bridge = local.uplink_bridge
  zone_name     = "stgzone"  # Changed from "stagingzone" to 8 chars max

  vnets = {
    (local.linux_vnet_name) = {
      vlan_id = local.linux_vlan_id
      cidr    = "10.30.0.0/24"
      gateway = "10.30.0.1"
      dns     = ["10.30.0.10"]
      mtu     = 1500
      comment = "Staging Linux segment"
    }
  }
}
