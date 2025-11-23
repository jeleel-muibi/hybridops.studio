---
id: ADR-0015
title: "Secrets Strategy — Azure Key Vault now; SOPS fallback; Vault optional later"
status: Accepted
date: 2025-10-20
domains: ["governance", "secops", "platform"]
owners: ["jeleel"]
supersedes: []
superseded_by: []
links:
  prs: []
  runbooks: ["../runbooks/bootstrap/bootstrap-ctrl01-node.md"]
  evidence: []
  diagrams: []
---

# ADR-0015 — Secrets Strategy: Azure Key Vault now; SOPS fallback; Vault optional later

## Status
Accepted — Azure Key Vault (AKV) is the primary secret backend for pipelines and Day‑0/Day‑1 automation. SOPS is available for encrypted‑at‑rest configuration where a file‑based workflow is simpler. HashiCorp Vault is earmarked as a phase‑2 enhancement for dynamic secrets.

## Context
- The portfolio must demonstrate **zero‑touch automation** (no UI credential entry) while remaining **auditable and enterprise‑ready**.
- Jenkins `ctrl-01` and ephemeral agents require credentials for Packer/Terraform/Ansible/cloud APIs without storing them in Git or the Jenkins UI.
- Two realistic approaches exist for the current delivery timeline:
  1) A managed KMS‑backed secret store (Azure Key Vault) with Entra ID authentication (Managed Identity or service principal).
  2) A self‑hosted Vault cluster (powerful, dynamic secrets) that entails more ops work: HA/Raft, TLS, auto‑unseal, backup/restore, and monitoring.

## Decision
- **Primary:** Use **Azure Key Vault** for CI secrets and bootstrap automation. Authenticate non‑interactively using **Entra ID** (Managed Identity where possible; service principal for on‑prem).
- **Fallback:** Use **SOPS** (age/PGP) for a small set of encrypted configuration files when a file‑based workflow is simpler (e.g., bootstrapping values in Git that are not high‑rotation secrets).
- **Phase‑2 (Optional):** Add **HashiCorp Vault** for dynamic secrets (DB creds/PKI/SSH certs) once core delivery is complete. Keep a thin abstraction (`SECRET_BACKEND=akv|sops|vault`) to avoid rewrites.

## Decision Drivers
- **Time‑to‑demo:** AKV provides enterprise‑grade security with minimal SRE tax.
- **Zero‑touch:** Entra ID + managed identities remove GUI credential handling.
- **Auditability:** AKV logging and RBAC provide a clear trail.
- **Cost:** At portfolio scale, AKV cost is negligible versus the ops cost of a Vault cluster.
- **Future‑proofing:** An abstraction layer allows later Vault adoption for dynamic use cases.

## Options Considered
- **Azure Key Vault (Chosen):** Managed lifecycle, Entra ID auth, clear RBAC/audit, least ops overhead.
- **HashiCorp Vault OSS:** Most powerful (dynamic secrets/PKI), but requires time to operate (TLS, auto‑unseal, Raft, backups, upgrades, alerting).
- **SOPS‑only:** Simple file encryption in Git; lacks rotation, audit events, and dynamic issuance.
- **Credentials in Git/Jenkins UI (Rejected):** Violates zero‑touch and audit requirements.

## Consequences
**Positive**
- Faster delivery; strong enterprise signal (RBAC, audit, KMS‑backed).
- Clean Jenkins pipelines with automated retrieval at runtime.
- Clear story: no credentials in Git; non‑interactive operations.

**Negative / Trade‑offs**
- No dynamic short‑lived secrets until Vault is added.
- Cloud dependency for reads (mitigated with local SOPS files for bootstrap‑only scenarios).

## Implementation Notes (high‑level, code‑free)
- All pipelines and scripts consult a single shim variable: `SECRET_BACKEND=akv|sops|vault`.
- **AKV:** prefer Managed Identity in cloud; use a service principal for `ctrl‑01` on‑prem. Enforce scoped RBAC and enable audit logs/alerts.
- **SOPS:** store only encrypted files in Git; keys are kept out of the repo; limit to bootstrap values, not high‑rotation secrets.
- **Vault (Phase‑2):** plan for Raft storage, auto‑unseal, TLS, backup/restore runbook, and monitoring. Introduce dynamic DB creds and short‑TTL cloud credentials when needed.

## References
- How‑to: [Provision ctrl‑01](../howto/HOWTO_ctrl01_provisioner.md)
- Runbook: [ctrl‑01 bootstrap / verification](../runbooks/bootstrap/bootstrap-ctrl01-node.md)
- Guide: [Cost & Telemetry](../guides/cost-model.md)
- Internal: [Maintenance Guide](../maintenance.md#adr-index-generation)

---

**Author / Maintainer:** Jeleel Muibi  
**Project:** HybridOps.Studio  
**License:** MIT‑0 / CC‑BY‑4.0
