// file: infra/terraform/modules/proxmox/vm/variables.tf
// purpose: Input variables for Proxmox VM module (bpg/proxmox)
// author: Jeleel Muibi
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
  description = "Prefix for VM names (suffix 01, 02, ...)"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

variable "role" {
  type        = string
  description = "Role label for the VM (for example k3s-node)"
}

variable "os_family" {
  type        = string
  description = "OS family label"
  default     = "linux"
}

variable "os_name" {
  type        = string
  description = "OS name/version label"
}

variable "bridge" {
  type        = string
  description = "Proxmox bridge or SDN vnet name"
}

variable "vlan_id" {
  type        = number
  description = "VLAN tag for primary NIC"
  default     = 0
}

variable "cpu_cores" {
  type        = number
  description = "Number of vCPU cores"
  default     = 2
}

variable "memory_mb" {
  type        = number
  description = "Memory in MB"
  default     = 4096
}

variable "disk_size_gb" {
  type        = number
  description = "Disk size in GB"
  default     = 40
}

variable "site" {
  type        = string
  description = "Site label"
  default     = ""
}

variable "extra_tags" {
  type        = list(string)
  description = "Additional Proxmox tags to apply to the VM"
  default     = []
}
