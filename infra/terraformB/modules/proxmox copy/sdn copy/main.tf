# File: ~/hybridops-studio/infra/terraform/modules/proxmox/sdn/main.tf

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.87.0"
    }
  }
}

# Note: Provider configuration is handled by Terragrunt's generate blocks in root.hcl

# SDN Zone
resource "proxmox_virtual_environment_sdn_zone_vlan" "main" {
  id     = var.zone_name
  bridge = var.uplink_bridge
  mtu    = 1500
}

# SDN VNets
resource "proxmox_virtual_environment_sdn_vnet" "vnets" {
  for_each = var.vnets

  id    = each.key
  zone  = proxmox_virtual_environment_sdn_zone_vlan.main.id
  tag   = each.value.vlan_id
  alias = each.value.comment
}

# SDN Subnets with DHCP
resource "proxmox_virtual_environment_sdn_subnet" "subnets" {
  for_each = var.vnets

  cidr            = each.value.cidr
  vnet            = proxmox_virtual_environment_sdn_vnet.vnets[each.key].id
  gateway         = each.value.gateway
  dhcp_dns_server = length(each.value.dns) > 0 ? each.value.dns[0] : null

  # Enable DHCP using dnsmasq
  dhcp = "dnsmasq"

  # DHCP range: . 100 to .200 (leaves . 1-. 99 for static, .201-.254 reserved)
  dhcp_range = [
    {
      start_address = cidrhost(each.value.cidr, 100)
      end_address   = cidrhost(each.value.cidr, 200)
    }
  ]
}
