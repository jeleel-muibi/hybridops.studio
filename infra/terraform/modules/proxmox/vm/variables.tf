# file: infra/terraform/modules/proxmox/vm/variables.tf

variable "node_name" {
  description = "Proxmox node name"
  type        = string
}

variable "vm_name" {
  description = "Name of the VM"
  type        = string
}

variable "vm_id" {
  description = "VM ID"
  type        = number
}

variable "template_vm_id" {
  description = "Template VM ID to clone from"
  type        = number
  default     = null
}

variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "cpu_type" {
  description = "CPU type"
  type        = string
  default     = "host"
}

variable "memory_mb" {
  description = "Memory in MB"
  type        = number
  default     = 2048
}

variable "disk_size_gb" {
  description = "Disk size in GB"
  type        = number
  default     = 20
}

variable "datastore_id" {
  description = "Datastore ID for VM disks"
  type        = string
}

variable "network_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "vlan_id" {
  description = "VLAN ID (null for untagged)"
  type        = number
  default     = null
}

variable "ip_address" {
  description = "IP address (dhcp or static IP with CIDR)"
  type        = string
  default     = "dhcp"
}

variable "gateway" {
  description = "Network gateway (only needed for static IP)"
  type        = string
  default     = null
}

variable "nameservers" {
  description = "DNS nameservers (only needed for static IP)"
  type        = string
  default     = null
}

variable "ssh_username" {
  description = "SSH username"
  type        = string
  default     = "hybridops"
}

variable "ssh_keys" {
  description = "List of SSH public keys"
  type        = list(string)
  default     = []
}

variable "os_type" {
  description = "OS type"
  type        = string
  default     = "l26"
}

variable "tags" {
  description = "VM tags"
  type        = list(string)
  default     = []
}

variable "on_boot" {
  description = "Start VM on boot"
  type        = bool
  default     = true
}

# Provider configuration variables (passed from root.hcl)
variable "proxmox_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_token" {
  description = "Proxmox API token"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS verification"
  type        = bool
  default     = false
}
