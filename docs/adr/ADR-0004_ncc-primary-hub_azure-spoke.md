---
id: ADR-0004
title: "NCC as Primary Hub, Azure as Routed Spoke"
status: Accepted
date: 2025-10-05
domains: ["networking"]
owners: ["jeleel"]
supersedes: []
superseded_by: []
links:
  prs: []
  runbooks: []
  evidence: []
  diagrams: []
---

# NCC as Primary Hub, Azure as Routed Spoke

---

## Context
HybridOps.Studio must provide **deterministic, secure connectivity** across:
- **On‑prem** (Proxmox core + EVE‑NG sub‑sites B1/B2, RKE2 control/worker nodes, PostgreSQL primary),
- **Azure** (AKS, AVD),
- **GCP** (GKE, federation core).

Goals:
- Keep **routing simple and auditable**, support **DR/burst** selection by a Decision Service (Prometheus federation + cloud monitors + credits).
- Maintain a **single source of truth** (Terraform + NetBox), avoid hard‑coded IPs, and preserve **evidence‑backed KPIs** (RTO ≤ 15m, RPO ≤ 5m).
- Minimize **control‑plane overhead** for a portfolio project while remaining realistic and extensible.

Constraints:
- Windows admin and AVD live in Azure; observability/federation core is in GCP.
- Prefer **open, vendor‑neutral** primitives (IPsec, BGP) over proprietary overlays.

---

## Decision
Adopt **Google NCC as the primary hub**. All sites and clouds attach via **IPsec + BGP**:
- **On‑prem → GCP:** Route‑based **IPsec (VTI)** to **GCP HA VPN**, BGP to **Cloud Router**, attached into **Hub VPC → NCC**.
- **Azure → GCP:** **Azure VPN Gateway (BGP)** peers with **GCP Cloud Router** for inter‑cloud routing. Azure workloads (AKS/AVD) remain **routed spokes**.
- **Workloads:** On‑prem is steady‑state. DR/burst targets (AKS/GKE) are reconciled via **GitOps** after the Decision Service triggers Terraform.
- **Data:** PostgreSQL remains **authoritative on‑prem**; **WAL‑G** ships backups to cloud storage for RO/promotion in DR drills.

This is the **baseline topology** in the docs (see *Network Design*).

---

## Rationale
- **Operational simplicity:** One hub (NCC) → fewer control planes, fewer duplicated policies, faster troubleshooting.
- **Deterministic routing:** Clear BGP adjacencies and route‑maps; easy to prove reachability (and to collect evidence).
- **Fits portfolio scope:** Demonstrates multi‑cloud without the overhead of dual hubs; still extensible.
- **Cost alignment:** Avoids continuous dual‑hub spend; cloud bursting is event‑driven.
- **Observability first:** Federation core and Decision Service colocated with the hub keep signal quality high.

---

## Consequences
**Positive**
- Lower cognitive load; easier to demonstrate **evidence‑backed KPIs**.
- Faster change lead time and cleaner CI/CD integration (one hub toolchain).

**Negative / Risks**
- **Hairpin** potential when Azure‑local consumers talk Azure‑local services via the hub. Mitigation: targeted route‑maps; keep Azure‑local flows local when required.
- Single‑hub dependency: if hub is unreachable, cross‑site traffic is impaired. Mitigation: runbooks for **inter‑hub** enablement (see Appendix) and on‑prem isolation mode.

---

## Alternatives Considered
1. **Dual hubs (NCC + Azure vWAN/Hub VNet)** — More symmetry, but **higher operational overhead**, complex policy duplication, and longer change lead times. Kept as **documented alternative**.
2. **Azure as primary hub** — Tilts control to Azure; less aligned with GKE/federation placement and current credits.
3. **SD‑WAN overlay** — Adds cost and proprietary control planes; less instructive for a portfolio.
4. **Cloud‑only** — Fails the hybrid requirement; no on‑prem control.

---

## Implementation (high level)
- **Terraform** modules provision:
  - GCP: HA VPN, Cloud Router, Hub VPC, NCC hub & attachments (GKE spokes).
  - Azure: VPN Gateway (BGP), VNet, AKS; BGP to Cloud Router.
- **BGP policy:** Communities/local‑pref to prefer on‑prem steady‑state; DR/burst flips via Terraform variables.
- **GitOps:** ArgoCD/Flux to reconcile workloads on AKS/GKE; Rancher optional for fleet access.
- **Secrets & policy:** Sealed/External Secrets; admission/policy to gate changes.
- **Data path:** WAL‑G to Blob/GCS; promotion runbook for DR.

---

## Verification / Test Matrix
- **VPN/BGP:** Site‑A↔GCP, B1↔GCP, B2↔GCP up; Azure↔GCP inter‑cloud BGP up.
- **Routing:** Pod/Service CIDRs reachable cross‑site; Azure RO DB reachable (if enabled).
- **DR/burst flow:** Decision → Terraform attach/scale → GitOps sync → DNS cutover → **RTO ≤ 15m**.
- **Data:** Promotion achieves **RPO ≤ 5m**.
- **Observability:** Federation targets healthy; dashboards show end‑to‑end path.

---

## Links
- **Network Design (canonical):** `docs/diagrams/network/README.md`
- **Architecture Overview (Mermaid):** `docs/diagrams/mermaid/architecture-overview.md`
- **Evidence Map:** `docs/evidence_map.md` · **Proof Archive:** `docs/proof/README.md`
- **Runbooks:** `docs/runbooks/` (DR cutover, WAL‑G restore, SoT pivot)
- **Related ADRs:** ADR‑0003 (Secrets management choice), ADR‑0005 (GitOps policy gates) — _planned_
