variable "node_name" {
  description = "Proxmox node name"
  type        = string
}

variable "vm_name" {
  description = "VM name"
  type        = string
}

variable "vm_id" {
  description = "VM ID"
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

variable "datastore_id" {
  description = "Datastore ID for VM disks"
  type        = string
}

variable "template_id" {
  description = "Template ID to clone from"
  type        = string
  default     = null
}

variable "disk_size_gb" {
  description = "Disk size in GB"
  type        = number
  default     = 32
}

variable "network_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "vlan_id" {
  description = "VLAN ID"
  type        = number
  default     = null
}

variable "ip_address" {
  description = "Static IP address in CIDR format"
  type        = string
}

variable "gateway" {
  description = "Network gateway"
  type        = string
}

variable "ssh_username" {
  description = "SSH username for cloud-init"
  type        = string
  default     = "sysadmin"
}

variable "ssh_keys" {
  description = "List of SSH public keys"
  type        = list(string)
  default     = []
}

variable "ssh_password" {
  description = "SSH password"
  type        = string
  sensitive   = true
  default     = null
}

variable "cloud_init_user_data_file_id" {
  description = "Cloud-init user data file ID"
  type        = string
  default     = null
}

variable "os_type" {
  description = "Operating system type"
  type        = string
  default     = "l26"
}

variable "tags" {
  description = "List of tags for the VM"
  type        = list(string)
  default     = []
}
