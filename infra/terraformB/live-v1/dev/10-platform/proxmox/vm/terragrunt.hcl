include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "sdn" {
  config_path = "../../../00-foundation/proxmox/sdn"
}

terraform {
  source = "../../../../../../modules/proxmox/vm"
}

inputs = {
  target_node    = get_env("PROXMOX_NODE", "pve-node1")
  datastore_id   = get_env("PROXMOX_STORAGE_VM", "local-lvm")
  template_vm_id = 9000

  # VM Configurations
  vm_count       = 2
  vm_name_prefix = "test-vm-"
  environment    = "dev"
  role           = "test"

  # Use SDN outputs for networking
  bridge         = dependency.sdn.outputs.bridge_name
  vlan_id        = dependency.sdn.outputs.vlan_tag
  static_ips     = ["10.20.0.10", "10.20.0.11"]
  gateway        = dependency.sdn.outputs.gateway

  # Optional: DNS entries (default to SDN-provided or override)
  dns_servers    = dependency.sdn.outputs.dns_servers

  # Hardware & Metadata
  cpu_cores      = 2
  memory_mb      = 2048
  disk_size_gb   = 20
  extra_tags     = ["terraform", "testing"]
}
