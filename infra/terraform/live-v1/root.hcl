// file: infra/terraform/live-v1/root.hcl
// purpose: Root Terragrunt configuration for HybridOps Studio live-v1
// author: Jeleel Muibi
// date: 2025-11-29

locals {
  proxmox_endpoint        = get_env("PROXMOX_URL", "")
  proxmox_token_id        = get_env("PROXMOX_TOKEN_ID", "")
  proxmox_token_secret    = get_env("PROXMOX_TOKEN_SECRET", "")
  proxmox_skip_tls_verify = (get_env("PROXMOX_SKIP_TLS_VERIFY", "true") == "true")
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "proxmox" {
  endpoint  = "${local.proxmox_endpoint}"
  api_token = "${local.proxmox_token_id}=${local.proxmox_token_secret}"
  insecure  = ${local.proxmox_skip_tls_verify}

  ssh {
    agent    = true
    username = "root"
  }
}
EOF
}

remote_state {
  backend = "local"
  config = {
    path = "${get_repo_root()}/infra/terraform/live-v1/.terragrunt-state/${path_relative_to_include()}.tfstate"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
