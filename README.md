# HybridOps.Studio — Hybrid Cloud Automation Portfolio

[![License: MIT-0](https://img.shields.io/badge/License-MIT--0-blue.svg)](https://opensource.org/licenses/MIT-0)
[![Terraform](https://img.shields.io/badge/terraform-1.5%2B-623CE4.svg)](https://terraform.io)
[![Ansible](https://img.shields.io/badge/ansible-2.12%2B-red.svg)](https://ansible.com)
[![Watch the Demo](https://img.shields.io/badge/Watch%20the%20Demo-YouTube-red?logo=youtube)](https://www.youtube.com/watch?v=YOUR_VIDEO_ID "Watch the HybridOps.Studio demo on YouTube")
[![Live Demo](https://img.shields.io/badge/Live%20Demo-scheduled%20sessions-2ea44f)](#live-demo)

**HybridOps.Studio** is a product-led blueprint for hybrid cloud operations: on‑prem control with Kubernetes + GitOps, and cloud failover/burst on Azure or GCP. It demonstrates enterprise‑grade automation patterns with reproducible runs and linked evidence.

---

## Highlights

- **Zero‑Touch Control Plane:** Provisions a Jenkins controller (`ctrl-01`) on Proxmox in ~10 minutes via cloud‑init Day‑0/Day‑1 automation — fully Git‑driven and evidence‑backed.  
- **Source of Truth:** NetBox‑driven inventory with Ansible dynamic discovery.  
- **GitOps Everywhere:** Argo CD / Flux manage desired state across clusters; Rancher optional for fleet access.  
- **Resilient Data:** PostgreSQL remains authoritative on‑prem; WAL‑G backups to cloud storage; fast promotion for DR.  
- **Networking Backbone:** Google Network Connectivity Center (NCC) as hub; on‑prem and cloud VNets/VPCs as spokes.  
- **Observability First:** Prometheus Federation across sites; shared Grafana views.  
- **Policy‑Driven DR/Burst:** Decision Service evaluates federation metrics plus Azure/GCP monitor signals and available credits.  
- **Operator Workflow:** No click‑ops — Make, Terraform, Ansible, and thin shell wrappers power everything.  
- **Evidence‑Backed:** Every claim maps to logs, outputs, screenshots, or dashboards.  

**Target KPIs:** RTO ≤ 15 m · RPO ≤ 5 m · Packer ≤ 12 m · Terraform ≤ 10 m · Autoscale +2 @ 70% (scale‑in < 40%).

---

## Cost & Telemetry (Evidence‑Backed)

Cost is a first‑class signal in HybridOps.Studio. Pipelines emit verifiable cost artifacts and enforce budget guardrails before burst/DR actions. The same artifacts power dashboards and reports.

- Guide: [Cost & Telemetry](./docs/guides/cost-model.md)  
- Evidence: [Proof Archive → cost](./docs/proof/cost/)  
- Policy hooks: [Decision Service](./control/tools/decision)

---

## Control Plane Context

The control plane (`ctrl-01`) is the foundation of HybridOps.Studio — it is the first proof of zero‑touch automation. The section below provides a deep dive into how it bootstraps itself, generates evidence, and drives the rest of the platform.

<details>
<summary><strong>Deep Dive: Zero‑Touch Control Plane (ctrl‑01)</strong></summary>

<p align="right"><sub><em>Click again to collapse this section</em></sub></p>

---

# HybridOps Studio — Control Plane (ctrl‑01) Strategy

### Purpose
Show a zero‑touch, production‑minded control plane that:
- boots from one Day‑0 script on Proxmox  
- self‑configures (Day‑1) entirely from Git  
- hands orchestration to Jenkins  
- executes workloads on ephemeral agents  
- produces durable evidence for every run  

---

### Elevator Pitch
> Buy a server, install Proxmox, run one script.  
> Ten minutes later you get a Jenkins control plane that builds infra on disposable agents and writes proofs into the repo.  
> Clean separation, easy DR, auditable.

---

### Architecture Summary
- **Jenkins Controller:** `ctrl-01` — a clean VM, not a container.  
- **Ephemeral Agents:** cloud‑init clones of a gold image, destroyed after jobs.  
- **Source of Truth:** Git repository defines Day‑0/Day‑1 state, pipelines, and evidence structure.  
- **Evidence Output:** stored under `docs/proof/ctrl01/<timestamp>/` with a `latest` symlink.

---

### Flow
```bash
Day-0 → Proxmox creates VM + injects cloud-init metadata
Day-1 → VM runs bootstrap.sh from Git (installs Jenkins, seeds jobs)
Day-2+ → Jenkins pipelines provision infra + collect evidence
```

---

### Evidence & Observability
| Artifact | Location |
|-----------|-----------|
| Bootstrap Log | `/var/log/ctrl01_bootstrap.log` |
| Evidence Folder | `docs/proof/ctrl01/<timestamp>/` |
| Latest Symlink | `docs/proof/ctrl01/latest` |
| Jenkins Init Scripts | `/var/lib/jenkins/init.groovy.d/` |

---

### Design Principles
- **Clean separation:** Controller orchestrates; agents execute.  
- **Ephemeral compute:** Agents are temporary; controller state is Git‑driven.  
- **Immutable evidence:** Every run emits verifiable outputs tied to a commit.  
- **Self‑healing:** Failures are rebuilt deterministically.  
- **Audit‑ready:** Jenkins emits proofs directly into the repo.

---

### DR Snapshot (Quick Recovery)
1. Snapshot or export the VM.  
2. Restore via Proxmox API or Terraform import.  
3. Resume pipelines; RPO validated via evidence timestamps.  

---

<p align="right"><sub>↑ Collapse to continue reading.</sub></p>
</details>

---

## Quickstart — Try It Yourself

<details>
<summary><strong>🟢 Run it yourself or try the live demo (click to expand)</strong></summary>

<p align="right"><sub><em>Click again to collapse this section</em></sub></p>

### Option 1 — Live Demo (recommended)

Prefer a walkthrough? [Watch the YouTube demo](https://www.youtube.com/watch?v=YOUR_VIDEO_ID)

You can SSH into a live demo environment and watch the control plane and its apps come online in real time.  
Jenkins pipelines automatically trigger RKE2, NetBox, and monitoring stacks — all visible as they build.

> Demo access is read-only. Sessions are announced for specific time windows.  
> One-time credentials expire automatically; destructive actions are not permitted.

```bash
ssh demo@hybridops.studio
# password: TryHybridOps!
```

To follow the build visually, use the Proxmox web viewer (read-only) to watch VMs boot, pipelines run, and dashboards populate:

https://demo.hybridops.studio/viewer

*Demo sessions are read-only and reset hourly to ensure a clean environment.*

---

### Option 2 — Run on your own Proxmox host

```bash
curl -fsSL https://raw.githubusercontent.com/jeleel-muibi/hybridops.studio/main/control/tools/provision/provision-ctrl01-proxmox-ubuntu.sh   -o /root/provision-ctrl01-proxmox-ubuntu.sh && chmod +x /root/provision-ctrl01-proxmox-ubuntu.sh && sudo JENKINS_ADMIN_PASS='<secret>' /root/provision-ctrl01-proxmox-ubuntu.sh
```

This Day-0 script:
- Builds the **ctrl-01** VM  
- Injects cloud-init payloads for Day-1 automation  
- Produces logs under `/var/log/ctrl01_provision.log`

See the full guide: [HOWTO: ctrl-01 Provisioner](./docs/howto/HOWTO_ctrl01_provisioner.md)

</details>

---

<sub>*If the demo server is under maintenance, follow the HOW-TO above to replicate the flow locally.*</sub>

## Architecture (executive view)

<p align="center">
  <img src="./docs/diagrams/flowcharts/renders/architecture-overview.png"
       alt="HybridOps.Studio — Executive Architecture"
       width="100%">
</p>

<details>
  <summary><strong>Mermaid fallback (compact, readable)</strong></summary>

> **Legend:** solid = control/data · dotted = IPsec/BGP, GitOps, config, backups

```mermaid
flowchart TB
  %% ===== On-Prem =====
  subgraph OnPrem["On-Prem"]
    direction TB
    Edges["EVE-NG Edges<br/>(B1/B2)"]
    RKE2["RKE2<br/>Control Plane"]
    Win["Windows AD / SCCM"]
    PG["PostgreSQL<br/>(Primary)"]
    Edges --> RKE2
    Win --> RKE2
  end

  %% ===== GCP Hub =====
  subgraph Hub["GCP Hub"]
    direction TB
    HAVPN["HA VPN"]
    CR["Cloud Router"]
    NCC["NCC (Hub)"]
    GKE["GKE"]
    HAVPN --> CR --> NCC --> GKE
  end

  %% ===== Azure Spoke =====
  subgraph Azure["Azure Spoke"]
    direction TB
    AZGW["VPN GW (BGP)"]
    AKS["AKS / VNet"]
    AVD["AVD"]
    AZGW --> AKS --> AVD
  end

  %% ===== Ops / Artifacts =====
  subgraph Ops["Observability / CI"]
    direction TB
    PFED["Prom Federation"]
    TF["Terraform"]
    ANS["Ansible / PowerShell"]
    PKR["Packer"]
  end

  subgraph Art["Images / Backups"]
    direction TB
    Blob["Azure Blob"]
    GCS["GCS"]
  end

  %% ---- Tunnels (dotted) ----
  Edges -. IPsec+BGP .-> HAVPN
  AZGW  -. inter-cloud BGP .-> CR

  %% ---- Control (solid) ----
  TF --> AKS
  TF --> GKE

  %% ---- GitOps / Config (dotted) ----
  RKE2 -. GitOps .-> AKS
  RKE2 -. GitOps .-> GKE
  ANS  -. WinRM .-> Win
  ANS  -. K8s mods .-> RKE2

  %% ---- Backups & Images (dotted) ----
  PG  -. WAL-G .-> Blob
  PG  -. WAL-G .-> GCS
  PKR --> Blob
  PKR --> GCS

  %% ---- Federation visibility ----
  PFED --- RKE2
  PFED --- AKS
  PFED --- GKE
```
</details>

**See more diagrams:** [Network Design](./docs/diagrams/network/README.md) · [Full Architecture (Mermaid)](./docs/diagrams/mermaid/architecture-overview.md)

---

## Evidence

- [**Evidence Map**](./docs/evidence_map.md) — claim → proof index
- [**Proof Archive**](./docs/proof/README.md) — curated screenshots and exports

<details>
<summary><strong>🔎 Evidence Map (click to expand)</strong> — claim → proof links</summary>

### KPIs
- **RTO ≤ 15m** — [Grafana DR panel](./docs/proof/observability/images) · [Runbook timings](./docs/proof/others/assets)
- **RPO ≤ 5m** — [SQL read-only promotion / log shipping](./docs/proof/sql-ro/images)
- **Image build ≤ 12m** — [CI logs: image builds](./docs/proof/images-runtime/images)
- **Terraform ≤ 10m** — [CI logs: plan/apply](./docs/proof/others/assets)
- **Autoscale +2@70%** — [Alert → scale event trace](./docs/proof/observability/images)

### Architecture assertions
- **Jenkins Control Plane (ctrl-01)** — [Provision & Evidence Bundle](./docs/proof/ctrl01/)
- **NCC hub-and-spoke** — [Topology & routes](./docs/proof/ncc/images)
- **Prometheus Federation** — [Targets & dashboards](./docs/proof/observability/images)
- **SQL RO in cloud for DR** — [Replica/RO dashboards](./docs/proof/sql-ro/images)
- **Runtime images to Blob/GCS** — [Artifact listings & screenshots](./docs/proof/images-runtime/images)
- **Decision Service (policy-governed)** — [Decision outputs & policy](./docs/proof/decision-service/images)
</details>

---

## Showcase Catalog

This section provides hands-on demonstrations of HybridOps.Studio capabilities. Each showcase includes documentation, runnable examples, and evidence of successful execution.

> **Quick Start:** Use `make showcase.avd-zerotouch-deployment.demo` to launch the AVD Zero-Touch showcase  
> Each showcase generates evidence and diagrams automatically. The [root Makefile](./Makefile) routes all showcase targets.

- [AVD Zero-Touch](./showcases/avd-zerotouch-deployment/README.md) - *Also available with advanced networking: `make showcase.avd-zerotouch-deployment.advanced-networking`*
- [CI/CD Pipeline](./showcases/ci-cd-pipeline/README.md)
- [DR Failover to Cloud](./showcases/dr-failover-to-cloud/README.md)
- [Migrate On-Prem to Cloud](./showcases/migrate-onprem-to-cloud/README.md)
- [Kubernetes Autoscaling](./showcases/kubernetes-autoscaling/README.md)
- [Linux Administration](./showcases/linux-administration/README.md)
- [Windows Administration](./showcases/windows-administration/README.md)
- [Network Automation (Programmatic, Nornir)](./showcases/network-automation/programmatic-nornir/README.md)
- [Network Automation (Declarative, Ansible)](./showcases/network-automation/declarative-ansible/README.md)
- [DR Failback to On-Prem](./showcases/dr-failback-to-onprem/README.md)
- [Scale Workload to Cloud](./showcases/scale-workload-to-cloud/README.md)
- **HPC groundwork (planned):** Slurm-based lab to demonstrate job scheduling and observability integration — see [ADR-0100](./docs/adr/ADR-0100-HPC-Extension-Strategy-for-HybridOps-Studio.md)
- [YouTube Assets](./showcases/youtube/README.md)

---

## Repository layout

- [**Control**](./control/README.md) — operator wrappers, provisioning scripts, and the decision service  
  - [control/tools/](./control/tools/) — repo utilities (index generators, provisioners)  
  - [control/decision/](./control/decision/README.md) — burst/DR policy, signals, and actions

- [**Packer**](./packer/README.md) — immutable base images (Linux, Windows, RKE2, Jenkins agents)  
  - `templates/`, `scripts/`, `vars/` — uploads to object storage or hypervisor templates

- [**Terraform**](./terraform/README.md) — modules and environment stacks (on-prem / Azure / GCP)  
  - `modules/`, `envs/` — remote state and policy gates

- [**Core**](./core/README.md) — reusable Ansible roles, shared libraries, and helpers

- [**Deployment**](./deployment/README.md) — inventories, playbooks, and GitOps overlays (k8s manifests)

- [**Docs**](./docs/README.md) — documentation hub  
  - [ADRs](./docs/adr/README.md) · [Runbooks](./docs/runbooks/README.md) · [HOWTOs](./docs/howto/README.md) · [Guides](./docs/guides/) · [Proof Archive](./docs/proof/README.md)

- [**Contrib**](./contrib/README.md) — helper references · [Scripts ↔ Playbooks](./contrib/scripts-playbooks.md)

- [**CI (docs)**](./docs/ci/README.md) — pipelines overview (Jenkins & GitHub Actions)

- [**Makefile**](./Makefile) — root build/ops targets

---

## Reuse these modules & roles

- **Ansible roles (Galaxy):** Versioned releases are published under my namespace.
  ```bash
  ansible-galaxy role install <namespace>.<role_name>
  ```

- **Terraform modules (Registry):** Provider‑specific modules with SemVer tags.
  ```hcl
  module "burst_cluster" {
    source  = "app/org/hybridops-burst-cluster/azure" # or gcp
    version = "~> 0.1"
  }
  ```

---

## Design Principles

- RKE2 on‑prem provides compliant, deterministic control; GitOps remediates drift.
- Google NCC enables hub‑and‑spoke connectivity across on‑prem and clouds.
- Prometheus Federation aggregates cross‑site metrics; the Decision Service combines these with Azure/GCP monitors and available credits to select the target for failover/burst.
- PostgreSQL remains authoritative on‑prem; cloud replicas/promotions are used for DR speed, with WAL‑G managing offsite backups and restores.
- Windows workloads (DC/SCCM/SQL) remain on‑prem unless explicitly included in DR scenarios.

---

## Operations

- Run procedures — **[Runbooks](./docs/runbooks/README.md)**
- Operator entry points — **[Control](./control/README.md)** (invokes canonical playbooks, Terraform, and GitOps)

<details>
  <summary><strong>Quick commands (optional)</strong></summary>

```bash
# Prep & sanity
make env.setup sanity

# On-prem bootstrap (baseline)
make control.orchestrate.onprem

# End-to-end DR flow (pick provider)
CLOUD_PROVIDER=azure make control.orchestrate.dr   # or: gcp

# Export Terraform outputs → CSV, then plan a NetBox sync (no writes)
make control.tf.csv
NETBOX_URL=https://netbox.local NETBOX_TOKEN=*** make control.netbox.plan
```

Direct wrappers (optional):
```bash
control/bin/rke2-server.sh
control/bin/rke2-agent.sh
control/bin/gitops-bootstrap.sh --dry-run
control/bin/dr-dns-cutover.sh azure
```
</details>

### Security at a glance
- RBAC & GitOps drift control — **[SecOps Roadmap](./docs/guides/secops-roadmap.md)**
- Secrets management — **[Technical Architecture › Secrets](./docs/briefings/technical_architecture.md#secrets-management)**
- Backup/DR (WAL-G, RPO/RTO) — **[Evidence Map](./docs/evidence_map.md)**

### Briefing Pack
- **[Executive Summary](./docs/briefings/executive_summary.md)** — high-level goals and value
- **[Project Overview](./docs/briefings/project_overview.md)** — repo structure & navigation
- **[Technical Architecture](./docs/briefings/technical_architecture.md)** — components & flows with proof links

---

## Community & Support

> This repository is a public, evidence‑backed portfolio intended for assessment.

- **Contribution policy:** External PRs are not accepted. For clarifications, please read the docs or use the channels in **Support**.
- **Contributing guidelines:** see [Contributing](./CONTRIBUTING.md)
- **Code of Conduct:** see [Code of Conduct](./.github/CODE_OF_CONDUCT.md)
- **Security Policy:** see [Security Policy](./.github/SECURITY.md)
- **Support:** see [Support](./.github/SUPPORT.md)

---

## Contact & Licensing

- **Engagements:** see **[Contracting](./CONTRACTING.md)** for services and contact details.
- **Code:** MIT‑0 — see **[License](./LICENSE)**.
- **Docs/diagrams:** CC‑BY‑4.0 — see **[Docs License](./docs/license-docs.md)**.
- Branding/wordmarks noted in **[Notice](./NOTICE)**.

<sub>© HybridOps.Studio — Designed by Jeleel Muibi · All product names/logos are trademarks of their respective owners.</sub>
