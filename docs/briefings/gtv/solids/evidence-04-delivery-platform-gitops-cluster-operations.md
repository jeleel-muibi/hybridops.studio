# Evidence 4 – Delivery Platform, GitOps & Cluster Operations  
**HybridOps.Studio – Jenkins, RKE2, Cost-Aware DR & Cloud Bursting**

---

## Evidence Context

This document is **Evidence 4 of 5** for my UK Global Talent application (digital technology).

- **Evidence 1** focuses on the **on-prem hybrid network core** (VLAN design, Proxmox as L3 core, observability & validation).  
- **Evidence 2** focuses on **WAN edge, dual ISP, and hybrid connectivity** (pfSense, CSR/VyOS, Azure/GCP hubs).  
- **Evidence 3** focuses on **source of truth & automation** (NetBox, Terraform bridge, Nornir/NETCONF, Ansible).  

This fourth evidence shifts the lens to the **delivery platform and runtime**:

- A **Packer-driven image pipeline** that produces production-ready Proxmox templates.  
- A **Jenkins-centred CI layer** that bootstraps and manages RKE2 clusters and platform services.  
- A **Kubernetes/RKE2 runtime** where workloads (including NetBox) run on cluster nodes, while state is offloaded to a **PostgreSQL LXC**.  
- **Cost-aware DR & cloud bursting** orchestrated by GitHub Actions, driven by Prometheus federation and a **Cost Decision Service**.

It demonstrates that HybridOps.Studio is not just wired up and modelled, but delivered and operated as a **modern, hybrid, cost-aware platform**.

---

## 1. Executive Summary

HybridOps.Studio implements a **delivery and runtime platform** that turns Git changes into running workloads on a hybrid on-prem + cloud stack, with **cost and DR as first-class concerns**.

The key question this evidence answers is:
“Can this person design and operate a hybrid delivery platform – from images and CI/CD to Kubernetes and cost-aware DR – in an enterprise-grade way?”

Key elements:

- **Image pipeline via Packer** – A structured workspace builds Proxmox VM templates for Ubuntu, Rocky Linux, and Windows Server/Client, with cloud-init and sensible defaults baked in. Templates are reused for control nodes, RKE2 clusters, and supporting services.  
- **Jenkins controller + ephemeral agents** – Jenkins runs in Docker on the control node and drives Packer builds, Terraform, Ansible, and RKE2 bootstrap. Agents start as Docker containers on the control node and later move into **Jenkins agent pods** on RKE2.  
- **RKE2 as the runtime** – Modern workloads (platform services and applications) run on an RKE2 cluster. NetBox, initially deployed in Docker on the control node, is migrated into RKE2 as a Kubernetes workload.  
- **PostgreSQL in LXC** – State is centralised in a dedicated PostgreSQL LXC (`db-01`) on Proxmox, backed by host-mounted storage and WAL-G backups to cloud, per [ADR-0013](../../docs/adr/ADR-0013_postgresql-as-lxc.md). Applications treat Kubernetes as **stateless compute**, pointing to `db-01` for data.  
- **Cost-aware DR & cloud bursting** – Prometheus federation aggregates signals across the platform and triggers GitHub Actions via Alertmanager. Before bursting or failing over to cloud, a **Cost Decision Service** consumes cost artefacts and enforces **budget guardrails** as defined in the [Cost & Telemetry guide](../../docs/guides/cost-model.md).

This evidence demonstrates that I:

- Designed the overall delivery and runtime architecture (from image pipelines through to DR and cloud bursting).  
- Implemented the CI/CD and DR control loops myself using Jenkins, Terraform, Ansible, RKE2, Prometheus, and GitHub Actions.  
- Operate the platform with enterprise practices: ADRs, runbooks, cost guardrails, and repeatable DR drills.  
- Provide enough artefacts (logs, screenshots, runbooks, cost reports) that a second engineer could independently verify and reproduce the system.

---

## 2. Platform Architecture & Evolution

> **Diagram placeholder – High-level delivery platform (Proxmox, Jenkins, RKE2, PostgreSQL LXC, Prometheus federation, GitHub Actions DR loop)**

### 2.1 Phases of the Platform

HybridOps.Studio’s delivery platform is intentionally staged:

