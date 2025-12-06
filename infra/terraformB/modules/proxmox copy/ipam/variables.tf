// infra/terraform/modules/proxmox/ipam/variables.tf

variable "allocations" {
  description = "Map of hostname => { vlan = number, offset = number }. Example: { \"k3s-dev-cp-01\" = { vlan = 20, offset = 10 } }"
  type = map(object({
    vlan   = number
    offset = number
  }))

  validation {
    condition = length(var.allocations) == length(distinct([for k, v in var.allocations : "${v.vlan}-${v.offset}"]))
    error_message = "allocations must not contain duplicate vlan+offset pairs."
  }
}

variable "subnet_map" {
  description = "Map of vlan (string) => cidr (eg. {\"20\" = \"10.20.0.0/24\"}). VLAN keys must be strings."
  type        = map(string)
}

variable "offset_min" {
  description = "Minimum allowed host offset (inclusive)"
  type        = number
  default     = 10
}

variable "offset_max" {
  description = "Maximum allowed host offset (inclusive)"
  type        = number
  default     = 250
}

variable "validate_requests" {
  description = "Enable additional runtime validations (default: true)"
  type        = bool
  default     = true
}
