terraform {
  source = "../../modules/proxmox/vm"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  # VM Configuration
  node_name    = "pve"
  vm_name      = "ctrl-01"
  vm_id        = 100

  # Resources
  cpu_cores    = 4
  cpu_type     = "host"
  memory_mb    = 8192
  disk_size_gb = 64

  # Storage
  datastore_id = "local-lvm"
  template_id  = "local:iso/ubuntu-22.04-cloudimg.img"

  # Network - Management VLAN
  network_bridge = "vmbr0"
  vlan_id        = 10
  ip_address     = "10.10.0.100/24"
  gateway        = "10.10.0.1"

  # Cloud-init
  ssh_username = "sysadmin"
  ssh_keys     = [
    # Add your SSH public key here
    # "ssh-rsa AAAA..."
  ]

  # Tags
  tags = [
    "terraform",
    "jenkins",
    "control-plane",
    "management"
  ]
}
