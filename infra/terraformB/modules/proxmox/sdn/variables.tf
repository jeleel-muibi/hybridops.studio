variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "site" {
  description = "Site identifier"
  type        = string
}

variable "uplink_bridge" {
  description = "Uplink bridge for SDN zone"
  type        = string
  default     = "vmbr0"
}

variable "zone_name" {
  description = "Name of the SDN zone"
  type        = string
}

variable "vnets" {
  description = "Map of VNets to create"
  type = map(object({
    vlan_id = number
    cidr    = string
    gateway = string
    dns     = optional(list(string), [])
    mtu     = optional(number, 1500)
    comment = optional(string, "")
  }))
}
