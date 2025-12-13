# file: infra/terraform/live-v1/ctrl01/terragrunt.hcl
# purpose: Control plane node 01 with DHCP on VLAN 10

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/proxmox/vm"
}

inputs = {
  # VM identification
  node_name = "hybridhub"
  vm_name   = "ctrl-01"
  vm_id     = 100

  # Clone from template 9004
  template_vm_id = 9004

  # Resources
  cpu_cores    = 2
  cpu_type     = "host"
  memory_mb    = 4096
  disk_size_gb = 32

  # Storage
  datastore_id = "local-lvm"

  # Network (VLAN 10 with DHCP)
  network_bridge = "vmbr0"
  vlan_id        = 10
  ip_address     = "dhcp"  # Gateway and DNS provided by DHCP server

  # Cloud-init
  ssh_username = "hybridops"
  ssh_keys     = []  # Will use key from Proxmox

  # Metadata
  os_type = "l26"
  tags    = ["terraform", "ctrl-plane", "k3s"]
}