1. **Bootstrap Phase – Docker-Centric Control Node**

   - **Jenkins controller** runs as a Docker container on the Proxmox control node (`ctrl-01`).  
   - **Jenkins agents** run as ephemeral Docker containers on the same host.  
   - **NetBox** also runs as a Docker container, connected directly to the PostgreSQL LXC (`db-01`).  
   - Packer builds Proxmox templates for the control plane and worker nodes, described in [`infra/packer-multi-os`](../../infra/packer-multi-os/README.md) and [ADR-0016 – Packer + Cloud-Init VM Templates](../../docs/adr/ADR-0016-packer-cloudinit-vm-templates.md).

2. **Orchestration Phase – RKE2 Cluster Bring-Up**

   - Jenkins pipelines provision and configure an **RKE2 cluster** on Proxmox using Packer templates.  
   - Terraform/Ansible pipelines converge control and worker nodes into a usable cluster (CNI, certificates, basic policies).  
   - Core platform add-ons (ingress, metrics, logging, storage) are deployed into dedicated namespaces.

3. **Migration Phase – Agents and NetBox into RKE2**

   - **Jenkins agents** are migrated from Docker containers into **Kubernetes pods** within the RKE2 cluster, keeping Jenkins controller on `ctrl-01`.  
   - **NetBox** is redeployed as a Kubernetes workload (Helm chart / manifests) in a `platform` or `network` namespace. It continues to use PostgreSQL in `db-01` via DNS, honouring ADR-0013’s separation of state.  
   - Other platform services (e.g. External Secrets Operator, Longhorn) are introduced as add-ons managed by GitOps tooling.

4. **Steady-State Phase – Hybrid Runtime with DR Hooks**

   - On-prem Proxmox and RKE2 host most steady-state workloads.  
   - **PostgreSQL LXC** provides the central state layer, with continuous WAL-G backups and a read-only replica in cloud.  
   - Prometheus federation and Grafana monitor both the control plane (Jenkins, RKE2, NetBox) and workloads.  
   - DR and burst capacity are realised by starting cloud Kubernetes capacity and promoting the cloud PostgreSQL replica when needed.

This evolution path is captured in ADRs and HOWTOs so that the platform can be rebuilt or migrated in a controlled way.

---

### 2.2 Logical Components

At a high level, the delivery platform comprises:

- **Build & Control Layer**
  - Jenkins controller (Docker on `ctrl-01`).  
  - GitHub repositories (infrastructure, platform, applications).  
  - Packer, Terraform, Ansible, and cluster tooling (RKE2 CLIs, kubectl) installed on the control node.  

- **Runtime Layer**
  - Proxmox VE as the virtualisation layer for control nodes, workers, and LXC containers.  
  - RKE2 cluster (control + worker nodes) hosting:
    - Jenkins agents as pods.  
    - NetBox and other platform services (e.g. ingress, metrics, log stack).  
    - Application namespaces for demos and future workloads.  

- **State Layer**
  - PostgreSQL in a **dedicated LXC (`db-01`)** with host-mounted storage, per ADR-0013.  
  - Backups and DR replication to cloud object storage and cloud PostgreSQL read replica.  
  - Evidence artefacts stored under `docs/proof/` (including DB backup logs and DR rehearsal outputs).

- **Observation & DR Control Layer**
  - Prometheus federation, Alertmanager, and Grafana running in the observability VLAN and/or RKE2.  
  - A **GitHub Actions DR orchestrator** triggered via webhook from Alertmanager.  
  - A **Cost Decision Service** that reads machine-readable cost artefacts and decides whether bursting/failover is economically acceptable.

---

## 3. Demo Video (Walk-Through)

> **Diagram placeholder – Delivery Platform & DR Control Loop**

The primary demo video for this evidence shows:

- A Jenkins-driven Packer build and RKE2 cluster bootstrap.  
- NetBox being deployed and migrated from Docker on the control node to RKE2.  
- A simulated Jenkins outage and the Prometheus federation → GitHub Actions → DR workflow in action, including the Cost Decision Service gate.

