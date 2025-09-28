# Backend Configs
This folder contains Terraform backend configuration files for different environments.
Each file defines a remote backend pointing to a specific Terraform Cloud workspace:

- `dev_backend.tf` → workspace `dev`
- `staging_backend.tf` → workspace `staging`
- `prod_backend.tf` → workspace `prod`
- `scenario_backend.tf` → workspace `scenario`

These files enable isolated state management across environments.
