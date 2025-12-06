// file: infra/terraform/live-v1/root.hcl
// purpose: Root Terragrunt configuration for HybridOps Studio live-v1
// Maintainer: HybridOps. Studio
// date: 2025-12-06

locals {
  # Proxmox credential management
  proxmox_endpoint        = get_env("PROXMOX_URL", "")
  proxmox_token_id        = get_env("PROXMOX_TOKEN_ID", "")
  proxmox_token_secret    = get_env("PROXMOX_TOKEN_SECRET", "")
  proxmox_skip_tls_verify = get_env("PROXMOX_SKIP_TLS_VERIFY", "true") == "true"

  # Extract the platform based on the directory structure (on-prem vs cloud)
  platform = can(regex(".*\\/proxmox.*", path_relative_to_include())) ? "onprem" : "cloud"

  # Extract the environment (dev, staging, prod) based on the path hierarchy
  path_parts  = split("/", path_relative_to_include())
  environment = length(local.path_parts) > 0 ? local.path_parts[0] : "dev"

  # Construct output paths
  relative_dir = replace(path_relative_to_include(), "/", "-")
  output_dir   = "${get_repo_root()}/output/artifacts/terraform/${local.platform}/${local. environment}"
  json_output  = "${local.output_dir}/${local. relative_dir}.json"
}

# Dynamically generate the Proxmox provider configuration
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

# Configure local backend for state management
remote_state {
  backend = "local"
  config = {
    path = "${get_repo_root()}/infra/terraform/live-v1/. terragrunt-state/${path_relative_to_include()}. tfstate"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Hooks for output processing
terraform {
  after_hook "save_json_outputs" {
    commands     = ["apply"]
    execute      = ["sh", "-c", "mkdir -p ${local.output_dir} && terraform output -json > ${local. json_output} 2>/dev/null || true"]
    run_on_error = false
  }
}
