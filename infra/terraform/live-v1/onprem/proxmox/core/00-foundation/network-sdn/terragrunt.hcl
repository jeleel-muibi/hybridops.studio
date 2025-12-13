include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infra/terraform/modules/proxmox/sdn"
}

inputs = {
  # Inherited from root.hcl:
  # - proxmox_node = "PROXMOX_HOSTNAME"
  # - proxmox_host = "PROXMOX_IP_ADDRESS"
  # - proxmox_bridge = "PROXMOX_BRIDGE_NAME"
  # - sdn_zone_name = "PROX_SDN_ZONE"

  # Map sdn_zone_name from root to zone_name expected by module
  zone_name = "hybzone"

  vnets = {
    vnetmgmt = {
      vlan_id     = 10
      description = "Management network"
      subnets = {
        submgmt = {
          cidr               = "10.10.0.0/24"
          gateway            = "10.10.0.1"
          vnet               = "vnetmgmt"
          dhcp_enabled       = true
          dhcp_range_start   = "10.10.0.100"
          dhcp_range_end     = "10.10.0.200"
          dhcp_dns_server    = "8.8.8.8"
        }
      }
    }
    vnetobs = {
      vlan_id     = 11
      description = "Observability network"
      subnets = {
        subobs = {
          cidr               = "10.11.0.0/24"
          gateway            = "10.11.0.1"
          vnet               = "vnetobs"
          dhcp_enabled       = true
          dhcp_range_start   = "10.11.0.100"
          dhcp_range_end     = "10.11.0.200"
          dhcp_dns_server    = "8.8.8.8"
        }
      }
    }
    vnetdev = {
      vlan_id     = 20
      description = "Development network"
      subnets = {
        subdev = {
          cidr               = "10.20.0.0/24"
          gateway            = "10.20.0.1"
          vnet               = "vnetdev"
          dhcp_enabled       = true
          dhcp_range_start   = "10.20.0.100"
          dhcp_range_end     = "10.20.0.200"
          dhcp_dns_server    = "8.8.8.8"
        }
      }
    }
    vnetstag = {
      vlan_id     = 30
      description = "Staging network"
      subnets = {
        substag = {
          cidr               = "10.30.0.0/24"
          gateway            = "10.30.0.1"
          vnet               = "vnetstag"
          dhcp_enabled       = true
          dhcp_range_start   = "10.30.0.100"
          dhcp_range_end     = "10.30.0.200"
          dhcp_dns_server    = "8.8.8.8"
        }
      }
    }
    vnetprod = {
      vlan_id     = 40
      description = "Production network"
      subnets = {
        subprod = {
          cidr               = "10.40.0.0/24"
          gateway            = "10.40.0.1"
          vnet               = "vnetprod"
          dhcp_enabled       = true
          dhcp_range_start   = "10.40.0.100"
          dhcp_range_end     = "10.40.0.200"
          dhcp_dns_server    = "8.8.8.8"
        }
      }
    }
    vnetlab = {
      vlan_id     = 50
      description = "Lab network"
      subnets = {
        sublab = {
          cidr               = "10.50.0.0/24"
          gateway            = "10.50.0.1"
          vnet               = "vnetlab"
          dhcp_enabled       = true
          dhcp_range_start   = "10.50.0.100"
          dhcp_range_end     = "10.50.0.200"
          dhcp_dns_server    = "8.8.8.8"
        }
      }
    }
  }
}
