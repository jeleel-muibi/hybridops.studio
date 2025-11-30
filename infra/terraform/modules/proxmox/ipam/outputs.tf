# Paste outputs.tf content here
output "assigned_ips" {
  description = "List of assigned IP addresses"
  value       = local.assigned_ips
}

output "ip_with_cidr" {
  description = "List of IPs with CIDR notation (e.g., 10.20.0.10/24)"
  value       = local.ip_with_cidr
}

output "ip_cidr_map" {
  description = "Map of index to IP/CIDR"
  value = {
    for idx, ip_cidr in local.ip_with_cidr :
    idx => ip_cidr
  }
}

output "allocation_summary" {
  description = "Summary of IP allocations"
  value = {
    total_available = local.range_size
    allocated       = var.vm_count
    remaining       = local.range_size - var.vm_count
    cidr           = var.cidr
    range_start    = cidrhost(var.cidr, var.ip_range_start)
    range_end      = cidrhost(var.cidr, var.ip_range_end)
    assigned_ips   = local.assigned_ips
  }
}
