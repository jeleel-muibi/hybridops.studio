# Paste outputs.tf content here
# Hostname-keyed IPAM module outputs

output "ipv4_addresses" {
  description = "Map of hostname to IPv4 address"
  value       = local.ipv4_addresses
}

output "gateways" {
  description = "Map of VLAN string to gateway IP address"
  value       = local.gateways
}

output "allocated_by_vlan" {
  description = "Allocations grouped by VLAN with hostnames and IPs"
  value       = local.allocated_by_vlan
}

output "allocation_checks" {
  description = "Validation check results for allocations"
  value       = local.allocation_checks
}
