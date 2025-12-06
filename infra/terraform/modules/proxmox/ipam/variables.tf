# Paste variables.tf content here
# Hostname-keyed IPAM module variables

variable "allocations" {
  description = "Map of hostname to allocation details (vlan, offset)"
  type = map(object({
    vlan   = string
    offset = number
  }))

  validation {
    condition     = alltrue([for k, v in var.allocations : v.offset >= 0])
    error_message = "All offsets must be non-negative integers."
  }
}

variable "subnet_map" {
  description = "Map of VLAN string to CIDR block (e.g., { '20' = '10.20.0.0/24' })"
  type        = map(string)

  validation {
    condition     = alltrue([for cidr in values(var.subnet_map) : can(cidrhost(cidr, 0))])
    error_message = "All subnet_map values must be valid CIDR blocks."
  }
}

variable "offset_min" {
  description = "Minimum allowed offset for IP allocation"
  type        = number
  default     = 10

  validation {
    condition     = var.offset_min >= 1 && var.offset_min < 255
    error_message = "offset_min must be between 1 and 254."
  }
}

variable "offset_max" {
  description = "Maximum allowed offset for IP allocation"
  type        = number
  default     = 250

  validation {
    condition     = var.offset_max >= 1 && var.offset_max < 255
    error_message = "offset_max must be between 1 and 254."
  }
}

variable "validate_requests" {
  description = "Enable validation checks for allocation requests"
  type        = bool
  default     = true
}
