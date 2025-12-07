terraform {
  required_version = ">= 1.5.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.87.0"
    }
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  node_name = var.node_name
  name      = var.vm_name
  vm_id     = var.vm_id

  agent {
    enabled = true
  }

  cpu {
    cores = var.cpu_cores
    type  = var.cpu_type
  }

  memory {
    dedicated = var.memory_mb
  }

  disk {
    datastore_id = var.datastore_id
    file_id      = var.template_id
    interface    = "scsi0"
    size         = var.disk_size_gb
  }

  network_device {
    bridge  = var.network_bridge
    vlan_id = var.vlan_id
  }

  initialization {
    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }

    user_account {
      username = var.ssh_username
      keys     = var.ssh_keys
      password = var.ssh_password
    }

    user_data_file_id = var.cloud_init_user_data_file_id
  }

  operating_system {
    type = var.os_type
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      initialization[0].user_data_file_id,
    ]
  }
}
