# Paste main.tf content here
terraform {
  required_version = ">= 1.0"
}

locals {
  # Parse the CIDR to get network details
  network_parts = split("/", var.cidr)
  network_addr  = local.network_parts[0]
  prefix_length = local.network_parts[1]

  # Calculate total available IPs in range
  range_size = var.ip_range_end - var.ip_range_start + 1

  # Generate list of available IPs
  available_ips = [
    for i in range(var.ip_range_start, var.ip_range_end + 1) :
    cidrhost(var.cidr, i)
  ]

  # Assign IPs sequentially based on count
  assigned_ips = slice(local.available_ips, 0, var.vm_count)

  # Create IP/CIDR combinations
  ip_with_cidr = [
    for ip in local.assigned_ips : "${ip}/${local.prefix_length}"
  ]
}

# Track IP allocations in state
resource "terraform_data" "ip_allocations" {
  for_each = toset(local.assigned_ips)

  input = {
    ip          = each.key
    environment = var.environment
    site        = var.site
    cidr        = var.cidr
    allocated_at = timestamp()
  }

  lifecycle {
    create_before_destroy = true
  }
}
