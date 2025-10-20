# Backend Configs
This folder contains Terraform backend configuration files for different environments.
Each file defines a remote backend pointing to a specific Terraform Cloud workspace:

Initialize Terraform with:

```bash
# Azure
terraform -chdir=../../environments/cloud/azure init -reconfigure -backend-config=$(pwd)/azure.backend.hcl

# GCP
terraform -chdir=../../environments/cloud/gcp init -reconfigure -backend-config=$(pwd)/gcp.backend.hcl
```
