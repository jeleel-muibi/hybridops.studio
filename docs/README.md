# Documentation Index

> Start here to navigate briefings, diagrams, runbooks, CI, and evidence.

---

## How to read this
1. **Briefings** – short narratives (executive → technical) for quick context.
2. **Diagrams** – architecture views (draw.io renders and Mermaid fallbacks).
3. **Evidence Map** – one place that links claims → dashboards/logs/exports.
4. **Runbooks** – procedure playbooks for DR, burst, bootstrap, and operations.
5. **ADRs & Case Studies** – design decisions and focused walkthroughs.
6. **CI** – GitHub Actions and Jenkins jobs that lint, test, and render artifacts.

---

## Briefings
- **Executive Summary** — [read](./briefings/executive_summary.md)
- **Project Overview** — [read](./briefings/project_overview.md)
- **Technical Architecture** — [read](./briefings/technical_architecture.md)

---

## Diagrams
- **Architecture (rendered PNG)** — [view](./diagrams/flowcharts/renders/architecture-overview.png)
- **Architecture (Mermaid)** — [view](./diagrams/mermaid/architecture-overview.md)
- **Network Design (canonical)** — [view](./diagrams/network/README.md)

> Editing sources: draw.io files live under `diagrams/flowcharts/*.drawio`.

---

## Evidence & Proof
- **Evidence Map (claims → proofs)** — [open](./evidence_map.md)
- **Proof Archive (screenshots & exports)** — [open](./proof/README.md)

---

## Runbooks
- **Runbook index** — [open](./runbooks/README.md)
- DR: **Failover to Cloud** — [open](./runbooks/dr-failover-to-cloud.md)
- DR: **Failback to On‑Prem** — [open](./runbooks/dr-failback-to-onprem.md)
- DR: **DNS Cutover** — [open](./runbooks/ops-dns-cutover.md)
- Bootstrap: **RKE2 Install** — [open](./runbooks/bootstrap-rke2-install.md)
- Bootstrap: **NetBox Seed** — [open](./runbooks/bootstrap-netbox.md)
- Ops: **AVD Zero‑Touch** — [open](./runbooks/ops-avd-zero-touch.md)
- Ops: **VPN Bring‑Up** — [open](./runbooks/ops-vpn-bringup.md)
- Ops: **Postgres WAL‑G Restore/Promote** — [open](./runbooks/ops-postgres-walg-restore-promote.md)

> Use the template at `runbooks/templates/runbook_template.md` for new procedures.

---

## Continuous Integration (CI)
- **CI Overview** — [open](./ci/README.md)
- **GitHub Actions** — [open](./ci/github-actions.md)
- **Jenkins CI** — [open](./ci/jenkins.md)

---

## Architecture Decision Records (ADRs)
- **ADR Index** — [open](./adr/README.md)
- ADR‑0001 — ADR process & conventions — [read](./adr/ADR-0001_adr-process-and-conventions.md)
- ADR‑0002 — NetBox as Source of Truth — [read](./adr/ADR-0002_source-of-truth_netbox-driven-inventory.md)
- ADR‑0003 — Secrets via External Secrets + KMS — [read](./adr/ADR-0003_secrets-management_k8s-external-secrets-kms.md)
- ADR‑0004 — NCC primary hub; Azure routed spoke — [read](./adr/ADR-0004_ncc-primary-hub_azure-spoke.md)

---

## Guides & Roadmaps
- **SecOps Roadmap** — [open](./guides/secops-roadmap.md)
- **Maintenance Guide** — [open](./maintenance.md)

---

## Case Studies
- **Nornir: Brown‑field Switch Config (BSC)** — [read](./case-studies/bsc-nornir.md)

---

## Requirements (tooling)
- **Python/Ansible** — [view](./requirements/requirements.txt)
- **Ansible Collections** — [view](./requirements/requirements.yml)

---

## Maintenance & Ownership

- **[Maintenance Guide](./maintenance.md)** — files and dashboards to keep current as the portfolio evolves.
- **Licensing (docs):** **[CC‑BY‑4.0](./license-docs.md)**. Vendor marks are noted in `NOTICE` at the repository root.

---

### Pinned Quick Links

- **Run a DR drill:** follow **[DR Failover to Cloud](./runbooks/dr-failover-to-cloud.md)**.
- **Bootstrap GitOps:** see **[Bootstrap GitOps](./runbooks/bootstrap-gitops.md)**.
- **Secrets rotation:** see **[Secrets Rotation](./runbooks/ops-secrets-rotation.md)**.

---

_Last updated: 2025-10-08 (UTC)_
