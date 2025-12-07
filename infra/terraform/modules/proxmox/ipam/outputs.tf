output "dhcp_config" {
  description = "DHCP configuration for SDN zone"
  value = {
    enabled     = var.dhcp_enabled
    backend     = local.dhcp_backend
    range_start = var.dhcp_range_start
    range_end   = var.dhcp_range_end
  }
}

output "dns_config" {
  description = "DNS configuration for SDN zone"
  value = {
    domain  = var.dns_domain
    servers = var.dns_servers
  }
}

output "static_reservations" {
  description = "Static IP reservations"
  value       = var.static_reservations
}
