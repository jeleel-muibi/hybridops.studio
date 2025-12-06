variable "allocations" {
  description = <<EOT
Map of hostname => { vlan = number, offset = number } specifying how hosts map to VLANs and offsets.
Example:
allocations = {
  "k3s-dev-cp-01" = { vlan = 20, offset = 10 }
  "prometheus-01" = { vlan = 11, offset = 10 }
}
EOT
  type = map(object({
    vlan   = number
    offset = number
  }))

  validation {
    # Ensure no duplicate vlan+offset combinations
    condition = length(var.allocations) == length(distinct([for k, v in var.allocations : "${v.vlan}-${v.offset}"]))
    error_message = "Allocations must not contain duplicate vlan+offset pairs."
  }

  validation {
    # Ensure all offsets are valid within bounds
    condition = alltrue([for a in values(var.allocations) :
      a.offset >= var.offset_min && a.offset <= var.offset_max
    ])
    error_message = "All offsets must lie within the range defined by offset_min and offset_max."
  }
}

variable "subnet_map" {
  description = <<EOT
Map of VLAN (string) => CIDR mapping. Used to specify the network subnets available for each VLAN.
Example:
subnet_map = {
  "20" = "10.20.0.0/24"
  "11" = "10.11.0.0/24"
}
EOT
  type = map(string)
  default = {}
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
  description = "Enable runtime validations through null_resource triggers (default: true)"
  type        = bool
  default     = true
}
