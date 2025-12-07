# IPAM configuration for Proxmox SDN zones
# Manages DHCP ranges, DNS records, and IP reservations

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.87.0"
    }
  }
}

# Note: The bpg/proxmox provider integrates DHCP/DNS/IPAM
# configuration directly into the SDN zone resource.
# This module provides a structured way to manage those settings.

locals {
  dhcp_backend = var.dhcp_enabled ? "dnsmasq" : null
}

# DNS zone configuration (managed via zone attributes)
# DHCP range configuration (managed via zone attributes)
# Static reservations (will be implemented via future Proxmox API support)

# Output configuration for parent modules to apply
