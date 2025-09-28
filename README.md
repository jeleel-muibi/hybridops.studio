# HybridOps.Studio — Architecture Overview

[![License: MIT-0](https://img.shields.io/badge/License-MIT--0-blue.svg)](https://opensource.org/licenses/MIT-0)
[![Ansible](https://img.shields.io/badge/ansible-2.9%2B-red.svg)](https://ansible.com)

**Summary**
**HybridOps.Studio is a product‑led hybrid blueprint spanning on‑prem Proxmox (with EVE‑NG sub‑sites) and Azure/GCP.**

> Looking for expert help with hybrid multicloud automation?
> See **[CONTRACTING.md](./CONTRACTING.md)** for services, packages, and contact details.

It delivers **DR ≤15 min**, cloud **read‑only DB**, and **burst‑to‑cloud Kubernetes** on demand.
A **policy‑governed Decision Service** chooses the failover/scale target in real time from telemetry, SLOs, and available credits, executed via **Terraform/Ansible/Packer** and **Jenkins/GitHub Actions** (observability: **Prometheus/Grafana**).

**Key Outcomes (KPIs)**
**RTO 15m · RPO 5m · Packer 12m · Terraform 10m · Autoscale +2@70% (scale‑in <40%)**

---

## Architecture Overview Diagram

![HybridOps Architecture Overview](docs/diagrams/flowcharts/renders/architecture-overview.png)

<details>
<summary><strong>🔎 Evidence Map (click to expand)</strong> — claim → proof links for KPIs & architecture</summary>

#### KPIs
- **RTO ≤ 15m** — [Grafana DR panel](#) · [Runbook step timings](#)
- **RPO ≤ 5m** — [SQL log shipping / AG graph](#)
- **Packer ≤ 12m** — [CI log: packer build](#)
- **Terraform ≤ 10m** — [CI log: terraform apply](#)
- **Autoscale +2@70% (scale-in <40%)** — [Alert → scale event trace](#)

#### Architecture Assertions
- **NCC hub-and-spoke** — [Topology / NCC routes](#)
- **Prometheus federation (on‑prem ↔ cloud)** — [Federation targets](#) · [Dashboards](#)
- **SQL WSFC → Azure RO** — [Replica status dashboard](#)
- **Packer → Blob / GCS (runtime images)** — [Artifact listings](#)
- **Decision Service (policy‑governed)** — [Repo section / policy file](#)

> Full, maintained list with screenshots and context: [`docs/EVIDENCE_MAP.md`](docs/evidence_map.md)
</details>

<details>
<summary><strong>Fallback: Mermaid source (GitHub‑friendly)</strong></summary>

```mermaid
flowchart LR
  subgraph OnPrem["On‑Prem (Site A) [HA]"]
    PVE["Proxmox Cluster [HA]"]
    PF["pfSense [HA]"]
    CSR["CSR1000v (IPsec)"]
    KCP["Kubernetes Control Plane x3 [HA]"]
    KW["Worker Nodes"]
    SCCM["SCCM Primary"]
    SQL["SQL Server (WSFC)"]
    NAS["Synology NAS"]
    PROM_ON["Prometheus"]
  end

  subgraph EVE["EVE‑NG Region"]
    subgraph B1["Sub‑site B1"]
      PF_B1["pfSense Edge (IPsec)"]
      RSW_B1["Routers & Switches"]
      KW_B1["K8s Workers"]
      SCCM_B1["SCCM Secondary"]
    end
    subgraph B2["Sub‑site B2"]
      PF_B2["pfSense Edge (IPsec)"]
      RSW_B2["Routers & Switches"]
      KW_B2["K8s Workers"]
      SCCM_B2["SCCM Secondary"]
    end
  end

  subgraph HUB["Hub & Observability"]
    NCC["Google NCC (Hub)"]
    PROM_CORE["Prometheus Federation Core"]
    GRAF["Grafana"]
    ALERT["Alerting/Webhooks"]
  end

  subgraph Azure["Azure (DR/Burst)"]
    CSR_AZ["CSR Spoke"]
    K8S_AZ["K8s Burst Workers"]
    DR_VM["Failover Compute [DR]"]
    RO_DB["Read‑Only DB Replica [RO]"]
    BLOB["Blob (Packer Images)"]
    PROM_AZ["Prometheus"]
    AZ_MON["Azure Monitor"]
  end

  subgraph GCP["GCP (Burst)"]
    K8S_GCP["K8s Burst Workers"]
    GCS["GCS (Packer Mirror)"]
    PROM_GCP["Prometheus"]
  end

  subgraph CICD["CI/CD & Images"]
    JENK["Jenkins"]
    GHA["GitHub Actions"]
    PACK["Packer"]
    TFC["Terraform Cloud"]
  end

  %% primary flows
  PVE --> KCP
  KCP --> KW
  KCP --> SQL
  SCCM --> KW
  PROM_ON --> PROM_CORE
  PROM_CORE --> GRAF
  GRAF --> ALERT
  TFC --> PVE
  JENK --> PACK
  GHA --> PACK
  PACK --> BLOB
  PACK --> GCS

  %% overlays (dashed)
  CSR -. "VPN IPsec" .-> NCC
  PF_B1 -. "VPN IPsec" .-> NCC
  PF_B2 -. "VPN IPsec" .-> NCC
  NCC -. "Spoke" .-> CSR_AZ
  PROM_ON -. "Federation" .-> PROM_AZ
  PROM_ON -. "Federation" .-> PROM_GCP
  KCP -. "Burst" .-> K8S_AZ
  KCP -. "Burst" .-> K8S_GCP
  SQL -. "Replication" .-> RO_DB
  AZ_MON -. "Autoscale Signal" .-> K8S_AZ
```
</details>

---

## What / Why / How (at a glance)
- **What**: Hybrid blueprint spanning on‑prem (Proxmox), emulated sub‑sites (EVE‑NG), and public clouds (Azure, GCP).
- **Why**: Resilience (DR), elasticity (burst), and speed (image + infra pipelines) with verifiable KPIs.
- **How**: IaC + CI/CD; hub‑and‑spoke VPN via **Google NCC**; federated observability with **Prometheus/Grafana**; **policy‑driven Decision Service** informed by **Prometheus federation** and cloud monitor signals.

---

## Evidence (click‑to‑verify)

| Ref | Claim it proves                                 | Direct link |
|-----|--------------------------------------------------|-------------|
| E1  | Product‑led blueprint (architecture/tests)       | https://github.com/jeleel-muibi/hybridops.studio#architecture |
| E2  | Impact (DR/burst metrics, federation)            | # (Grafana panel URL) |
| E3  | Recognition (public automation roles)            | https://galaxy.ansible.com/HybriOps |
| E4  | Demo (talk + live failover)                      | # (YouTube URL) |

> Each link lands directly on proof (screens, runs, graphs).

---

## What’s Inside (concise)
- **On‑Prem (Proxmox)**: pfSense HA; Cisco CSR; K8s control‑plane (x3) + workers [HA]; SQL Server **WSFC**; SCCM; Synology NAS; Prometheus; **EVE‑NG nested**.
- **EVE‑NG (Sub‑Sites)**: Two emulated sites with pfSense edges (IPsec), routers/switches, K8s workers (join Site‑A CP), SCCM Secondary.
- **Cloud (Azure/GCP)**: CSR spoke (Azure); **K8s burst workers**; **DR** failover compute; **RO** database replica; Packer images (Blob/GCS); Prometheus; Azure/GCP Monitoring (signals).
- **Automation & Observability**: Terraform Cloud (plans/state); Jenkins & GitHub Actions; Packer (Windows + control node images); Ansible; Prometheus **federation**; Grafana; alerting/webhooks.

---

## Deep Dives (for engineers)
- [Inventories — single source of truth](./inventories/README.md)
- [Network Automation (Programmatic, Nornir)](./showcases/network-automation/programmatic-nornir/README.md)
- [Network Automation (Declarative, Ansible)](./showcases/network-automation/declarative-ansible/README.md)
- [Windows Automation](./windowsAutomation/README.md)
- [Linux Automation](./linuxAutomation/README.md)
- [Terraform Infra](./terraform-infra/README.md)
- [Server Automation](./serverAutomation/README.md)
- [Containerization](./containerization/README.md)
- [Pipeline Diagram](./docs/egf_pipeline.md)
- [Main Topology](./docs/topology_main.png)
- [Network Design](./docs/network-design.md)
- [Runbook & Deployment](./deployments/README.md)
- [SecOps Roadmap (Planned Upgrades)](./docs/guides/secops-roadmap.md)

---

## Licensing

- **Code (IaC, scripts, tooling):** MIT No Attribution (MIT‑0) — see [LICENSE](./LICENSE).
- **Docs & Diagrams (`docs/`):** Creative Commons Attribution 4.0 — see [docs/LICENSE-DOCS.md](./docs/LICENSE-DOCS.md).
- **Branding / Trademarks:** The **HybridOps.Studio** name/wordmark and third‑party vendor logos are **not** licensed — see [NOTICE](./NOTICE).

**Brand & Ownership**
© HybridOps.Studio — Designed by Jeleel Muibi · https://hybridops.studio

_Logos are trademarks of their respective owners. Use does not imply endorsement._

_Last updated: 2025-09-24 12:00 UTC_
