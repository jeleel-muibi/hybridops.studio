---
id: ADR-0003
title: "Secrets Management: K8s External/Sealed Secrets + KMS"
status: Accepted
date: 2025-10-05
domains: ["secops"]
owners: ["jeleel"]
supersedes: []
superseded_by: []
links:
  prs: []
  runbooks: []
  evidence: []
  diagrams: []
---

# Secrets Management: K8s External/Sealed Secrets + KMS

---

## Context
We need a GitOps-friendly approach to secret distribution across on‑prem and cloud clusters, with auditability and no plaintext secrets in Git.

## Decision
- Prefer **External Secrets** (or **Sealed Secrets** where appropriate) for Kubernetes secrets.
- Use **cloud KMS** (Azure Key Vault / GCP KMS) for encryption keys and secret backends; on‑prem HSM is optional.
- Non‑Kubernetes consumers (Ansible/Jenkins) use scoped credentials stores; no secrets in repo.

## Rationale
- Integrates tightly with GitOps pipelines (decrypt at deploy time).
- Provider-native KMS reduces custom cryptography and keeps audit trails in cloud platforms.
- Scales across clusters and environments with minimal drift.

## Consequences
- Requires KMS bootstrap and access policy management.
- Local development needs helper scripts to pull test creds securely.

## Verification
- GitOps syncs succeed with sealed/external secrets; no plaintext secrets leak into Git history.
- Audit logs show key usage and access.

## Links
- Evidence: `docs/proof/observability/`
- SecOps Roadmap: `docs/guides/secops-roadmap.md`
