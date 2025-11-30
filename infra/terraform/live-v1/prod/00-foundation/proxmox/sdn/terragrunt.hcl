// file: infra/terraform/live-v1/prod/00-foundation/proxmox/sdn/terragrunt.hcl
// purpose: Proxmox SDN virtual networks for prod environment
// author: Jeleel Muibi
// date: 2025-11-29

include "env" {
  path = find_in_parent_folders("terragrunt.hcl")
}

terraform {
  source = "../../../../modules/proxmox/sdn"
}

inputs = {
  proxmox_endpoint  = include.env.locals.proxmox_endpoint
  proxmox_api_token = "${include.env.locals.proxmox_token_id}=${include.env.locals.proxmox_token_secret}"
  proxmox_node      = include.env.locals.proxmox_node
  uplink_bridge     = get_env("PROXMOX_BRIDGE", "vmbr0")

  environment       = include.env.locals.environment

  vnets = {
    "vnet-prod-linux" = {
      vlan_id = 40
      cidr    = "10.40.0.0/24"
    }
  }
}
