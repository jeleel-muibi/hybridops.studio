# file: infra/terraform/modules/proxmox/vm/main.tf
# purpose: Generic Proxmox VM resource (supports cloning from template)

resource "proxmox_virtual_environment_vm" "vm" {
  node_name = var.node_name
  name      = var.vm_name
  vm_id     = var.vm_id
  tags      = var.tags
  on_boot   = var.on_boot

  # Clone from template if template_vm_id is provided
  dynamic "clone" {
    for_each = var.template_vm_id != null ? [1] : []
    content {
      vm_id = var.template_vm_id
      full  = true
    }
  }

  # CPU configuration
  cpu {
    cores = var.cpu_cores
    type  = var.cpu_type
  }

  # Memory configuration
  memory {
    dedicated = var.memory_mb
  }

  # Disk configuration
  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.disk_size_gb
    file_format  = "raw"
  }

  # Network configuration
  network_device {
    bridge  = var.network_bridge
    vlan_id = var.vlan_id
  }

  # QEMU Guest Agent
  agent {
    enabled = true
  }

  # Operating system
  operating_system {
    type = var.os_type
  }

  # Cloud-init configuration
  initialization {
    datastore_id = var.datastore_id

    # IP configuration
    ip_config {
      ipv4 {
        address = var.ip_address == "dhcp" ? "dhcp" : var.ip_address
        gateway = var.ip_address == "dhcp" ?  null : var.gateway
      }
    }

    # DNS configuration (only for static IP)
    dynamic "dns" {
      for_each = var.nameservers != null ? [1] : []
      content {
        servers = split(",", var.nameservers)
      }
    }

    # User account
    user_account {
      username = var.ssh_username
      keys     = var.ssh_keys
    }
  }
}
