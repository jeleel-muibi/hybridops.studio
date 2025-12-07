// purpose: IPAM configuration for dev environment

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../modules/proxmox/ipam"
}

# Get SDN outputs from foundation layer
dependency "sdn" {
  config_path = "../../00-foundation/proxmox/sdn"
}

locals {
  env_cfg     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment = local.env_cfg.locals.environment
  site        = local.env_cfg.locals.site
}

inputs = {
  zone_id          = dependency.sdn.outputs.zone_id
  dhcp_enabled     = true
  dhcp_range_start = "10.20.100.1"
  dhcp_range_end   = "10.20.100.254"
  dns_domain       = "dev.hybridops.local"
  dns_servers      = ["10.20.0.10", "10.10.0.10"]

  static_reservations = {
    "k8s-master01" = "10.20.0.10"
    "k8s-worker01" = "10.20.0.11"
    "k8s-worker02" = "10.20.0.12"
    "postgres01"   = "10.20.0.20"
    "ctrl01"       = "10.20.0.30"
  }
}
