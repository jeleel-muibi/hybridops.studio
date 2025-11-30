# generic.pkr.hcl
# Universal VM template builder for Proxmox
# Supports Linux (Ubuntu, Rocky, Debian) and Windows
#
# Author: Jeleel Muibi | HybridOps.Studio
# Created: 2025-11-08
# Updated: 2025-11-13

# ═══════════════════════════════════════════════════════════════════════════
# Local Variables
# ═══════════════════════════════════════════════════════════════════════════
locals {
  # Windows unattended content templating
  unattended_content = {
    for key, value in var.unattended_content : key => templatefile(
      value.template,
      merge(value.vars, {
        winrm_username         = var.winrm_username
        winrm_password         = var.winrm_password
        windows_edition        = lookup(value.vars, "windows_edition", var.windows_edition)
        windows_language       = lookup(value.vars, "windows_language", var.windows_language)
        windows_input_language = lookup(value.vars, "windows_input_language", var.windows_input_language)
        driver_version         = lookup(value.vars, "driver_version", "")
      })
    )
  }

  # Build unattended CD if Windows content exists
  unattended_as_cd = length(var.unattended_content) > 0 ? [{
    type    = "sata"
    index   = 3 + length(var.unattended_content)
    content = local.unattended_content
    label   = "Windows Unattended CD"
  }] : []

  # Merge additional CD files with Windows unattended content
  additional_cd_files = concat(var.additional_cd_files, local.unattended_as_cd)

  # SSH authentication strategy:
  # 1. Try SSH key if file exists (preferred, secure, no password in logs)
  # 2. Fall back to password if key unavailable (initial setup, testing)
  # 3. Null password when using key (prevents accidental password auth)
  ssh_key_path = var.ssh_private_key_file != "" ? var.ssh_private_key_file : "${path.root}/keys/packer_rsa"
  use_ssh_key  = fileexists(local.ssh_key_path)

  # Conditionally set auth method
  ssh_key_file = local.use_ssh_key ? local.ssh_key_path : null
  ssh_password = local.use_ssh_key ? null : var.ssh_password

  # For provisioner sudo commands - always needed even with key auth
  sudo_password = var.ssh_password
}

# ═══════════════════════════════════════════════════════════════════════════
# Proxmox ISO Source
# ═══════════════════════════════════════════════════════════════════════════
source "proxmox-iso" "vm" {
  # Proxmox connection
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_token_id
  token                    = var.proxmox_token_secret
  insecure_skip_tls_verify = var.proxmox_skip_tls_verify

  # VM metadata
  node                 = var.proxmox_node
  vm_id                = var.vmid
  vm_name              = var.name
  template_description = var.description != "" ? var.description : "${var.name} - Built ${timestamp()}"
  pool                 = var.pool

  # Hardware configuration
  cpu_type        = var.cpu_type
  sockets         = var.cpu_sockets
  cores           = var.cpu_cores
  memory          = var.memory
  scsi_controller = var.scsi_controller

  disks {
    type         = var.disk_type
    disk_size    = var.disk_size
    storage_pool = var.proxmox_storage_pool
    format       = var.disk_format
    cache_mode   = var.disk_cache
  }

  network_adapters {
    bridge      = var.network_adapter
    model       = var.network_adapter_model
    mac_address = var.network_adapter_mac
    vlan_tag    = var.network_adapter_vlan == -1 ? null : var.network_adapter_vlan
    firewall    = var.network_adapter_firewall
  }

  vga {
    type   = var.vga_type
    memory = var.vga_memory
  }

  # System configuration
  os         = var.os
  bios       = var.bios
  qemu_agent = var.qemu_agent
  onboot     = var.start_at_boot

  # Primary ISO configuration
  boot_iso {
    iso_file         = var.iso_download ? "" : "${var.proxmox_storage_pool_iso}:iso/${var.iso_file}"
    iso_storage_pool = var.proxmox_storage_pool_iso
    iso_url          = var.iso_download ? var.iso_url : ""
    iso_checksum     = var.iso_checksum
    iso_download_pve = var.iso_download_pve
    unmount          = var.iso_unmount
  }

  # Additional ISOs (VirtIO drivers, tools, etc.)
  dynamic "additional_iso_files" {
    for_each = var.additional_iso_files
    content {
      iso_file         = var.iso_download ? "" : "${var.proxmox_storage_pool_iso}:iso/${additional_iso_files.value.iso_file}"
      iso_storage_pool = var.proxmox_storage_pool_iso
      iso_url          = var.iso_download ? additional_iso_files.value.iso_url : ""
      iso_checksum     = additional_iso_files.value.iso_checksum
      iso_download_pve = var.iso_download_pve
      unmount          = var.iso_unmount
    }
  }

  # CD content (Windows Autounattend.xml, scripts, etc.)
  dynamic "additional_iso_files" {
    for_each = local.additional_cd_files
    iterator = iso
    content {
      type             = iso.value.type
      index            = iso.value.index
      iso_storage_pool = var.proxmox_storage_pool_iso
      cd_files         = contains(keys(iso.value), "files") ? iso.value.files : []
      cd_content       = contains(keys(iso.value), "content") ? iso.value.content : {}
      cd_label         = contains(keys(iso.value), "label") ? iso.value.label : ""
      unmount          = var.iso_unmount
    }
  }

  # Cloud-Init (Linux only)
  cloud_init              = var.cloud_init
  cloud_init_storage_pool = var.cloud_init_storage_pool

  # HTTP server for autoinstall/kickstart files
  http_directory    = var.http_directory != "" ? var.http_directory : "${path.root}/http"
  http_bind_address = var.http_bind_address
  http_port_min     = var.http_port
  http_port_max     = var.http_port

  # Boot configurations
  boot         = "order=${var.disk_type}0;ide2;net0"
  boot_wait    = var.boot_wait
  boot_command = var.boot_command
  task_timeout = var.task_timeout

  # SSH communicator (Linux only)
  # Strategy: SSH key preferred (secure), password fallback (testing/setup)
  # When key exists: uses key auth, password set to null
  # When key missing: uses password auth (less secure, logs show password attempts)
  communicator         = var.communicator
  ssh_username         = var.ssh_username
  ssh_private_key_file = local.ssh_key_file  # null if no key exists
  ssh_password         = local.ssh_password  # null if key exists
  ssh_timeout          = var.ssh_timeout

  # WinRM communicator (Windows only)
  winrm_username = var.winrm_username
  winrm_password = var.winrm_password
  winrm_insecure = var.winrm_insecure
  winrm_use_ssl  = var.winrm_use_ssl
}

# ═══════════════════════════════════════════════════════════════════════════
# Linux Build
# ═══════════════════════════════════════════════════════════════════════════
build {
  name    = "linux"
  sources = ["source.proxmox-iso.vm"]

  # Shell provisioner with sudo support
  # Note: Even with SSH key auth, sudo may require password
  # Uses ssh_password for sudo, not SSH authentication
  provisioner "shell" {
    execute_command = "echo '${local.sudo_password}' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
    inline          = length(var.provisioner) > 0 ? var.provisioner : ["echo 'No provisioning commands specified'"]
  }
}

# ═══════════════════════════════════════════════════════════════════════════
# Windows Build
# ═══════════════════════════════════════════════════════════════════════════
build {
  name    = "windows"
  sources = ["source.proxmox-iso.vm"]
}
