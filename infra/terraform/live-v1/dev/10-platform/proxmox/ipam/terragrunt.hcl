include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/infra/terraform/modules/proxmox/ipam"
}

dependency "sdn" {
  config_path = "../../../00-foundation/proxmox/sdn"
}

inputs = {
  cidr            = "10.20.0.0/24"
  ip_range_start  = 10   # Start at 10.20.0.10
  ip_range_end    = 50   # End at 10.20.0.50 (40 IPs available for dev)
  vm_count        = 3     # Number of VMs to provision
  environment     = "dev"
  site            = "onprem"
}
