# Terraform Infrastructure

Production‑style Terraform for a hybrid platform. Each folder under **cloud/** or **onprem/** is a **root** that owns its providers, backend, and module wiring.

## What this area provides
- **Clear separation:** roots per environment (Azure, GCP, on‑prem dev/staging/prod).
- **Consistent modules:** reusable building blocks in `modules/` (clusters, networking, GitOps, VPN, decision).
- **Provider strategy:** versions are pinned once; auth/config lives in each root.
- **SoT flow:** Terraform → NetBox (seed) → Ansible inventory (plugin).

## Execute
Azure
```bash
terraform -chdir=terraform-infra/cloud/azure init -backend-config=backend.hcl
terraform -chdir=terraform-infra/cloud/azure apply -var-file=vars.dr.tfvars
```
GCP
```bash
terraform -chdir=terraform-infra/cloud/gcp init -backend-config=backend.hcl
terraform -chdir=terraform-infra/cloud/gcp apply -var-file=vars.dr.tfvars
```
On‑prem (dev)
```bash
terraform -chdir=terraform-infra/onprem/dev init -backend-config=backend.hcl
terraform -chdir=terraform-infra/onprem/dev apply -var-file=dev.tfvars
```

## Module contract
Cluster modules (AKS/GKE/RKE2) expose:
```hcl
output "kube_host"  { value = ... }   # API server
output "kube_ca"    { value = ... }   # base64‑encoded
output "kube_token" { value = ... }   # sensitive
```
Roots consume these outputs to configure Kubernetes/Helm providers and drive GitOps bootstrap.

## SoT handoff
1) Emit Terraform outputs (JSON snapshot).
2) Seed NetBox from the snapshot (`deployment/netbox/seed/`).
3) Use Ansible’s NetBox inventory for all runs.

## CI & Security
- CI: `lint-terraform.yml` (fmt/validate), `gitops-dry-run.yml` (kustomize build of overlays).
- Secrets: pass credentials via CI secrets or local env; no secrets in files.

---
**Related:** [Project README](../README.md) · [Deployment](../deployment/README.md) · [Evidence Map](../docs/evidence_map.md) · [Runbooks](../docs/runbooks/README.md)
