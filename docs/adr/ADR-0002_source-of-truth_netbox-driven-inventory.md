---
id: ADR-0002
title: "Source of Truth: NetBox-Driven Inventory"
status: Accepted
date: 2025-10-05
domains: ["platform", "gitops"]
owners: ["jeleel"]
supersedes: []
superseded_by: []
links:
  prs: []
  runbooks: []
  evidence: []
  diagrams: []
---

# Source of Truth: NetBox-Driven Inventory

---

## Context
We need a single source of truth (SoT) for infrastructure objects (sites, devices, IPs, groups) that supports **Ansible**, **Terraform**, and documentation. The SoT must work on‑prem, support DR, and avoid secrets in Git.

## Decision
Use **NetBox** as the authoritative SoT:
- **Ansible**: consume inventory via NetBox dynamic inventory and/or GraphQL; no static hosts except **bootstrap**.
- **Terraform**: emits infrastructure outputs and (optionally) writes reference data back to NetBox via provider/API.
- **Bootstrapping**: a minimal `hosts.ini` is allowed **only** until NetBox is up, after which inventory comes from NetBox.
- **Docs**: diagrams and addressing are rendered from variables and NetBox, not hard-coded.

## Rationale
- Mature data model for networking and DC assets.
- First-class integrations (REST/GraphQL), easy to automate audits and drift checks.
- Clean separation between **definition** (NetBox) and **realization** (Terraform/Ansible).

## Consequences
- Requires initial NetBox bring-up early in the phase plan.
- We must follow data model conventions (roles, tags, site/tenant scoping).

## Verification
- `ansible-inventory --list` resolves hosts/groups from NetBox.
- Runbooks demonstrate **SoT pivot** from bootstrap to NetBox.

## Links
- Runbook: `docs/runbooks/sot_pivot.md`
- Evidence: `docs/proof/ncc/` (topology screenshots referencing NetBox data)
