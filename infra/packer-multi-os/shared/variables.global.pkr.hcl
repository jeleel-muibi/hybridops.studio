# variables.global.pkr.hcl
# Purpose: Centralized variable definitions shared across all OS builds
# Maintainer: HybridOps.Studio
# Date: 2025-11-08

# Proxmox connection
variable "proxmox_url" {
  type        = string
  description = "Proxmox API URL"
  default     = env("PROXMOX_URL")
}

variable "proxmox_token_id" {
  type        = string
  description = "Proxmox API token ID (format: user@realm!tokenname)"
  default     = env("PROXMOX_TOKEN_ID")
}

variable "proxmox_token_secret" {
  type        = string
  description = "Proxmox API token secret"
  sensitive   = true
  default     = env("PROXMOX_TOKEN_SECRET")
}

variable "proxmox_node" {
  type        = string
  description = "Proxmox node name"
  default     = env("PROXMOX_NODE")
}

variable "proxmox_storage_pool" {
  type        = string
  description = "Storage pool for VM disks"
  default     = env("PROXMOX_STORAGE_VM")
}

variable "proxmox_storage_pool_iso" {
  type        = string
  description = "Storage pool for ISO files"
  default     = env("PROXMOX_STORAGE_ISO")
}

variable "proxmox_skip_tls_verify" {
  type        = bool
  description = "Skip TLS certificate verification"
  default     = env("PROXMOX_SKIP_TLS_VERIFY") == "true"
}

# Cloud-Init / Kickstart
variable "cloud_init" {
  type        = bool
  description = "Enable Cloud-Init"
  default     = true
}

variable "cloud_init_storage_pool" {
  type        = string
  description = "Cloud-Init storage pool"
  default     = (
    env("PROXMOX_STORAGE_CLOUDINIT") != ""
    ? env("PROXMOX_STORAGE_CLOUDINIT")
    : env("PROXMOX_STORAGE_VM")
  )
}

# HTTP server for kickstart / cloud-init
variable "http_bind_address" {
  type        = string
  description = "HTTP server bind address"
  default     = env("PACKER_HTTP_BIND_ADDRESS")
}

variable "http_port" {
  type        = string
  description = "HTTP server port"
  default     = env("PACKER_HTTP_PORT")
}

variable "http_directory" {
  type        = string
  description = "HTTP directory path"
  default     = "http"
}

# VM metadata
variable "vmid" {
  type        = number
  description = "VM ID for the template (auto-assigned during build)"
  default     = 0
}

variable "name" {
  type        = string
  description = "VM template name"
}

variable "description" {
  type        = string
  description = "VM template description"
  default     = ""
}

variable "pool" {
  type        = string
  description = "Resource pool name"
  default     = ""
}

# ISO configuration
variable "iso_file" {
  type        = string
  description = "ISO filename on Proxmox storage"
}

variable "iso_url" {
  type        = string
  description = "ISO download URL"
  default     = ""
}

variable "iso_checksum" {
  type        = string
  description = "ISO checksum (format: sha256:...)"
  default     = ""
}

variable "iso_download" {
  type        = bool
  description = "Download ISO if not found"
  default     = false
}

variable "iso_download_pve" {
  type        = bool
  description = "Download ISO directly from PVE node"
  default     = false
}

variable "iso_unmount" {
  type        = bool
  description = "Unmount ISO after installation"
  default     = true
}

variable "additional_iso_files" {
  type = list(object({
    iso_file     = string
    iso_url      = string
    iso_checksum = string
  }))
  description = "Additional ISO files (e.g. VirtIO drivers for Windows)"
  default     = []
}

# Hardware
variable "disk_size" {
  type        = string
  description = "Disk size (e.g. 20G, 40G)"
  default = "10G"
}

variable "disk_format" {
  type        = string
  description = "Disk format"
  default     = "raw"
}

variable "disk_type" {
  type        = string
  description = "Disk type (scsi, sata, virtio)"
  default     = "scsi"
}

variable "disk_cache" {
  type        = string
  description = "Disk cache mode"
  default     = "none"
}

variable "cpu_type" {
  type        = string
  description = "CPU type to emulate"
  default     = "host"
}

