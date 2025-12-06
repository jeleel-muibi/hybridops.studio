# Terraform Live Configuration: `live-v1`

**Owner:** HybridOps.Studio  
**Scope:** Infrastructure-as-Code (IaC) for `dev`, `staging`, and `prod` environments across Proxmox, Azure, and GCP.

---

## 1. Overview

The `live-v1` directory contains environment-specific Terragrunt configurations. These:
- Separate environments into `dev`, `staging`, and `prod`.
- Define resource stacks in **00-foundation** (e.g., networks) and **10-platform** (e.g., clusters).
- Use a shared root configuration (`terragrunt.hcl`) for state backend and shared variables.

---

## 2. Structure

```plaintext
live-v1/
  terragrunt.hcl          # Root: backend and shared configuration
  dev/                    # Development environment
    00-foundation/        # Foundational resources
      proxmox/sdn/        # SDN networks for Proxmox
      azure/network/      # Azure resource groups, VNets, subnets
      gcp/network/        # GCP VPCs, subnets
    10-platform/          # Platform services
      proxmox/vm/         # Proxmox k3s VMs
      azure/aks/          # Azure Kubernetes Service
      gcp/gke/            # Google Kubernetes Engine
  staging/…               # Staging (same pattern as `dev`)
  prod/…                  # Production (same pattern as `dev`)
```

---

## 3. Usage

### 3.1 Common Commands
Run from the root of the repository:
```bash
terragrunt init           # Initialize the stack (module + backend)
terragrunt plan           # Preview changes
terragrunt apply          # Deploy changes
```

### 3.2 Example Workflows

#### Proxmox (`dev`)
```bash
# Load Proxmox connection variables
set -a && . ../../env/.env.proxmox && set +a

# Plan/apply SDN resources
cd dev/00-foundation/proxmox/sdn
terragrunt plan

# Plan/apply VM cluster
cd ../../10-platform/proxmox/vm
terragrunt apply
```

#### Azure (`dev`)
```bash
# Load Azure authentication
source ../../control/provision/init-azure-env.sh

# Deploy VNets
cd dev/00-foundation/azure/network
terragrunt plan

# Deploy AKS cluster
cd ../../10-platform/azure/aks
terragrunt apply
```

#### GCP (`dev`)
```bash
# Load GCP setup
source ../../control/provision/init-gcp-env.sh
export GCP_PROJECT_ID="your-project-id"

# Deploy VPC setup
cd dev/00-foundation/gcp/network
terragrunt plan

# Deploy GKE cluster
cd ../../10-platform/gcp/gke
terragrunt apply
```

---

## 4. Outputs

All Terraform outputs are stored in a **centralized directory** under `output/artifacts/terraform` for easy access:
```plaintext
output/
  artifacts/
    terraform/
      onprem/
        dev/sdn/terraform-outputs.json
        dev/vm/terraform-outputs.json
        staging/
        prod/
      cloud/
        dev/network/terraform-outputs.json
        dev/aks/terraform-outputs.json
        staging/
        prod/
```

These outputs may be consumed by CI/CD pipelines, inventory tools, or documentation systems.

---

## 5. Mock Outputs

Mock outputs can be used for validation and planning when upstream dependencies are not yet deployed. To enable mock outputs:
```bash
export TERRAGRUNT_USE_MOCKS=true
terragrunt plan
```

For more details, refer to the specific [ipam module](../modules/ipam/README.md) that provides mock output examples.

---

## 6. Secrets Management

- **Proxmox**:
  - Stored in `.env.proxmox`, sourced during runtime.
- **Cloud Providers (Azure/GCP)**:
  - Initialized via `init-azure-env.sh` and `init-gcp-env.sh`, leveraging CLI authentication and secret backends (Azure Key Vault, GCP Secret Manager).

For further details, see:
- `docs/guides/secrets-lifecycle.md`

---
