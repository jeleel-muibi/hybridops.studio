// purpose: Proxmox SDN vnets for network lab/testing environment

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

  uplink_bridge = get_env("PROXMOX_BRIDGE", "vmbr0")
}

inputs = {
  environment   = local.environment
  site          = local.site
  uplink_bridge = local.uplink_bridge
  zone_name     = "netlab"

  vnets = {
    "vnetlab" = {
      vlan_id = 50
      cidr    = "10.50.0.0/24"
      gateway = "10.50.0.1"
      dns     = ["10.50.0.10"]
      mtu     = 1500
      comment = "Network Lab for EVE-NG and testing"
    }
  }
}
