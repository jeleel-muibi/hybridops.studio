# Paste variables.tf content here
variable "cidr" {
  description = "CIDR block for the network (e.g., 10.20.0.0/24)"
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "ip_range_start" {
  description = "Starting host number for IP assignment (e.g., 10 for .10)"
  type        = number

  validation {
    condition     = var.ip_range_start > 0 && var.ip_range_start < 255
    error_message = "IP range start must be between 1 and 254."
  }
}

variable "ip_range_end" {
  description = "Ending host number for IP assignment (e.g., 50 for .50)"
  type        = number

  validation {
    condition     = var.ip_range_end > 0 && var.ip_range_end < 255
    error_message = "IP range end must be between 1 and 254."
  }
}

variable "vm_count" {
  description = "Number of VMs requesting IPs"
  type        = number

  validation {
    condition     = var.vm_count > 0
    error_message = "VM count must be greater than 0."
  }
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
}

variable "site" {
  description = "Site identifier"
  type        = string
}