variable "cpu_sockets" {
  type        = number
  description = "Number of CPU sockets"
  default     = 1
}

variable "cpu_cores" {
  type        = number
  description = "Cores per socket"
  default     = 2
}

variable "memory" {
  type        = number
  description = "RAM in MB"
  default     = 4096
}

variable "network_bridge" {
  type        = string
  description = "Network bridge"
  default     = "vmbr0"
}

variable "network_adapter" {
  type        = string
  description = "Network bridge alias"
  default     = "vmbr0"
}

variable "network_adapter_model" {
  type        = string
  description = "Network model"
  default     = "virtio"
}

variable "network_adapter_mac" {
  type        = string
  description = "Override MAC address"
  default     = null
}

variable "network_adapter_vlan" {
  type        = number
  description = "VLAN tag (-1 = none)"
  default     = -1
}

variable "network_adapter_firewall" {
  type        = bool
  description = "Enable Proxmox firewall"
  default     = false
}

variable "os" {
  type        = string
  description = "OS type (l26/win10/win11)"
  default     = "l26"
}

variable "scsi_controller" {
  type        = string
  description = "SCSI controller model"
  default     = "virtio-scsi-pci"
}

variable "vga_type" {
  type        = string
  description = "VGA type"
  default     = "std"
}

variable "vga_memory" {
  type        = number
  description = "VGA memory (MiB)"
  default     = 32
}

variable "bios" {
  type        = string
  description = "BIOS type (seabios/ovmf)"
  default     = "seabios"
}

variable "qemu_agent" {
  type        = bool
  description = "Enable QEMU guest agent"
  default     = true
}

variable "start_at_boot" {
  type        = bool
  description = "Auto-start VM"
  default     = true
}

# Boot and communication
variable "boot_wait" {
  type        = string
  description = "Delay before boot command"
  default     = "5s"
}

variable "boot_command" {
  type        = list(string)
  description = "Boot command sequence"
  default     = []
}

variable "communicator" {
  type        = string
  description = "Packer communicator (ssh/winrm)"
  default     = "ssh"
}

variable "task_timeout" {
  type        = string
  description = "Proxmox task timeout"
  default     = "5m"
}

# Linux-specific
variable "ssh_username" {
  type        = string
  description = "SSH username"
  default     = "hybridops"
}

variable "ssh_password" {
  type        = string
  description = "SSH password"
  default     = "Temporary!"
  sensitive   = true
}

variable "ssh_private_key_file" {
  type        = string
  description = "Path to private key"
  default     = "~/.ssh/id_ed25519"
}

variable "ssh_timeout" {
  type        = string
  description = "SSH timeout"
  default     = "10m"
}

# Windows-specific
variable "winrm_username" {
  type        = string
  description = "WinRM username"
  default     = "Administrator"
}

variable "winrm_password" {
  type        = string
  description = "WinRM password"
  default     = "Temporary!"
  sensitive   = true
}

variable "winrm_insecure" {
  type        = bool
  description = "Skip WinRM SSL validation"
  default     = true
}

variable "winrm_use_ssl" {
  type        = bool
  description = "Use WinRM SSL"
  default     = false
}

variable "windows_edition" {
  type        = string
  description = "Windows edition"
  default     = ""
}

variable "windows_language" {
  type        = string
  description = "Windows display language"
  default     = "en-US"
}

variable "windows_input_language" {
  type        = string
  description = "Windows keyboard language"
  default     = "en-US"
}

variable "unattended_content" {
  type = map(object({
    template = string
    vars     = map(string)
  }))
  description = "Unattended install templates (Cloud-Init / Autounattend)"
  default     = {}
}

variable "additional_cd_files" {
  type = list(object({
    type  = string
    index = number
    files = list(string)
  }))
  description = "Additional CD/ISO attachments"
  default     = []
}

# Provisioning
variable "provisioner" {
  type        = list(string)
  description = "Custom provisioning commands (legacy placeholder)"
  default     = []
}

variable "driver_version" {
  type        = string
  description = "VirtIO driver version subdirectory (e.g., 2k22, 2k19)"
  default     = ""
}
