## [Unreleased]
- Planned: Add CI/CD pipeline for decision-service and Terraform workflows
- Planned: Populate AKS and GKE showcases with autoscaling and GitOps examples

## [2025-09-17] Initial Structure Established
- Added universal compute module with provider-specific submodules (Proxmox, Azure)
- Created modules for network, VPN (NCC hub/spokes), and Kubernetes
- Defined environments for onprem (dev, staging, prod) and cloud (Azure, GCP)
- Added scenarios for failover-tests and migration-tests with isolated state
- Implemented backend-configs for Terraform Cloud workspaces: dev, staging, prod, scenario
- Introduced cloud-showcases folder for standalone AKS and GKE demos
- Integrated Cloud DNS failover policy with public IP health checks
- Built decision-service to select Azure or GCP based on budget and health
- Established Ansible integration consuming Terraform outputs at runtime
- Created terraform/output folder to store terraform_outputs.json
- Added root-level README.md and folder-specific documentation
