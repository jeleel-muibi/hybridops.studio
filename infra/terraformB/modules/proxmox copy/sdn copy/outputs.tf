# File: ~/hybridops-studio/infra/terraform/modules/proxmox/sdn/outputs.tf

output "zone_id" {
  description = "ID of the created SDN zone"
  value       = proxmox_virtual_environment_sdn_zone_vlan.main.id
}

output "zone_bridge" {
  description = "Bridge used by the SDN zone"
  value       = proxmox_virtual_environment_sdn_zone_vlan.main.bridge
}

output "zone_mtu" {
  description = "MTU of the SDN zone"
  value       = proxmox_virtual_environment_sdn_zone_vlan.main.mtu
}

output "vnet_ids" {
  description = "Map of VNet names to their IDs"
  value = {
    for k, v in proxmox_virtual_environment_sdn_vnet.vnets : k => v.id
  }
}

output "vnet_details" {
  description = "Detailed information about created VNets"
  value = {
    for k, v in proxmox_virtual_environment_sdn_vnet.vnets : k => {
      id    = v.id
      zone  = v.zone
      tag   = v.tag
      alias = v.alias
    }
  }
}

output "subnet_ids" {
  description = "Map of subnet CIDRs to their full resource IDs"
  value = {
    for k, v in proxmox_virtual_environment_sdn_subnet.subnets : k => v.id
  }
}

output "subnet_details" {
  description = "Detailed information about created subnets"
  value = {
    for k, v in proxmox_virtual_environment_sdn_subnet.subnets : k => {
      id      = v.id
      vnet    = v.vnet
      gateway = v.gateway
      cidr    = var.vnets[k].cidr
    }
  }
}

output "network_summary" {
  description = "Summary of the complete SDN network setup"
  value = {
    zone        = proxmox_virtual_environment_sdn_zone_vlan.main.id
    environment = var.environment
    site        = var.site
    vnets       = keys(proxmox_virtual_environment_sdn_vnet.vnets)
    subnets     = [for k, v in var.vnets : v.cidr]
  }
}
