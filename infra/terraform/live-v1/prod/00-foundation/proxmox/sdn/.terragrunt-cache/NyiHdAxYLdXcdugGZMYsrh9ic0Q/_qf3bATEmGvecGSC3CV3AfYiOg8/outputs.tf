output "zone_id" {
  description = "ID of the SDN zone"
  value       = proxmox_virtual_environment_sdn_zone_vlan.main.id
}

output "zone_bridge" {
  description = "Bridge used by SDN zone"
  value       = proxmox_virtual_environment_sdn_zone_vlan.main.bridge
}

output "vnet_details" {
  description = "Details of VNets (VLAN tag, gateway, etc.)"
  value = {
    for k, v in proxmox_virtual_environment_sdn_vnet.vnets : k => {
      id      = v.id
      zone    = v.zone
      tag     = v.tag
      gateway = var.vnets[k].gateway
      cidr    = var.vnets[k].cidr
      alias   = v.alias
    }
  }
}

output "subnet_details" {
  description = "Details of created subnets"
  value = {
    for k, v in proxmox_virtual_environment_sdn_subnet.subnets : k => {
      vnet    = v.vnet
      cidr    = v.cidr
      gateway = v.gateway
      snat    = v.snat
    }
  }
}
