// file: infra/terraform/live-v1/dev/10-platform/proxmox/vm/terragrunt.hcl
// purpose: Proxmox k3s node VMs for dev environment

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "sdn" {
  config_path = "../../../00-foundation/proxmox/sdn"

  mock_outputs = {
    zone_bridge = "vmbr0"
    vnet_details = {
      vnetdev1 = {
        tag = 20
      }
    }
    subnet_details = {
      vnetdev1 = {
        gateway = "10.20.0. 1"
        cidr    = "10.20. 0.0/24"
      }
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "ipam" {
  config_path = "../ipam"

  mock_outputs = {
    ip_with_cidr = ["10.20.0.10/24", "10.20.0.11/24", "10.20.0.12/24"]
    assigned_ips = ["10.20.0.10", "10. 20.0.11", "10.20.0.12"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

terraform {
  source = "../../../../../modules/proxmox/vm"
}

locals {
  # Environment metadata
  env_cfg     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment = local.env_cfg. locals.environment
  site        = local.env_cfg.locals. site

  # SDN vnet key (must match what SDN module creates)
  vnet_name = "vnetdev1"

  # VM layout
  vm_name_prefix = "${local.environment}-k3s-"

  # Node and datastore from env
  target_node  = get_env("PROXMOX_NODE", "hybridhub")
  datastore_id = get_env("PROXMOX_STORAGE_VM", "local-lvm")
}

inputs = {
  # Proxmox VM placement
  target_node    = local.target_node
  template_vm_id = 9003  # Rocky Linux 10 template
  datastore_id   = local.datastore_id

  vm_count       = 3
  vm_name_prefix = local.vm_name_prefix

  environment = local.environment
  site        = local.site
  role        = "k3s-node"

  os_family = "linux"
  os_name   = "rocky-10"

  # Network from SDN dependency
  bridge  = dependency.sdn.outputs.zone_bridge
  vlan_id = dependency.sdn.outputs.vnet_details[local.vnet_name]. tag

  # Static IP configuration from IPAM
  use_dhcp    = false
  static_ips  = dependency.ipam.outputs.ip_with_cidr  # e.g., ["10.20. 0.10/24", "10.20.0.11/24", "10.20.0. 12/24"]
  gateway     = dependency.sdn.outputs.subnet_details[local.vnet_name].gateway
  dns_servers = ["10.20.0.10", "8.8.8.8"]  # First VM will be DNS, plus Google DNS as backup

  cpu_cores    = 2
  memory_mb    = 4096
  disk_size_gb = 40

  extra_tags = ["terraform", "k3s", local.environment]
}
