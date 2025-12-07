TERRAFORM INFRASTRUCTURE
========================

STRUCTURE
---------
modules/proxmox/sdn/    SDN module (zones, VLANs, subnets)
live-v1/                Terragrunt environments

DEPLOYED ENVIRONMENTS
---------------------
Env      VLAN  Subnet          Purpose
mgmt     10    10.10.0.0/24    Management
obs      11    10.11.0.0/24    Observability
dev      20    10.20.0.0/24    Development
staging  30    10.30.0.0/24    Staging
prod     40    10.40.0.0/24    Production
netlab   50    10.50.0.0/24    Network Lab

USAGE
-----
cd live-v1/dev
terragrunt init && terragrunt plan && terragrunt apply

MODULE EXAMPLE
--------------
module "sdn" {
  source      = "../../modules/proxmox/sdn"
  zone_name   = "onprem-dev"
  vlan_id     = 20
  bridge      = "vmbr0"
  subnet_cidr = "10.20.0.0/24"
  gateway     = "10.20.0.1"
}

REQUIREMENTS
------------
- Terraform >= 1.5.0
- Terragrunt >= 0.67.0
- Provider: bpg/proxmox v0.87.0

VERSION: v0.1.0-sdn (6/6 deployed)
