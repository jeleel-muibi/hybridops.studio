include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "sdn" {
  config_path = "../../../00-foundation/proxmox/sdn"
}

inputs = {
  subnet_map = {
    for k, v in dependency.sdn.outputs.vnet_details :
    k => v.cidr
  }

  allocations = {
    "dev-k3s-01" = { vlan = 20, offset = 10 }
    "dev-k3s-02" = { vlan = 20, offset = 11 }
    "dev-k3s-03" = { vlan = 20, offset = 12 }
  }

  offset_min        = 10
  offset_max        = 250
  validate_requests = true
}
