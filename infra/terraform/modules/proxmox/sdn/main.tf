terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.87.0"
    }
  }
}

# SDN Zone with IPAM (no DHCP for VLAN zones)
resource "proxmox_virtual_environment_sdn_zone_vlan" "main" {
  id     = var.zone_name
  bridge = var.uplink_bridge
  mtu    = 1500
  ipam   = "pve"
}

# SDN VNets
resource "proxmox_virtual_environment_sdn_vnet" "vnets" {
  for_each = var.vnets

  id    = each.key
  zone  = proxmox_virtual_environment_sdn_zone_vlan.main.id
  tag   = each.value.vlan_id
  alias = each.value.comment
}

# SDN Subnets (static IP assignment, no DHCP)
resource "proxmox_virtual_environment_sdn_subnet" "subnets" {
  for_each = var.vnets

  cidr    = each.value.cidr
  vnet    = proxmox_virtual_environment_sdn_vnet.vnets[each.key].id
  gateway = each.value.gateway

  # DNS server for static IP configurations
  dhcp_dns_server = length(each.value.dns) > 0 ?  each.value.dns[0] : null
}
