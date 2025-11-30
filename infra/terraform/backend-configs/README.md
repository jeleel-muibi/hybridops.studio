# OPTIONAL FALLBACK — Terraform Cloud Backend (Manual Only)

Primary flow uses **Terragrunt**, which auto-generates the TFC backend (see `live/terragrunt.hcl`).  
This folder is **only** for rare, manual `terraform init` runs (e.g., day-0 bootstrap before Jenkins).

```bash
export TF_TOKEN_app_terraform_io=<your_tfc_token>
WS="cloud-azure-staging-10-platform-keyvault"   # example workspace name

terraform init \
  -backend-config=infra/terraform/backend-configs/tfc.remote.tfbackend \
  -backend-config="organization=YOUR_TFC_ORG" \
  -backend-config="workspaces.name=${WS}"
