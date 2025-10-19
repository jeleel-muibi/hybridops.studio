---
id: ADR-0003
title: "Secrets Management: Kubernetes External Secrets + KMS Integration"
status: Accepted
date: 2025-10-07
domains: ["security", "platform", "kubernetes"]
owners: ["jeleel"]
supersedes: []
superseded_by: []
links:
  prs: []
  runbooks: ["../runbooks/security/k8s-external-secrets.md"]
  evidence: ["../proof/security/k8s-secrets-demo/"]
  diagrams: ["../diagrams/k8s_external_secrets_flow.png"]
---

# ADR-0003 — Secrets Management: Kubernetes External Secrets + KMS Integration

## Status
Accepted — Standardized approach to secrets lifecycle management in Kubernetes clusters using **External Secrets Operator (ESO)** with **cloud-native KMS** backends.

## Context
HybridOps.Studio spans multiple Kubernetes environments (on-prem RKE2 and cloud AKS/GKE).  
Each cluster needs a **secure, consistent way** to retrieve and sync secrets without embedding credentials in Git or container images.  
Traditional Kubernetes `Secret` objects lack encryption-at-rest portability and introduce compliance concerns when manually handled.

We require:
- Unified secret lifecycle across clouds and on-prem.  
- No plaintext secrets in Git repositories.  
- Support for auto-rotation and cloud KMS backends.

## Decision
Implement **Kubernetes External Secrets Operator (ESO)** with KMS integration.

### Key design points
- Use **Azure Key Vault** and **Google Secret Manager** as backend providers.  
- On-prem RKE2 clusters use **Vault or SOPS** with encrypted sync to ESO.  
- ESO polls the KMS and reconciles into native Kubernetes Secrets.  
- Ansible or Terraform define secret manifests declaratively.  
- RBAC restricts ESO namespaces to relevant workloads (e.g., Jenkins, NetBox).

### Workflow summary
1. Developers or pipelines push encrypted values to the appropriate KMS.  
2. ESO fetches and injects decrypted data into target namespaces.  
3. Jenkins jobs reference Secrets via environment variables.  
4. Logs and audit trails remain in the cloud provider KMS for traceability.

## Consequences
- ✅ Eliminates hardcoded secrets from Git.  
- ✅ Enables full multi-cloud and hybrid support.  
- ⚠️ Requires KMS IAM setup in each environment.  
- ⚠️ Adds dependency on ESO availability and CRD reconciliation timing.

## References
- [Runbook: Kubernetes External Secrets Bootstrap](../runbooks/security/k8s-external-secrets.md)  
- [Diagram: K8s Secrets Flow](../diagrams/k8s_external_secrets_flow.png)  
- [Evidence: Secrets Demo Logs](../proof/security/k8s-secrets-demo/)  

---

**Author / Maintainer:** Jeleel Muibi  
**Project:** [HybridOps.Studio](https://github.com/jeleel-muibi/hybridops.studio)  
**License:** MIT-0 / CC-BY-4.0
