# Paste main.tf content here
# Hostname-keyed IPAM module - computation only with state tracking
terraform {
  required_version = ">= 1.0"
}

locals {
  # Compute IPv4 addresses for each hostname
  ipv4_addresses = {
    for hostname, allocation in var.allocations :
    hostname => cidrhost(var.subnet_map[allocation.vlan], allocation.offset)
  }

  # Compute gateways (first usable IP in each subnet)
  gateways = {
    for vlan, cidr in var.subnet_map :
    vlan => cidrhost(cidr, 1)
  }

  # Group allocations by VLAN
  allocated_by_vlan = {
    for vlan in keys(var.subnet_map) : vlan => {
      hostnames = [
        for hostname, allocation in var.allocations :
        hostname if allocation.vlan == vlan
      ]
      ips = [
        for hostname, allocation in var.allocations :
        local.ipv4_addresses[hostname] if allocation.vlan == vlan
      ]
    }
  }

  # Validation checks
  allocation_checks = var.validate_requests ? {
    # Check all offsets are within allowed range
    offsets_in_range = alltrue([
      for hostname, allocation in var.allocations :
      allocation.offset >= var.offset_min && allocation.offset <= var.offset_max
    ])

    # Check all VLANs in allocations exist in subnet_map
    vlans_exist = alltrue([
      for hostname, allocation in var.allocations :
      contains(keys(var.subnet_map), allocation.vlan)
    ])

    # Check for duplicate offsets within same VLAN
    no_duplicate_offsets = alltrue([
      for vlan in keys(var.subnet_map) : length([
        for hostname, allocation in var.allocations :
        allocation.offset if allocation.vlan == vlan
        ]) == length(distinct([
          for hostname, allocation in var.allocations :
          allocation.offset if allocation.vlan == vlan
      ]))
    ])

    # Total allocations
    total_allocations = length(var.allocations)

    # Summary message
    summary = "Validated ${length(var.allocations)} allocation(s) across ${length(var.subnet_map)} VLAN(s)"
  } : {}
}

# Track allocations in state and surface validation checks
resource "null_resource" "ipam_allocations" {
  triggers = {
    allocations       = jsonencode(var.allocations)
    subnet_map        = jsonencode(var.subnet_map)
    ipv4_addresses    = jsonencode(local.ipv4_addresses)
    allocation_checks = jsonencode(local.allocation_checks)
    timestamp         = timestamp()
  }

  lifecycle {
    precondition {
      condition     = !var.validate_requests || local.allocation_checks.offsets_in_range
      error_message = "One or more offsets are outside the allowed range (${var.offset_min}-${var.offset_max})."
    }

    precondition {
      condition     = !var.validate_requests || local.allocation_checks.vlans_exist
      error_message = "One or more VLANs in allocations do not exist in subnet_map."
    }

    precondition {
      condition     = !var.validate_requests || local.allocation_checks.no_duplicate_offsets
      error_message = "Duplicate offsets detected within the same VLAN."
    }
  }
}
