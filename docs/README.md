# HybridOps Studio — Documentation Index

This page orients readers to the core materials—ADRs (why), How-to guides (how), Runbooks (operate), diagrams (design), and evidence. Detailed procedures live in the How-to and Runbooks.

---

## Start here

- **How‑to: Provision the Control Node (Proxmox)** — Day‑0 → Day‑1 walkthrough with execution steps.  
  See: [How‑to: Provision ctrl‑01](./howto/HOWTO_ctrl01_provisioner.md)

- **Design Rationale** — why the control node is a full VM (cloud‑init), and how this supports DR and migration.  
  See: [ADR‑0012 — Control node as a VM](./adr/ADR-0012_control-node-as-vm.md)

- **Operations Runbook** — verification, optional Jenkins notes, troubleshooting, and re‑runs.  
  See: [Runbook — ctrl‑01 bootstrap](./runbooks/bootstrap/bootstrap-ctrl01-node.md)

> ℹ️ This index intentionally avoids inline shell commands and credentials. Use the How‑to for any execution.

---

## Selected artifacts

- **Briefings**
  - [Executive Summary](./briefings/executive_summary.md)
  - [Project Overview](./briefings/project_overview.md)
  - [Technical Architecture](./briefings/technical_architecture.md)

- **Diagrams**
  - [Architecture (rendered)](./diagrams/flowcharts/renders/architecture-overview.png)
  - [Architecture (Mermaid)](./diagrams/mermaid/architecture-overview.md)
  - [Network Design (canonical)](./diagrams/network/README.md)

- **Evidence & Proof**
  - [Evidence Map (claims → proofs)](./evidence_map.md)
  - [Proof Archive](./proof/README.md)

- **Runbooks**
  - [Runbook Index](./runbooks/README.md)
  - [ctrl‑01: Bootstrap & Verification](./runbooks/bootstrap/bootstrap-ctrl01-node.md)
  - DR — [Failover to Cloud](./runbooks/dr-failover-to-cloud.md) · [Failback to On‑Prem](./runbooks/dr-failback-to-onprem.md) · [DNS Cutover](./runbooks/ops-dns-cutover.md)
  - Bootstrap — [RKE2 Install](./runbooks/bootstrap-rke2-install.md) · [NetBox Seed](./runbooks/bootstrap-netbox.md)

- **ADRs**
  - [ADR Index](./adr/README.md)
  - Selected: [ADR‑0001 — ADR process](./adr/ADR-0001_adr-process-and-conventions.md) · [ADR‑0002 — NetBox SoT](./adr/ADR-0002_source-of-truth_netbox-driven-inventory.md) · [ADR‑0003 — Secrets via External Secrets + KMS](./adr/ADR-0003_secrets-management_k8s-external-secrets-kms.md) · [ADR‑0012 — Control node as a VM](./adr/ADR-0012_control-node-as-vm.md)

- **CI**
  - [CI Overview](./ci/README.md) · [GitHub Actions](./ci/github-actions.md) · [Jenkins CI](./ci/jenkins.md)

- **Guides & Roadmaps**
  - [SecOps Roadmap](./guides/secops-roadmap.md)
  - [Maintenance Guide](./maintenance.md)
  - [How‑to: Provision ctrl‑01](./howto/HOWTO_ctrl01_provisioner.md)

---

## Conventions

- This page is an **index of portfolio artifacts**.  
- Execution details: **How‑to** and **Runbooks**.  
- Design decisions: **ADRs**.  
- Evidence and proofs: **Evidence Map** and **Proof Archive**.

---

_Last updated: 2025-10-13 19:10 UTC_
