# HybridOps.Studio — Hybrid Cloud Automation Platform

[![License: MIT-0](https://img.shields.io/badge/License-MIT--0-blue.svg)](https://opensource.org/licenses/MIT-0)
[![Terraform](https://img.shields.io/badge/terraform-1.5%2B-623CE4.svg)](https://terraform.io)
[![Ansible](https://img.shields.io/badge/ansible-2.15%2B-red.svg)](https://ansible.com)
[![Packer](https://img.shields.io/badge/packer-1.9%2B-02A8EF.svg)](https://developer.hashicorp.com/packer)

**HybridOps.Studio** is a product-led blueprint for hybrid cloud operations:

- On-prem Proxmox as the core site, with SDN-backed segmentation and local control.
- Kubernetes clusters on-prem and in the cloud (AKS/GKE) driven by GitOps.
- Cost- and signal-aware DR, failback, and burst into Azure and GCP.
- NetBox as source of truth and Prometheus-first observability across sites.

This repository contains the **platform implementation** – image factory, Terraform/Terragrunt stacks, CI/CD glue, control tooling, and run outputs. Narrative documentation, ADRs, runbooks, and showcases live on the docs site at [docs.hybridops.studio](https://docs.hybridops.studio).

---

## Highlights

- **Hybrid multi-cloud and WAN aware:** On-prem Proxmox as the core site, with cloud landing zones on Azure and GCP. Design is ready for VPN/SD-WAN, hub-and-spoke, and services such as Google Network Connectivity Center (NCC).
- **Kubernetes and GitOps as the control surface:** Clusters on-prem and in the cloud are driven by GitOps (Argo CD or Flux). Rancher is optional as a fleet access layer, not a source of truth.
- **Observability and SLOs first:** Prometheus, Grafana, and Loki are ready to federate across environments so that SLOs, saturation, and error budgets can be evaluated across sites.
- **Cost- and signal-aware DR and burst:** Decision helpers combine metrics, health signals, and cost data before triggering failover, failback, or burst actions.
- **Zero-touch control plane:** Provisions a Jenkins controller (`ctrl-01`) and supporting services via Packer images, Terraform, and cloud-init—Git-driven and evidence-backed.
- **Image factory (Packer):** Golden images for Ubuntu, Rocky Linux, and Windows Server feed `ctrl-01`, worker nodes, and disposable agents.
- **Networking backbone:** Proxmox SDN on-prem, cloud networking on Azure and GCP, and explicit separation between core, edge, and observability VLANs.
- **Operator workflow:** No click-ops; `make`, Terraform, Ansible, and thin shell wrappers power flows end-to-end.
- **Evidence-backed:** Meaningful runs emit logs and artifacts under `output/`, with curated evidence referenced from the docs site.

---

## Example Scenarios

Representative scenarios this platform is designed to support:

- **DR drill – on-prem → cloud (cost-aware):**  
  A cloud-hosted Prometheus/Alertmanager stack detects loss of the on-prem control plane.  
  A serverless decision service evaluates health and cost signals, then triggers GitHub Actions via webhook to orchestrate failover of critical workloads to Azure or GCP. Evidence is recorded as Terraform state, CI logs, and decision JSON under `output/`.

- **Burst on saturation:**  
  While the on-prem site is healthy, Jenkins and the control tooling act as the primary scheduler.  
  When telemetry shows sustained saturation or cost thresholds being met, a cost-gated decision helper authorises a burst of additional capacity into AKS/GKE, using the same images, manifests, and GitOps flows, then gracefully scales back when demand drops.

- **WAN / multi-site lab:**  
  The same patterns are applied to model hub-and-spoke or mesh topologies using Proxmox SDN, VPN overlays, and cloud connectivity (for example GCP Network Connectivity Center).  
  This allows rehearsal of routing, failure modes, and observability flows in an enterprise-style WAN without exposing production assets.

These scenarios are documented end-to-end as showcases and operations runbooks on [docs.hybridops.studio](https://docs.hybridops.studio/showcases/readme).

**Target KPIs:** RTO ≤ 15 minutes · RPO ≤ 5 minutes · Packer runs ≤ 12 minutes · Terraform stacks ≤ 10 minutes · autoscale +2 at 70% (scale-in below 40%).

---

## Repository Layout (platform)

```text
.
├── control/        # Operator entry points and orchestration wrappers
├── core/           # Shared libraries (Jenkins, Python, PowerShell)
├── infra/          # Packer templates + Terraform/Terragrunt stacks
├── output/         # Logs and artifacts from platform runs
├── deployment/     # (Planned) GitOps overlays and K8s manifests
├── contrib/        # Helper references and contribution helpers
├── Makefile        # Top-level build / orchestration entry points
└── README.md       # This file
```

Key entry points:

- **Control layer:** `control/` — see `control/README.md` for operator workflows and how evidence is emitted under `output/`.
- **Packer factory:** `infra/packer-multi-os/` — golden image definitions and build tooling.
- **Terraform/Terragrunt:** `infra/terraform/` — live stacks and shared modules.
- **Outputs:** `output/logs/` and `output/artifacts/` — canonical evidence for runs.

Full narrative documentation, ADRs, runbooks, and showcases live in the **private docs repository**, rendered at:

- **Public site:** [docs.hybridops.studio](https://docs.hybridops.studio)

---

## Reusing Ansible Collections

HybridOps.Studio Ansible content is published as separate collections so this repository can focus on end-to-end platform wiring and evidence.

Collections are consumed from Ansible Galaxy in playbooks under `deployment/` and in examples on the docs site:

- `hybridops.app` – application and platform roles (for example Jenkins controller, RKE2 control plane, NetBox bootstrap, SQL Server, Windows administration).  
  - Source: [github.com/hybridops-studio/ansible-collection-app](https://github.com/hybridops-studio/ansible-collection-app)  
  - Galaxy: [galaxy.ansible.com/hybridops/app](https://galaxy.ansible.com/hybridops/app)

- `hybridops.common` – common utilities, inventory generation, environment guards, and shared plugins.  
  - Source: [github.com/hybridops-studio/ansible-collection-common](https://github.com/hybridops-studio/ansible-collection-common)  
  - Galaxy: [galaxy.ansible.com/hybridops/common](https://galaxy.ansible.com/hybridops/common)

- `hybridops.helper` – helper roles for evidence collection and NetBox integration.  
  - Source: [github.com/hybridops-studio/ansible-collection-helper](https://github.com/hybridops-studio/ansible-collection-helper)  
  - Galaxy: [galaxy.ansible.com/hybridops/helper](https://galaxy.ansible.com/hybridops/helper)

- `hybridops.network` – network automation roles (for example base configuration, backups, OSPF/BGP, VLANs, HSRP/VRRP, NTP).  
  - Source: [github.com/hybridops-studio/ansible-collection-network](https://github.com/hybridops-studio/ansible-collection-network)  
  - Galaxy: [galaxy.ansible.com/hybridops/network](https://galaxy.ansible.com/hybridops/network)

Typical usage pattern:

```bash
ansible-galaxy collection install hybridops.app
ansible-galaxy collection install hybridops.common
ansible-galaxy collection install hybridops.helper
ansible-galaxy collection install hybridops.network
```

Playbooks under `deployment/` then reference these collections using fully qualified names, for example `hybridops.app.jenkins_controller` or `hybridops.network.vlan`.

---

## Quick Start — On-prem foundation path

<details>
  <summary><strong>Show quick start workflow</strong></summary>

<br>

> Focus: the on-prem foundation (image factory, SDN, and control plane).  
> Cloud landing zones, DR drills, and burst scenarios follow the same patterns and are documented on the docs site.  
> Assumes access to Proxmox and cloud accounts; no credentials are distributed with this project.

### 1. Clone the hybridops-platform repository

```bash
git clone https://github.com/hybridops-studio/hybridops-platform.git
cd hybridops-platform
```

### 2. Install system prerequisites (workstation or CI agent)

From the repository root:

```bash
cd control/tools/setup

# Show available targets
make help

# Install base tooling (Terraform, Packer, kubectl, gh, etc.)
make base

# Optionally add Azure and GCP CLIs
make azure
make gcp
```

Local overview: [`control/tools/setup/README.md`](./control/tools/setup/README.md)  
Narrative guide: [Platform prerequisites and tooling](https://docs.hybridops.studio/guides/getting-started/10-prerequisites/)

### 3. Build image templates (Proxmox required)

```bash
cd infra/packer-multi-os

# Initialise Packer environment from shared .env
make init

# Build selected templates
make build-ubuntu-24.04
make build-rocky-9
make build-windows-server-2022
```

Build logs and proof bundles are written under:

- `output/logs/packer/`
- `output/artifacts/packer-builds/`

Further detail:

- [Packer Proxmox templates](https://docs.hybridops.studio/howtos/packer-proxmox-template/)
- [Proxmox VM template build runbook](https://docs.hybridops.studio/runbooks/platform/packer-proxmox-template-build/)

### 4. Bring up foundation networking (Proxmox SDN)

```bash
cd infra/terraform/live-v1/onprem/proxmox/core/00-foundation/network-sdn

# Review configuration
terragrunt plan

# Apply SDN and DHCP
terragrunt apply
```

Operational details and known SDN quirks (such as vnet interface persistence) are documented in:

- `infra/terraform/live-v1/onprem/proxmox/core/00-foundation/network-sdn/README.md`
- `infra/terraform/live-v1/onprem/proxmox/core/00-foundation/network-sdn/sdn_operations.md`
- [How-to: Proxmox SDN with Terraform](https://docs.hybridops.studio/howtos/network/proxmox-sdn-terraform/)

</details>

---

## Control Plane & Workflows

The **control plane** (`ctrl-01`) anchors HybridOps.Studio—auto-provisioned from Packer-built images, parameterised by Terraform via cloud-init, and orchestrated via Jenkins.

- Control-layer documentation: `control/README.md`
- Jenkins controller and JCasC helpers: `control/tools/jenkins/`
- Decision helpers (cost/DR/burst): `control/tools/decision/`

Typical flows:

- Provision or refresh `ctrl-01` via Terraform and Packer-built templates.
- Bootstrap Jenkins and seed pipelines from Git.
- Run image builds, SDN deployment, and cluster bootstrap from `make` targets.
- Emit logs and machine-readable artifacts under `output/` for each significant run.

High-level briefings and architecture diagrams live at:

- [Architecture briefings](https://docs.hybridops.studio/briefings/)
- [Architecture overview](https://docs.hybridops.studio/architecture/overview/)

---

## Outputs & Evidence

This repository treats `output/` as the **canonical evidence root** for platform runs.

```text
output/
├── artifacts/      # Machine-readable artifacts (JSON, CSV, reports, inventories, bundles)
│   ├── packer-builds/
│   ├── terraform/
│   ├── ansible-runs/
│   └── ...
└── logs/           # Raw logs (packer, terraform, ansible, decision helpers, etc.)
    ├── packer/
    ├── terraform/
    └── ansible/
```

These folders are:

- **Produced by** wrapper scripts under `control/` and by CI jobs.
- **Referenced from** the documentation site (e.g. evidence maps and showcases).
- **Versioned** so assessors can trace evidence back to specific commits and pipelines.

On the docs site, curated evidence is surfaced via pages such as:

- [Evidence overview](https://docs.hybridops.studio/evidence/overview/)
- [Platform run outputs](https://docs.hybridops.studio/evidence/platform-runs/)

---

## Documentation (docs.hybridops.studio)

All narrative material—ADRs, HOWTOs, runbooks, guides, and showcases—lives in a separate private documentation repository (`platform-docs`) rendered to:

- [docs.hybridops.studio](https://docs.hybridops.studio)

Typical navigation paths from this hybridops-platform repository include:

- **Getting started:**  
  - [Platform prerequisites](https://docs.hybridops.studio/getting-started/platform-prerequisites/)  
  - [Environment setup](https://docs.hybridops.studio/getting-started/environment-setup/)
- **Packer and images:**  
  - [Packer Proxmox templates](https://docs.hybridops.studio/howtos/packer-proxmox-template/)
- **Proxmox SDN and networking:**  
  - [Proxmox SDN with Terraform](https://docs.hybridops.studio/howtos/network/proxmox-sdn-terraform/)
- **Evidence and showcases:**  
  - [Evidence map and showcases](https://docs.hybridops.studio/evidence/map-and-showcases/)

The docs site is the right place for **Global Talent Visa** assessors, hiring managers, and learners; the hybridops-platform repository is the right place for engineers who want to run or inspect the automation.

---

## Design Principles

- **Separation of concerns:** platform automation (`hybridops-platform` repo) vs. documentation (`platform-docs` repo).
- **Git as source of truth:** infrastructure, control logic, and evidence structure live in version control.
- **Repeatability:** every environment can be rebuilt from images, IaC, and documented procedures.
- **Evidence-first:** meaningful runs emit logs and artifacts under `output/` that back up the claims on the docs site.
- **Security-aware:** secrets come from dedicated backends (e.g. AKV/SOPS); no shared credentials are published.

---

## Contributing & Usage

This repository is primarily a **portfolio and reference implementation**.

- External PRs may be reviewed but are not guaranteed to be merged.
- For clarifications or collaboration, see contact information on the docs site:
  - [Contact](https://docs.hybridops.studio/contact/)

Licensing:

- **Code:** MIT-0 (MIT No Attribution). See [`LICENSE`](./LICENSE).
- **Documentation and diagrams:** CC BY 4.0. See ["Documentation License (CC BY 4.0)"](./LICENSE#documentation-license-cc-by-40).
