// file: infra/terraform/modules/proxmox/vm/main.tf
// purpose: Create Proxmox VMs from a template using bpg/proxmox
// Maintainer: HybridOps.Studio
// date: 2025-11-29

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.87.0"
    }
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  count       = var.vm_count

  name        = format("%s%02d", var.vm_name_prefix, count.index + 1)
  node_name   = var.target_node

  description = "${var.environment}/${var.role}"
  started     = true
  on_boot     = true

  tags        = var.extra_tags

  agent {
    enabled = true
  }

  # Clone from an existing cloud-init capable template
  clone {
    node_name = var.target_node
    vm_id     = var.template_vm_id
    full      = true
  }

  operating_system {
    type = "l26"
  }

  # VM Hardware
  cpu {
    cores = var.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.memory_mb
  }

  boot_order    = ["scsi0", "net0"]
  scsi_hardware = "virtio-scsi-pci"

  # Network Configuration
  network_device {
    bridge   = var.bridge
    vlan_id  = var.vlan_id == 0 ? null : var.vlan_id
    model    = "virtio"
    firewall = false
    enabled  = true
  }

  # Cloud-init configuration for network setup
  initialization {
    datastore_id = var.datastore_id

    ip_config {
      ipv4 {
        address = var.use_dhcp ? "dhcp" : var.static_ips[count.index]
        gateway = var.use_dhcp ? null : var.gateway
      }
    }

    dns {
      servers = var.dns_servers
    }
  }
}
