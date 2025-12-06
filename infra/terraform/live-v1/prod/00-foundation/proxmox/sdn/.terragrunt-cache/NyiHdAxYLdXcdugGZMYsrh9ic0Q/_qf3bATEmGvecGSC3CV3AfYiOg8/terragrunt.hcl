// purpose: Proxmox SDN vnets for production environment

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
  linux_vnet_name = "vnetprd1"
  linux_vlan_id   = 40
}

inputs = {
  environment   = local.environment
  site          = local.site
  uplink_bridge = local.uplink_bridge
  zone_name     = "prdzone"  # Changed from "prodzone" for consistency

  vnets = {
    (local.linux_vnet_name) = {
      vlan_id = local.linux_vlan_id
      cidr    = "10.40.0.0/24"
      gateway = "10.40.0.1"
      dns     = ["10.40.0.10"]
      mtu     = 1500
      comment = "Production Linux segment"
    }
  }
}
