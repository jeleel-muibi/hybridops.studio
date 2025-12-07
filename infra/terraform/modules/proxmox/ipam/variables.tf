variable "zone_id" {
  description = "SDN zone ID to attach IPAM configuration"
  type        = string
}

variable "dhcp_enabled" {
  description = "Enable DHCP server (dnsmasq)"
  type        = bool
  default     = true
}

variable "dhcp_range_start" {
  description = "DHCP range start IP"
  type        = string
}

variable "dhcp_range_end" {
  description = "DHCP range end IP"
  type        = string
}

variable "dns_domain" {
  description = "DNS domain for this zone"
  type        = string
}

variable "dns_servers" {
  description = "List of DNS servers"
  type        = list(string)
  default     = []
}

variable "static_reservations" {
  description = "Map of static IP reservations (hostname => IP)"
  type        = map(string)
  default     = {}
}