Docs page (embedded video):  
[HybridOps.Studio – Delivery Platform & DR Demo](https://doc.hybridops.studio/evidence/delivery-platform-dr-demo/)

YouTube link:  
[HybridOps.Studio – Delivery Platform, GitOps & Cluster Operations](https://www.youtube.com/watch?v=YOUR_VIDEO_ID)

---

## 4. CI/CD & GitOps Flows

### 4.1 Image Pipeline – Packer Templates for Proxmox

The **image pipeline** creates standardised VM templates for Proxmox:

- Templates live under [`infra/packer-multi-os`](../../infra/packer-multi-os/README.md) and include:
  - `ubuntu-2204`, `ubuntu-2404`  
  - `rocky-9`, `rocky-10`  
  - Windows Server and Windows 11 variants  
- Each template:
  - Uses Packer with the Proxmox builder, wired to Proxmox via token (no stored passwords).  
  - Bakes in cloud-init, QEMU guest agent, and baseline hardening.  
  - Is tagged by environment and component via `PKR_VAR_*` variables for downstream cost accounting.

A Jenkins pipeline (`ci/packer-build`) runs:

1. `make validate` to ensure shared Packer config is consistent.  
2. `make build-<template>` to build templates for Ubuntu/Rocky/Windows.  
3. `evidence_packer.sh` to collect logs, metadata, and screenshots into [`docs/proof/platform/packer-builds/<date>/`](../../docs/proof/platform/packer-builds/).  
4. A post-build step to publish artefacts to the docs site and attach run IDs for traceability.

This pipeline feeds directly into Terraform and RKE2 provisioning pipelines.

Hands-on procedures for this pipeline are documented in:

- [HOWTO – Build Proxmox VM Templates with Packer](../../docs/howtos/HOWTO_packer_proxmox_template.md)  
- [HOWTO – Run the Packer Image Pipeline via Jenkins](../../docs/howtos/HOWTO_run_packer_image_pipeline_via_jenkins.md)

---

### 4.2 Infrastructure Pipeline – Terraform & Ansible

Infrastructure for the delivery platform is described declaratively:

- **Terraform/Terragrunt** modules define:
  - Proxmox resources (VMs, LXCs, networks).  
  - Cloud infrastructure for DR and burst (resource groups, VNets/VPCs, K8s clusters).  
  - Tags using the standard cost keys from the [Cost & Telemetry guide](../../docs/guides/cost-model.md).

- **Ansible** roles configure:
  - Proxmox nodes and LXC containers (e.g. `db-01`).  
  - Control node tooling (Packer, Terraform, Ansible, Jenkins dependencies).  
  - RKE2 node bootstrap (kernel parameters, container runtime, CNI support).  

Jenkins pipelines (e.g. `infra/provision-rke2`) sequence these steps:

1. Validate Terraform (`terraform fmt`, `terraform validate`, `terragrunt hclfmt`).  
2. Apply infra changes to the desired environment.  
3. Run Ansible plays to converge nodes.  
4. Emit evidence (plans, apply logs, Ansible summaries) into `docs/proof/infra/terraform/` and `docs/proof/infra/ansible/`.

---

### 4.3 Application Runtime Pipeline – NetBox on RKE2

NetBox is a representative platform application that demonstrates the full delivery pattern:

1. **Initial Docker deployment** on `ctrl-01`:
   - A Docker Compose stack deploys NetBox front-end containers, pointing to PostgreSQL in `db-01`.  
   - This is used during the bootstrap phase to validate networking and SoT flows.

2. **Migration to RKE2**:
   - Jenkins pipeline `apps/deploy-netbox`:
     - Builds or pulls NetBox images.  
     - Applies Helm charts or Kubernetes manifests in the `platform-netbox` namespace.  
     - Injects configuration via Kubernetes secrets (backed by External Secrets Operator and Azure Key Vault).  
     - Points NetBox to PostgreSQL in `db-01` via internal DNS (`db01.lab.local`) and service endpoints.

3. **Post-deploy validation**:
   - Pipeline runs connectivity checks (from a Jenkins agent pod) to:
     - `https://netbox.lab.local`  
     - NetBox health endpoint/API.  
     - PostgreSQL service on `db-01`.  
   - Captures `kubectl get pods`, `kubectl describe`, and NetBox health responses into `docs/proof/apps/netbox/<date>/`.

The same pipeline structure is reused for other applications, making NetBox a **pattern example** rather than a one-off.

---

### 4.4 GitOps & Add-ons

The platform is designed to support GitOps controllers (e.g. Argo CD) alongside Jenkins:

- Jenkins:
  - Builds images (Packer).  
  - Provisions infrastructure (Terraform/Ansible).  
  - Bootstraps the RKE2 cluster and installs core add-ons (Argo CD, External Secrets Operator, Longhorn).

- Argo CD (or similar GitOps tool):
  - Watches Git repositories containing Kubernetes manifests/Helm charts.  
  - Keeps RKE2 namespaces (platform, apps) in sync with Git.  
  - Provides drift detection and safe rollbacks for applications.

Add-ons such as **External Secrets Operator** and **Longhorn** are treated as platform capabilities, with their detailed design and configuration captured in ADRs and HOWTOs rather than bloating this evidence.

---

## 5. Cost-Aware DR & Cloud Bursting

> **Screenshot placeholder – Grafana view of Prometheus federation + DR alerts timeline**  
> **Screenshot placeholder – Cost dashboard showing DR run before/after**

### 5.1 Cost & Telemetry as First-Class Signals

HybridOps.Studio treats cost as a **first-class reliability signal**, not an afterthought:

- The [Cost & Telemetry guide](../../docs/guides/cost-model.md) defines:
  - Standard tags such as `cost:env`, `cost:owner`, `cost:component`, `cost:run_id`, `cost:purpose`.  
  - A requirement that Terraform, Packer, and CI pipelines emit **machine-readable cost artefacts** under `docs/proof/cost/`.  
  - Guardrails for DR/burst actions (e.g. expected hourly cost, maximum allowed duration).

- Pipelines are instrumented to:
  - Attach cost tags to cloud resources.  
  - Export run-time metrics and cost estimates to JSON/CSV/Markdown.  
  - Publish summary dashboards and reports.

This makes spend and DR decisions **auditable** and reproducible.

---

### 5.2 Prometheus-Driven DR Orchestration

Instead of manual DR runbooks only, the platform implements an **automated DR control loop**:

1. **Detection**  
   - Prometheus federation and Alertmanager provide a single, aggregated signal that can trigger DR workflows via GitHub Actions. They monitor:
     - Jenkins controller health (HTTP, job success rate, queue depth)  
     - RKE2 API health and node status  
     - Application SLOs (e.g. NetBox availability)  
   - When on-prem Jenkins is unavailable beyond an SLO, Alertmanager fires a `jenkins_critical_down` alert.

2. **Trigger**  
   - Alertmanager routes the alert to:
     - Human channels (Slack/Teams/email).  
     - A dedicated **webhook endpoint** that triggers a GitHub Actions workflow.

3. **Cost Decision Service**  
   - The GitHub Actions workflow invokes a **Cost Decision Service** that:
     - Reads recent cost artefacts under `docs/proof/cost/`.  
     - Calculates the projected incremental cost of:
       - Starting cloud Kubernetes capacity.  
       - Promoting cloud PostgreSQL read replica to primary.  
       - Running in DR mode for a specified duration.  
     - Compares projected cost against configured budget and purpose.

4. **Action**  
   - If the projected cost is acceptable (or approved by an operator), the workflow proceeds to:
     - Create or scale up a cloud Kubernetes cluster (e.g. AKS).  
     - Promote the **cloud PostgreSQL replica** to primary, per ADR-0013’s promotion strategy.  
     - Deploy Jenkins, NetBox, and critical apps using the same GitOps manifests.  
     - Update DNS and/or Azure Front Door backend pools to route traffic to the cloud entrypoint.

5. **Verification & Evidence**  
   - The workflow runs smoke tests (e.g. `kubectl`, HTTP probes) and commits results to `docs/proof/dr/<date>/` so that each DR drill or event is fully evidenced.

This loop demonstrates **autonomous, cost-aware DR**: the system can fail over or burst when needed, but only within **explicit financial guardrails**.

---

## 6. Key Design Decisions (ADRs)

Representative ADRs underpinning this evidence include:

- **[ADR-0013 – PostgreSQL Runs in LXC (State on Host-Mounted Storage; Backups First-Class)](../../docs/adr/ADR-0013_postgresql-as-lxc.md)**  
  Run PostgreSQL in a dedicated LXC (`db-01`) with host-mounted ZFS dataset and WAL-G backups to cloud. This keeps data durable and portable, while allowing Kubernetes and Jenkins to remain stateless.

- **ADR-0016 – Packer + Cloud-Init VM Templates**  
  Maintain a single, shared Packer workspace for Proxmox templates across OS families, with cloud-init and guest tooling baked in as a prerequisite for automated infra and RKE2 nodes.

- **ADR-00xx – Jenkins Controller in Docker, Agents in RKE2**  
  Keep the Jenkins controller anchored on the control node for resilience and simplicity, while running agents as ephemeral containers/pods close to workloads and infrastructure.

- **ADR-00xy – GitHub Actions as Stateless DR Orchestrator**  
  Use GitHub Actions as the external, stateless orchestrator for DR/burst workflows, triggered by Prometheus alerts and guarded by the Cost Decision Service.

- **ADR-00xz – Cost as First-Class Signal for DR & Burst**  
  Require cost artefacts for all significant infra/app changes, and gate DR/burst decisions on explicit budget checks.

- **ADR-00x? – GitOps Controller (Argo CD) for Application Delivery**  
  Delegate ongoing application sync and rollbacks to GitOps tooling, with Jenkins focusing on images, infra, and bootstrap.

Each ADR links to dedicated runbooks, how-tos, and diagrams for operator use.

---

## 7. Implementation Highlights (Representative Slices)

### 7.1 Jenkins Packer Pipeline (Excerpt)

A simplified Jenkins pipeline for Packer builds:

```groovy
pipeline {
  agent { label 'ctrl-docker' }
  stages {
    stage('Validate') {
      steps {
        sh 'cd infra/packer-multi-os && make validate'
      }
    }
    stage('Build ubuntu-2204') {
      steps {
        sh 'cd infra/packer-multi-os && make build-ubuntu-2204'
      }
    }
    stage('Collect Evidence') {
      steps {
        sh 'control/tools/provision/packer/evidence_packer.sh --mode build --log-file output/logs/packer/ubuntu-2204.log --env infra/packer-multi-os/shared/.env'
      }
    }
  }
}
```

In the evidence PDF, this appears as a short screenshot or snippet, with the full file linked under “Links & Artefacts”.

---

### 7.2 PostgreSQL LXC Storage & Networking (Excerpt)

From ADR-0013’s implementation:

```bash
# Host: Proxmox node
zfs create pool0/db01-data
mkdir -p /srv/db01-data

# LXC mount entry
mp0: /srv/db01-data,mp=/var/lib/postgresql/14/main,backup=1

# LXC config networking (excerpt)
net0: name=eth0,bridge=vmbr6,hwaddr=02:00:00:db:01:01,ip=10.6.0.10/24,gw=10.6.0.1
```

This highlights how data is anchored on the host, while the container remains lightweight and replaceable.

---

### 7.3 Prometheus Alert → GitHub Action (Conceptual YAML Excerpt)

```yaml
# Alertmanager route (excerpt)
route:
  receiver: 'dr-webhook'
  match:
    alertname: 'jenkins_critical_down'

receivers:
  - name: 'dr-webhook'
    webhook_configs:
      - url: 'https://dr.hybridops.studio/github-actions/webhook'
        send_resolved: true
```

```yaml
# GitHub Actions workflow (high-level excerpt)
on:
  repository_dispatch:
    types: [jenkins_critical_down]

jobs:
  cost_check_and_dr:
    runs-on: ubuntu-latest
    steps:
      - name: Fetch cost artefacts
        run: python control/tools/cost/read_cost_evidence.py --env prod

      - name: Evaluate cost
        run: python control/tools/cost/decision_service.py --mode dr-burst

      - name: Trigger DR (if approved)
        run: ./control/tools/dr/execute_dr_plan.sh
```

In practice the scripts are split out, but this illustrates the **cost-gated DR orchestration**.

---

## 8. Validation & Evidence

This section lists the concrete artefacts assessors can use to verify that the delivery platform works end-to-end in real life, not just on paper.

Representative validations:

- **Image Pipeline**
  - Successful `make build-*` runs for all templates, with logs and screenshots saved under `docs/proof/infra/packer/<date>/`.  
  - Proxmox UI showing templates with expected names, VMIDs, and cloud-init support.

- **RKE2 Provisioning**
  - `kubectl get nodes` showing expected control/worker nodes.  
  - `kubectl get pods -A` output demonstrating core add-ons running.  
  - Terraform and Ansible logs proving idempotent convergence.

- **NetBox Migration**
  - Screenshots of NetBox running first in Docker on `ctrl-01`, then as a Kubernetes workload (with pod logs and readiness checks).  
  - Database continuity verified via `SELECT` queries on `db-01` before and after migration.

- **Cost & DR Drills**
  - Runs of the DR workflow in “simulation mode” where:
    - Prometheus alerts are fired in a test channel.  
    - Cost Decision Service computes and logs projected spend.  
    - Terraform/Ansible/dr scripts run against a non-production environment.  
  - Artefacts stored under `docs/proof/dr/<date>/` and `docs/proof/cost/<date>/`.

These artefacts are captured as screenshots, logs, and markdown summaries in the repository and surfaced via the docs site.

---

## 9. Links & Artefacts

**Docs & Guides**

- [Packer VM Templates – README](../../infra/packer-multi-os/README.md)  
- [HOWTO – Build Proxmox VM Templates with Packer](../../docs/howtos/HOWTO_packer_proxmox_template.md)  
- [HOWTO – Run the Packer Image Pipeline via Jenkins](../../docs/howtos/HOWTO_run_packer_image_pipeline_via_jenkins.md)  
- [HOWTO – Deploy NetBox on RKE2 Using PostgreSQL LXC](../../docs/howtos/HOWTO_deploy_netbox_on_rke2_with_postgresql_lxc.md)  
- [HOWTO – Migrate NetBox from Docker on ctrl-01 to RKE2](../../docs/howtos/HOWTO_netbox_migration_docker_to_rke2.md)  
- [HOWTO – Run a Cost-Aware DR Drill (Prometheus → GitHub Actions → DR Workflow)](../../docs/howtos/HOWTO_dr_cost_drill.md)  
- [Cost & Telemetry — Evidence-Backed FinOps](../../docs/guides/cost-model.md)  

**Runbooks**

- [Runbook – Jenkins Controller Outage (ctrl-01)](../../docs/runbooks/dr/runbook_jenkins_controller_outage_ctrl01.md)  
- [Runbook – DR Cutover: On-Prem → Cloud](../../docs/runbooks/dr/runbook_dr_cutover_onprem_to_cloud.md)  
- [Runbook – DR Failback: Cloud → On-Prem](../../docs/runbooks/dr/runbook_dr_failback_cloud_to_onprem.md)  
- [Runbook – PostgreSQL LXC (db-01) Failure and Promotion](../../docs/runbooks/dr/runbook_db01_failover.md)  
- [Runbook – Cost Guardrail Breach (DR/Burst Blocked)](../../docs/runbooks/dr/runbook_cost_guardrail_breach.md)  

**ADRs**

- [ADR-0013 – PostgreSQL Runs in LXC (State on Host-Mounted Storage)](../../docs/adr/ADR-0013_postgresql-as-lxc.md)  
- [ADR-0016 – Packer + Cloud-Init VM Templates](../../docs/adr/ADR-0016-packer-cloudinit-vm-templates.md)  
- [ADR-0604 – Packer Image Pipeline for Proxmox Templates](../../docs/adr/ADR-0604-packer-image-pipeline-proxmox-templates.md)  
- ADRs for Jenkins in Docker, GitHub Actions DR orchestration, cost decision service, GitOps tooling, and K8s add-ons under `docs/adr/`.

**CI / Pipeline Docs**

- [CI – GitHub Actions Guardrails](../../docs/ci/github-actions.md)  
- [CI – Jenkins Orchestrator](../../docs/ci/jenkins.md)  
- [CI – Emit Cost Artefacts from Pipelines](../../docs/ci/CI_cost_artefacts_from_pipelines.md)  

**Proof & Evidence**

- [`docs/proof/platform/packer-builds/`](../../docs/proof/platform/packer-builds/) – Packer build logs and screenshots.  
- `docs/proof/infra/terraform/…` – Terraform plans and apply logs.  
- `docs/proof/infra/ansible/…` – Ansible run outputs.  
- `docs/proof/apps/netbox/…` – NetBox deployment and migration evidence.  
- `docs/proof/data/postgresql-lxc/…` – Backup logs and promotion tests for `db-01`.  
- `docs/proof/cost/…` – Cost artefacts used by the Cost Decision Service.  
- `docs/proof/dr/…` – DR drills and (if ever needed) real failover runs.

Together, these artefacts show that the delivery platform is **built, run, and evolved** like a real product: automated, observable, cost-aware, and ready to be adopted or adapted by other teams.

---

**Owner:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation
