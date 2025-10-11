# Technical Architecture

This section outlines the major components and flows that power HybridOps.Studio. Detailed diagrams live in **Diagrams & Guides**; proofs for each assertion live under the **Proof Archive**.

## Core Components
- **Control plane (on‑prem):** RKE2 (Kubernetes) with GitOps (ArgoCD/Flux). Rancher optional for fleet access.
- **Data layer:** PostgreSQL primary remains on‑prem; **WAL‑G** handles offsite backups and restores for DR.
  Evidence: [SQL RO & RPO](../proof/sql-ro/README.md)
- **Networking:** Google **NCC** provides hub‑and‑spoke connectivity across sites/clouds.
  Evidence: [NCC](../proof/ncc/README.md)
- **Observability:** **Prometheus Federation** aggregates metrics; **Grafana** provides DR panels and autoscale traces.
  Evidence: [Observability](../proof/observability/README.md)
- **Decision Service:** Policy engine that selects Azure/GCP using federation metrics, cloud monitoring, and credits.
  Evidence: [Decision Service](../proof/decision-service/README.md)
- **Images & CI/CD:** Packer builds base images; Jenkins primary CI with GitHub Actions fallback.
  Evidence: [Runtime Images](../proof/images-runtime/README.md)

## DR & Bursting Flow (high level)
1. **Detect:** Federation alerts trigger a DR/burst evaluation.
2. **Decide:** Decision Service evaluates SLOs and credits, picks a target (Azure/GCP).
3. **Prepare:** Terraform attaches/expands the chosen cluster (AKS/GKE) and networking.
4. **Promote/Restore:** PostgreSQL promoted/restored via WAL-G; NetBox points to the active DB.
5. **Sync:** GitOps reconciles workloads in the target; DNS cutover finalizes traffic.
6. **Verify:** Grafana dashboards confirm RTO/RPO; evidence artifacts are exported.

## Secrets management {#secrets-management}
HybridOps.Studio treats secrets as code-governed and provider-integrated:

- **Kubernetes secrets workflow:** GitOps-compatible (Sealed Secrets or External Secrets) with decryption at deploy time.
- **Key management:** Cloud KMS (Azure Key Vault / GCP KMS) or on-prem HSM, per environment.
- **RBAC & lease-based access:** Least privilege for controllers; rotation via CI hooks or vault policies.
- **Auditability:** Secret changes tracked via Git history and GitOps events; runtime access logged.

**See also:** [Evidence Map](../evidence_map.md) → Observability / Decision Service topics for audit screenshots and CI logs.

## Security & Operations
- RBAC, secrets, and change management tracked in the **SecOps Roadmap** — see [SecOps Roadmap](../guides/secops-roadmap.md).
- All runs emit artifacts to `output/` for auditability; curated proofs live in the [Proof Archive](../proof/README.md).

## Diagrams
- High-level and sequence views are maintained under [Diagrams & Guides](../README.md). Mermaid fallbacks exist where helpful.

## Related
- Showcases: see the [Showcase Catalog](../../showcases/README.md) for focused demos and runbooks.

_Last updated: 2025-10-05_
