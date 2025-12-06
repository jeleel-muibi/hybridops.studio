// infra/terraform/modules/proxmox/ipam/outputs.tf

output "ipv4_addresses" {
  description = "Map(hostname => ipv4 address) allocated by IPAM module"
  value       = local.ipv4_addresses
}

output "gateways" {
  description = "Map(vlan_string => gateway ip). Gateway is host offset 1 in each subnet."
  value       = local.gateways
}

output "allocated_by_vlan" {
  description = "Map(vlan_string => list(hostnames))"
  value       = local.allocated_by_vlan
}

output "allocation_checks" {
  description = "Basic validation results (offsets_in_range, vlans_exist)"
  value = {
    offsets_in_range = local.offsets_in_range
    vlans_exist      = local.vlans_exist
  }
}
