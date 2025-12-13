# file: infra/terraform/live-v1/root.hcl
# purpose: Root configuration shared across all environments in the on-premises deployment

locals {
  # Global configuration
  site_name        = "onprem"
  organization     = "hybridops"

  # Terraform state backend (local for on-prem, can be S3/GCS for cloud)
  state_base_path  = "${get_repo_root()}/infra/terraform/live-v1/.terragrunt-state"

  # Module base path
  module_base      = "${get_repo_root()}/infra/terraform/modules"

  # Extract Proxmox details from environment
  proxmox_url      = get_env("PROXMOX_URL", "")
  proxmox_node     = get_env("PROXMOX_NODE", "")

  # Parse host from PROXMOX_URL using split (simpler and more reliable)
  # https://192.168.0.27:8006/api2/json → split by "/" → ["https:", "", "192.168.0.27:8006", ...]
  proxmox_url_parts = split("/", local.proxmox_url)
  proxmox_host_port = local.proxmox_url_parts[2]
  proxmox_host      = split(":", local.proxmox_host_port)[0]

  # Default SDN zone name
  sdn_zone_name    = get_env("PROXMOX_SDN_ZONE", "hybzone")

  # Default bridge
  proxmox_bridge   = get_env("PROXMOX_BRIDGE", "vmbr0")
}

# Generate backend configuration for local state
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "local" {
    path = "${local.state_base_path}/${path_relative_to_include()}.tfstate"
  }
}
EOF
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.89.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_url
  api_token = var.proxmox_token
  insecure  = var.proxmox_insecure
  ssh {
    agent    = true
    username = "root"
  }
}
EOF
}

# Common variables for all modules
inputs = {
  # Proxmox API
  proxmox_url      = local.proxmox_url
  proxmox_token    = format("%s=%s",
                       get_env("PROXMOX_TOKEN_ID", ""),
                       get_env("PROXMOX_TOKEN_SECRET", ""))
  proxmox_insecure = get_env("PROXMOX_SKIP_TLS_VERIFY", "false") == "true"

  # Proxmox infrastructure
  proxmox_node     = local.proxmox_node
  proxmox_host     = local.proxmox_host
  proxmox_bridge   = local.proxmox_bridge

  # SDN defaults
  sdn_zone_name    = local.sdn_zone_name

  # Global tags
  tags = {
    managed_by   = "terraform"
    project      = "hybridops-blueprint"
    site         = local.site_name
    organization = local.organization
  }
}
