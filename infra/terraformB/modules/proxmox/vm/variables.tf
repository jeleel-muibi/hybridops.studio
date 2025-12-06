// file: infra/terraform/modules/proxmox/vm/variables.tf
// purpose: Input variables for Proxmox VM module (bpg/proxmox)
// Maintainer: HybridOps.Studio
// date: 2025-11-29

variable "target_node" {
  type        = string
  description = "Proxmox node where VMs will be created"
}

variable "template_vm_id" {
  type        = number
  description = "Proxmox VMID of the cloud-init template to clone"
}

variable "datastore_id" {
  type        = string
  description = "Proxmox datastore ID for VM disks"
}

variable "vm_count" {
  type        = number
  description = "Number of VMs to create"
  default     = 1
}

variable "vm_name_prefix" {
  type        = string
  description = "Prefix for VM names (suffix 01, 02, etc.)"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, staging, prod)"
  default     = "dev"
}

variable "role" {
  type        = string
  description = "Role label for the VMs (e.g., k3s-node, worker, etc.)"
}

variable "os_family" {
  type        = string
  description = "Operating system family label"
  default     = "linux"
}

variable "os_name" {
  type        = string
  description = "Operating system name/version label"
}

variable "bridge" {
  type        = string
  description = "Proxmox bridge or SDN vnet name"
}

variable "vlan_id" {
  type        = number
  description = "VLAN tag for the primary NIC; set to 0 for no VLAN tagging"
  default     = 0
}

variable "cpu_cores" {
  type        = number
  description = "Number of vCPU cores allocated per VM"
  default     = 2
}

variable "memory_mb" {
  type        = number
  description = "Memory allocated to VMs (in MB)"
  default     = 4096
}

variable "disk_size_gb" {
  type        = number
  description = "Disk size allocated per VM (in GB)"
  default     = 40
}

variable "extra_tags" {
  type        = list(string)
  description = "Additional tags to apply to VMs in Proxmox"
  default     = []
}

# Network & IP Configuration
variable "static_ips" {
  type        = list(string)
  description = "List of static IPs allocated to VMs (e.g., ['10.20.0.10', '10.20.0.11'])"
  default     = []
}

variable "gateway" {
  type        = string
  description = "Default gateway IP for static IP configurations"
  default     = ""
}

variable "dns_servers" {
  type        = list(string)
  description = "DNS servers for network configurations"
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "use_dhcp" {
  type        = bool
  description = "Flag to indicate whether DHCP should be used for networking (default: false)"
  default     = false
}
