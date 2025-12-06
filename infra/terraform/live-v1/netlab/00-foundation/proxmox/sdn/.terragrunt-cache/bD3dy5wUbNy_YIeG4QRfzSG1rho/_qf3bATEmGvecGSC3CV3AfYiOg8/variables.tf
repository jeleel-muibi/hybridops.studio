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

# Provider configuration variables (passed from root.hcl)
variable "proxmox_url" {
  description = "Proxmox API endpoint URL"
  type        = string
}

variable "proxmox_token" {
  description = "Proxmox API token in format 'id=secret'"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS verification for Proxmox API"
  type        = bool
  default     = false
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Global tags for resources"
  type        = map(string)
  default     = {}
}
