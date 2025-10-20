# Terraform Environments

This folder contains **root Terraform environments** for cloud (Azure/GCP) and on‑prem (dev/staging/prod).

- Shared provider **version pins** live under:
  - `cloud/providers/common.tf`
  - `onprem/providers/common.tf`

- Each root env has **its own provider configuration** (`providers.tf`) and **backend** (`backend.hcl`).

## Usage

```bash
# Azure (DR attach / burst)
terraform -chdir=terraform-infra/cloud/azure init -backend-config=backend.hcl
terraform -chdir=terraform-infra/cloud/azure apply -var-file=vars.dr.tfvars

# GCP
terraform -chdir=terraform-infra/cloud/gcp init -backend-config=backend.hcl
terraform -chdir=terraform-infra/cloud/gcp apply -var-file=vars.dr.tfvars

# On‑prem (dev)
terraform -chdir=terraform-infra/onprem/dev init -backend-config=backend.hcl
terraform -chdir=terraform-infra/onprem/dev apply -var-file=dev.tfvars
```

> Modules should stay provider‑agnostic; wire providers from each root env as needed.
