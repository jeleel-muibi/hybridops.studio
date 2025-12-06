// file: infra/terraform/live-v1/root.hcl
// purpose: Root configuration shared across all environments in the on-premises deployment

locals {
  # Global configuration
  site_name        = "onprem"
  organization     = "hybridops"

  # Terraform state backend (local for on-prem, can be S3/GCS for cloud)
  state_base_path  = "${get_repo_root()}/infra/terraform/live-v1/.terragrunt-state"
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
      version = "~> 0.87.0"
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
  proxmox_url      = get_env("PROXMOX_URL", "")
  proxmox_token    = format("%s=%s",
                       get_env("PROXMOX_TOKEN_ID", ""),
                       get_env("PROXMOX_TOKEN_SECRET", ""))
  proxmox_insecure = get_env("PROXMOX_SKIP_TLS_VERIFY", "false") == "true"
  proxmox_node     = get_env("PROXMOX_NODE", "")

  # Global tags
  tags = {
    managed_by  = "terraform"
    project     = "hybridops-blueprint"
    site        = local.site_name
    organization = local.organization
  }
}
