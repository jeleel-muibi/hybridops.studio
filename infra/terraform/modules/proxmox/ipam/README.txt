PROXMOX IPAM MODULE
===================

Manages IP Address Management for Proxmox SDN zones.

FEATURES
--------
- DHCP range configuration (dnsmasq)
- DNS domain and server settings
- Static IP reservations

USAGE
-----
module "ipam" {
  source = "../../modules/proxmox/ipam"

  zone_id           = module.sdn.zone_id
  dhcp_enabled      = true
  dhcp_range_start  = "10.20.100.1"
  dhcp_range_end    = "10.20.100.254"
  dns_domain        = "dev.hybridops.local"
  dns_servers       = ["10.10.0.10", "10.10.0.11"]

  static_reservations = {
    "k8s-master01" = "10.20.0.10"
    "k8s-worker01" = "10.20.0.11"
  }
}

INPUTS
------
zone_id              SDN zone ID
dhcp_enabled         Enable DHCP (default: true)
dhcp_range_start     DHCP range start IP
dhcp_range_end       DHCP range end IP
dns_domain           DNS domain name
dns_servers          List of DNS servers
static_reservations  Map of hostname => IP

OUTPUTS
-------
dhcp_config          DHCP configuration
dns_config           DNS configuration
static_reservations  Static IP mappings
