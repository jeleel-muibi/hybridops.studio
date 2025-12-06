# Local computations for IPAM module
locals {
  # Convert VLAN numbers to strings to reliably index subnet_map
  alloc_list = [
    for hostname, a in var.allocations :
    {
      hostname = hostname
      vlan_str = tostring(a.vlan)
      offset   = a.offset
    }
  ]

  # Basic validation checks (calculated into null_resource triggers and outputs)
  offsets_in_range = alltrue([for a in local.alloc_list : a.offset >= var.offset_min && a.offset <= var.offset_max])
  vlans_exist      = alltrue([for a in local.alloc_list : contains(keys(var.subnet_map), a.vlan_str)])
}

# Null resource to capture validation results
resource "null_resource" "validate_and_record" {
  triggers = {
    allocations = jsonencode(var.allocations)
    validations = jsonencode({
      offsets_in_range = local.offsets_in_range
      vlans_exist      = local.vlans_exist
    })
  }

  count = var.validate_requests ? 1 : 0
}

# Calculated values
locals {
  ipv4_addresses = {
    for hostname, alloc in var.allocations :
    hostname => cidrhost(var.subnet_map[tostring(alloc.vlan)], alloc.offset)
  }

  gateways = {
    for vlan_key, cidr in var.subnet_map :
    vlan_key => cidrhost(cidr, 1)
  }

  allocated_by_vlan = {
    for vlan_key in distinct([for _, a in var.allocations : tostring(a.vlan)]) :
    vlan_key => [for name, a in var.allocations : name if tostring(a.vlan) == vlan_key]
  }
}

# Outputs for Proxmox IPAM module

output "ipv4_addresses" {
  description = "Map(hostname => allocated IP address)"
  value       = local.ipv4_addresses
}

output "gateways" {
  description = "Map(VLAN => gateway IP)"
  value       = local.gateways
}

output "allocated_by_vlan" {
  description = "Map(VLAN => list of hostnames assigned to each VLAN)"
  value       = local.allocated_by_vlan
}

output "validation_checks" {
  description = "Validation results for this IPAM module - ensure success before consuming outputs."
  value = {
    offsets_in_range = local.offsets_in_range
    vlans_exist      = local.vlans_exist
  }
}
