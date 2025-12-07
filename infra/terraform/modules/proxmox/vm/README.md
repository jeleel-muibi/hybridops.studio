# Proxmox VM Module

Generic, reusable module for deploying VMs on Proxmox VE with cloud-init support.

## Features

- Cloud-init Day-0 configuration
- Static IP assignment (configurable)
- VLAN support (optional)
- Flexible resource allocation (CPU, RAM, disk)
- Template/image cloning
- Tag management
- Customizable cloud-init user data

## Design Philosophy

This module is intentionally generic and can be used for:
- Jenkins controllers (ctrl-01)
- PostgreSQL databases
- NetBox IPAM
- Application servers
- Ephemeral agents
- Any Linux VM workload

All VM-specific configuration (Jenkins installation, database setup, etc.)
is passed via cloud-init user data in the deployment layer (terragrunt.hcl).

## Usage Example

See `live-v1/ctrl01/terragrunt.hcl` for a complete ctrl-01 deployment example.

## Requirements

- Terraform >= 1.5.0
- Proxmox Provider: bpg/proxmox v0.87.0
- Cloud-init enabled template/image on Proxmox

## Key Inputs

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| node_name | Yes | - | Proxmox node name |
| vm_name | Yes | - | VM name |
| datastore_id | Yes | - | Datastore ID for VM disks |
| ip_address | Yes | - | Static IP in CIDR format (e.g., 10.10.0.100/24) |
| gateway | Yes | - | Network gateway |
| cpu_cores | No | 2 | Number of CPU cores |
| memory_mb | No | 2048 | Memory in MB |
| disk_size_gb | No | 32 | Disk size in GB |
| vlan_id | No | null | VLAN ID (optional) |
| template_id | No | null | Template/image ID to clone |
| ssh_keys | No | [] | List of SSH public keys |
| cloud_init_user_data_file_id | No | null | Cloud-init user data file ID |
| tags | No | [] | List of tags |

## Outputs

- vm_id: Proxmox VM ID
- vm_name: VM name
- ip_address: VM IP address
- node_name: Proxmox node hosting the VM
- tags: Applied VM tags

## Future Enhancements

- DHCP support (currently static IP only)
- NetBox IPAM integration (Phase 3)
- Multiple network interfaces
- Cloud-init via inline YAML (not just file_id)
