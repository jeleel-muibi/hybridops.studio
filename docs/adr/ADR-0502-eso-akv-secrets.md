---
id: ADR-0502
title: "Use External Secrets Operator with Azure Key Vault for Application Secrets"
status: Accepted
date: 2025-12-02
category: "05-data-storage"    # One of:
                              # "00-governance"
                              # "01-networking"
                              # "02-platform"
                              # "03-security"
                              # "04-observability"
                              # "05-data-storage"
                              # "06-cicd-automation"
                              # "07-disaster-recovery"
                              # "08-cost-optimisation"
                              # "09-compliance"

domains: ["platform", "security"]
owners: ["HybridOps.Studio"]
supersedes: []
superseded_by: []

links:
  prs: []
  runbooks: []
  howtos:
    - "../howtos/HOWTO_rke2_bootstrap_from_proxmox_templates.md"
  evidence:
    - "../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md"
  diagrams: []
  related_docs:
    - "./ADR-0202-rke2-primary-runtime-for-platform-and-apps.md"
    - "./ADR-0016-packer-cloudinit-vm-templates.md"
---

_Status: Accepted (2025-12-02)_

---

# Use External Secrets Operator with Azure Key Vault for Application Secrets

## 1. Context

HybridOps.Studio runs workloads on:

- **RKE2** clusters backed by Proxmox.  
- A shared PostgreSQL LXC (db-01) for stateful services such as NetBox.  

Early iterations used:

- Local `Secret` manifests with inline values in development, and  
- Environment-specific `.env` files during bootstrap.

This approach:

- Does not scale beyond a single operator.  
- Increases the risk of secret sprawl and accidental commits.  
- Makes rotation and revocation harder to orchestrate.

HybridOps.Studio already integrates with Azure for cloud resources and cost-aware DR, making **Azure Key Vault (AKV)** a natural candidate for central secret storage.

We want:

- A way for Kubernetes workloads on RKE2 to fetch secrets **on-demand** from a central vault.  
- Minimal plaintext secret handling in CI pipelines.  
- A pattern that is common in enterprise environments.

## 2. Decision

HybridOps.Studio adopts:

- **Azure Key Vault (AKV)** as the central store for application and platform secrets.  
- **External Secrets Operator (ESO)** as the mechanism to project secrets from AKV into Kubernetes clusters.

In practice:

- Secrets are created and managed in AKV with clear naming and ownership.  
- For each application, one or more `ExternalSecret` resources are defined in Git.  
- ESO reconciles these resources, creating or updating Kubernetes `Secret` objects as required.  
- Pods consume secrets via standard environment variables or mounted secret volumes.

Local `.env` usage is limited to:

- Bootstrap and development scenarios, and  
- Never committed to Git.

## 3. Rationale

### 3.1 Why Azure Key Vault?

- Already used for other Azure integrations and DR-related components.  
- Managed service with:
  - Role-based access control,  
  - Audit logging, and  
  - Built-in rotation support.  
- Aligns with patterns commonly seen in enterprise Azure environments.

### 3.2 Why External Secrets Operator?

- ESO provides a **Kubernetes-native** abstraction for external secret stores.  
- It supports AKV out of the box and can later support other backends if needed.  
- It fits the GitOps model:
  - `ExternalSecret` resources live in Git.  
  - The operator reconciles them into runtime secrets.

This keeps application manifests declarative while avoiding hard-coded secret values.

## 4. Consequences

### 4.1 Positive

- **Centralised secret management**  
  - Secrets live in AKV, not scattered across manifests or CI variables.

- **Improved security posture**  
  - Reduced risk of secrets landing in Git history.  
  - Clear access control and audit via AKV.

- **Better GitOps alignment**  
  - Secret references are declarative, while values stay out of the repo.

### 4.2 Negative / trade-offs

- **Operational dependency on AKV and ESO**  
  - ESO and AKV must be available for secrets to be reconciled or updated.

- **Bootstrap complexity**  
  - ESO itself needs to be deployed and given credentials (for example, via workload identity or managed identities), which requires careful bootstrapping.

- **Local development considerations**  
  - Developers need a way to fetch or simulate AKV secrets locally without bypassing the pattern entirely.

## 5. Implementation

### 5.1 Secret lifecycle

- Secrets are created in AKV by a small number of trusted operators or automated tools.  
- Names follow a consistent naming convention (for example, `netbox-db-password`, `jenkins-admin-password`).  
- ESO is configured with:
  - Access to specific AKV instances,  
  - Mapped to namespaces or applications as needed.

### 5.2 Git representation

- For each application namespace, a set of `ExternalSecret` manifests is stored under a path such as:

  - `deploy/<app>/secrets/externalsecret-*.yaml`

- These manifests specify:
  - The AKV secret name,  
  - The target Kubernetes `Secret` name, and  
  - Any required mapping/templating.

### 5.3 CI/CD integration

- Jenkins pipelines and GitHub Actions **do not handle raw secrets** except where strictly required for bootstrap.  
- Pipelines may validate the existence of required AKV entries (for example, smoke tests), but they avoid printing or logging secret values.

## 6. Operational considerations

- ESO and AKV integrations must be included in:
  - DR planning (for example, what happens if AKV is unavailable).  
  - Access reviews and audits.

- Documentation and Academy content should show:
  - How to create a new secret in AKV.  
  - How to wire it into RKE2 via `ExternalSecret`.  
  - How rotation affects running workloads.

## 7. References

- [ADR-0202 – Adopt RKE2 as Primary Runtime for Platform and Applications](./ADR-0202-rke2-primary-runtime-for-platform-and-apps.md)  
- [ADR-0016 – Packer + Cloud-Init VM Templates for Proxmox](./ADR-0016-packer-cloudinit-vm-templates.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation
