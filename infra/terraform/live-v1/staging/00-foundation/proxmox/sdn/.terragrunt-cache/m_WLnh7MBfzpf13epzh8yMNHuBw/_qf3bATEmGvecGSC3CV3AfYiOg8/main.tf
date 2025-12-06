# file: infra/terraform/modules/proxmox/sdn/main.tf
# purpose: Proxmox SDN resources - zone, vnets, subnets

resource "proxmox_virtual_environment_sdn_zone_vlan" "main" {
  id     = var.zone_name
  bridge = var.uplink_bridge
}

resource "proxmox_virtual_environment_sdn_vnet" "vnets" {
  for_each = var.vnets

  id      = each.key
  zone    = proxmox_virtual_environment_sdn_zone_vlan.main.id
  tag     = each.value.vlan_id
  alias   = each.value.comment

  depends_on = [proxmox_virtual_environment_sdn_zone_vlan.main]
}

resource "proxmox_virtual_environment_sdn_subnet" "subnets" {
  for_each = var.vnets

  vnet    = proxmox_virtual_environment_sdn_vnet.vnets[each.key].id
  cidr    = each.value.cidr
  gateway = each.value.gateway
  snat    = true

  depends_on = [proxmox_virtual_environment_sdn_vnet.vnets]
}
