// file: infra/terraform/live-v1/dev/10-platform/proxmox/ipam/terragrunt.hcl
// purpose: IPAM hostname-keyed IP allocations for dev environment

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infra/terraform/modules/proxmox/ipam"
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
        gateway = "10.20.0.1"
        cidr    = "10.20.0.0/24"
      }
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  # Map of VLAN ID to subnet CIDR
  subnet_map = {
    "20" = "10.20.0.0/24"
  }

  # Hostname-based allocations for dev environment
  allocations = {
    # K3s cluster nodes
    "dev-k3s-01" = {
      vlan   = "20"
      offset = 10
    }
    "dev-k3s-02" = {
      vlan   = "20"
      offset = 11
    }
    "dev-k3s-03" = {
      vlan   = "20"
      offset = 12
    }

    # Monitoring infrastructure
    "prometheus-01" = {
      vlan   = "20"
      offset = 20
    }
  }

  # Allocation constraints
  offset_min = 10
  offset_max = 250

  # Enable validation
  validate_requests = true
}
