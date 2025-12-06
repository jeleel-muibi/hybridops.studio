# Map of Hostname → IPv4 Address allocated per VLAN and offset
output "ipv4_addresses" {
  description = <<EOT
Map of Hostname => IPv4 Address (calculated from vlan → subnet and offset).
Use this when provisioning VMs or assigning static IPs per host.
Example:
{
  "k3s-dev-cp-01" = "10.20.0.10"
  "k3s-dev-cp-02" = "10.20.0.11"
}
EOT
  value = local.ipv4_addresses
}

# Map of VLAN → Gateway IP (first host in the subnet)
output "gateways" {
  description = <<EOT
Map of VLAN (keyed as strings) to the gateway IP address.
Example:
{
  "20" = "10.20.0.1"
  "11" = "10.11.0.1"
}
EOT
  value = local.gateways
}

# Map of VLAN → List of Hostnames (reverse allocation metadata)
output "allocated_by_vlan" {
  description = <<EOT
Map of VLAN (keyed as strings) → List of hostnames.
Shows how many hosts are allocated under each VLAN.
Example:
{
  "20" = ["k3s-dev-cp-01", "k3s-dev-cp-02"]
}
EOT
  value = local.allocated_by_vlan
}

# Validation results (e.g., Are offsets in range? Are all VLANs defined in subnet_map?)
output "validation_checks" {
  description = <<EOT
Validation results for safely applying this module:
- `offsets_in_range`: Boolean indicating if all offsets are valid for their subnets.
- `vlans_exist`: Boolean indicating if all referenced VLANs exist in `subnet_map`.
Example:
{
  "offsets_in_range" = true
  "vlans_exist" = true
}
EOT
  value = {
    offsets_in_range = local.offsets_in_range
    vlans_exist      = local.vlans_exist
  }
}

# Full allocation metadata (optional unified view of the key outputs)
output "allocation_metadata" {
  description = <<EOT
Comprehensive metadata about allocations:
- `ipv4_addresses`: Map (hostname → allocated IP addresses).
- `gateways`: Map (VLAN → gateway IPs).
- `allocated_by_vlan`: Map (VLAN → hostnames).
- `validation_checks`: Validation booleans.

Recommended for debugging or external integrations.
EOT
  value = {
    ipv4_addresses    = local.ipv4_addresses
    gateways          = local.gateways
    allocated_by_vlan = local.allocated_by_vlan
    validation_checks = {
      offsets_in_range = local.offsets_in_range
      vlans_exist      = local.vlans_exist
    }
  }
}
