// file: infra/terraform/modules/proxmox/vm/main.tf
// purpose: Create Proxmox VMs from a template using bpg/proxmox
// author: Jeleel Muibi
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
  count = var.vm_count

  name      = format("%s%02d", var.vm_name_prefix, count.index + 1)
  node_name = var.target_node

  description = "${var.environment}/${var.role}"
  started     = true
  on_boot     = true

  tags = var.extra_tags

  agent {
    enabled = true
  }

  # Clone from an existing cloud-init capable template
  clone {
    node_name = var. target_node
    vm_id     = var.template_vm_id
    full      = true
  }

  operating_system {
    type = "l26"
  }

  cpu {
    cores = var.cpu_cores
    type  = "host"  # ← ADD THIS - match the template's CPU type
  }

  memory {
    dedicated = var.memory_mb
  }

  # Explicitly set boot order and SCSI hardware to match template
  boot_order    = ["scsi0", "net0"]
  scsi_hardware = "virtio-scsi-pci"

  network_device {
    bridge   = var.bridge
    vlan_id  = var.vlan_id == 0 ? null : var. vlan_id
    model    = "virtio"
    firewall = false
    enabled  = true
  }
}
