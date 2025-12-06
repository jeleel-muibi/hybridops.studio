# Evidence Slot 1 – HybridOps.Studio Platform Overview & Trajectory (MC)

> **Criteria:** Mandatory Criterion (MC) – recognised as a potential leader in digital technology.  
> **Scope:** High-level overview of HybridOps.Studio as a hybrid platform blueprint and trajectory.  
> **Note:** Target length ~3 pages. `[IMG-XX]` placeholders will be replaced with final diagrams and screenshots.

---

## 1. HybridOps.Studio in One View

HybridOps.Studio is a **hybrid platform blueprint and reference implementation** that I design and operate to production standards as a platform/SRE product. It combines:

- A **hybrid on-prem + cloud network** with dual ISP and WAN edge design.  
- A **source of truth** model using NetBox and PostgreSQL.  
- A **delivery platform** built on Packer, Jenkins, RKE2 and GitOps.  
- A **disaster recovery and cost-aware automation layer** driven by Prometheus and GitHub Actions.  
- A full **documentation and academy engine** that turns the platform into reusable teaching and consulting material.

The goal is to demonstrate the level of ownership and design I can bring to a modern infrastructure/platform team: not just running servers, but designing the **architecture, automation, observability, DR, cost guardrails and documentation** as a reusable, organisation-ready blueprint.

[IMG-01 – Overall HybridOps.Studio platform diagram – ~8 lines]  
*(Architecture diagram showing: on-prem Proxmox & pfSense; RKE2 cluster; db-01 PostgreSQL LXC; Prometheus; Jenkins; GitHub Actions; cloud DR/burst; docs & academy.)*

---

## 2. Core Architecture – From Network to DR & Docs

### 2.1 Hybrid network & WAN edge

I designed a **dual‑ISP, IPsec‑based hybrid network** as the foundation of HybridOps.Studio:

- pfSense firewalls with dual ISP connections.  
- Site‑to‑site IPsec tunnels to cloud providers.  
- Segmented VLANs for management, workloads, and observability.  

This is captured in my networking evidence packs and ADRs (for example, ADR‑01xx series) and provides the **connectivity and security baseline** for everything else.

### 2.2 Source of truth & automation

On top of the network, I built a **source of truth model** using NetBox and PostgreSQL:

- NetBox stores sites, racks, devices, IPs and services.  
- A dedicated PostgreSQL LXC (`db‑01`) holds state, separate from RKE2 worker nodes.  
- Automation tooling (Terraform, Ansible, Nornir) pulls data from NetBox and applies changes to the network and infrastructure.

This SoT approach makes it possible to treat infrastructure changes as **data‑driven**, not just ad‑hoc playbooks.

### 2.3 Delivery platform – images, CI/CD & GitOps

To standardise compute, I built a **Packer image pipeline** for Proxmox templates:

- Unified workspace under `infra/packer-multi-os/` for Ubuntu, Rocky Linux and Windows images.  
- Cloud‑init‑ready templates with consistent VMIDs and configuration.  

CI/CD then glues this together:

- **Jenkins** runs on a control node (`ctrl‑01`) in Docker.  
- Agents start locally at first, then move into the RKE2 cluster as it is provisioned.  
- Pipelines orchestrate:
  - Packer image builds.  
  - Terraform plans and applies.  
  - Ansible configurations.  
  - GitOps operations (with Argo CD) for workloads.

This gives HybridOps.Studio a realistic **delivery pipeline** of the kind typically owned by an internal platform/SRE team in an enterprise environment.

### 2.4 DR & cost‑aware automation

A major focus of HybridOps.Studio is to treat **disaster recovery (DR) and cost** as first‑class concerns:

- Prometheus federation and Alertmanager detect critical failures (for example, Jenkins or RKE2 control plane issues).  
- Alertmanager webhooks trigger a **GitHub Actions DR workflow**, which can:
  - Bring up DR infrastructure in cloud.  
  - Re‑point workloads to cloud endpoints.  
- A **Cost Decision Service**, informed by cost artefacts from CI pipelines, decides whether DR/bursting is financially acceptable before actions are taken.

DR drills and cost artefacts are stored under:

- `docs/proof/dr/...`  
- `docs/proof/cost/...`

which allows me and others to audit DR behaviour and cost impact over time.

### 2.5 Docs engine & academy

Finally, HybridOps.Studio includes a **documentation and academy engine**:

- MkDocs builds two sites:
  - A **public** documentation view.  
  - An **academy** view for deeper labs and showcases.  
- Documentation is structured into:
  - ADRs (`docs/adr/`)  
  - HOWTOs (`docs/howtos/`)  
  - Runbooks (`docs/runbooks/`)  
  - CI docs (`docs/ci/`)  
  - Case studies (`docs/cases/`)  
  - Academy showcases (`deployment/academy/showcases/...`)

This lets me package the platform as **teaching material**, not just internal notes.

---

## 3. Evidence of Structure & Governance

A key part of this evidence is not just the platform itself, but the **governance and documentation discipline** around it.

[IMG-02 – ADR index or ADR filesystem tree screenshot – ~6 lines]  
*(Shows ADR_0001 conventions and category codes for networking, platform, CI/CD, DR, cost, etc.)*

[IMG-03 – HOWTO / runbook index screenshot – ~6 lines]  
*(Shows catalogues of HOWTOs and runbooks generated by the docs tooling.)*

### 3.1 ADRs – architectural decisions

HybridOps.Studio uses formal **Architectural Decision Records (ADRs)**, including:

- ADR‑0001 – ADR Process & Conventions (defines ID ranges and categories).  
- ADRs for:
  - Packer + cloud‑init templates.  
  - Packer image pipeline for Proxmox templates.  
  - Jenkins controller and agents.  
  - RKE2 runtime and add‑ons.  
  - DR signal plane (Prometheus federation).  
  - GitHub Actions as stateless DR orchestrator.  
  - Cost as a first‑class DR/bursting signal.

Each ADR links to related HOWTOs, runbooks, and proof folders.

### 3.2 HOWTOs & runbooks

Every major operation has both:

- A **HOWTO** (learning/teaching view), and  
- A **runbook** (operational view).

Examples:

- HOWTO: Run a cost‑aware DR drill (Prometheus → GitHub Actions → DR workflow).  
- Runbooks:
  - Jenkins controller outage.  
  - DR cutover on‑prem → cloud.  
  - DR failback cloud → on‑prem.  
  - db‑01 (PostgreSQL LXC) failover.  
  - Cost guardrail breach (DR/burst blocked).

This shows that I don’t just build systems; I design the **operational muscle memory** around them.

### 3.3 CI documentation

CI/CD itself is documented with dedicated CI briefs, for example:

- GitHub Actions guardrail pipelines:
  - Linting, validation, rendering and dry‑runs.  
- Jenkins orchestrator pipelines:
  - Controlled `plan → approve → apply` flows.  
  - Evidence generation into `docs/proof/...`.  
- Cost artefact emission from pipelines:
  - JSON artefacts under `docs/proof/cost/<component>/cost-run-<run_id>.json`.

This reinforces that the platform is treated as a **product with lifecycle**, not a loose collection of scripts.

---

## 4. Public Footprint & Trajectory

This evidence also speaks to my **trajectory** as a potential leader in digital technology.

### 4.1 Academic foundation and early work

- First‑class BSc in Computer Science.  
- Department award for outstanding engagement.  
- Final‑year project on network automation and abstraction, ranked among the top projects in my cohort.  

HybridOps.Studio is the **evolved continuation** of that early network automation work, now extended into hybrid infra, DR and teaching.

[IMG-04 – Small combined panel of degree/award/FYP repo screenshot – ~8 lines]

### 4.2 Public repo and docs (planned surface)

HybridOps.Studio is being prepared for a **public‑facing surface**:

- Sanitised GitHub repository with:
  - ADRs, HOWTOs, runbooks, CI docs.  
  - Selected automation and infra code (with secrets removed).  
- Public MkDocs site:
  - High‑level overview for hiring managers and assessors.  
  - Deeper academy sections for learners.

[IMG-05 – Screenshot/placeholder of public docs home page – ~6 lines]

### 4.3 Teaching & community roadmap

On top of the platform, I am building:

- **HybridOps Academy** showcases (e.g. CI/CD pipeline demo, DR drill lab).  
- Public teaching content:
  - Short videos walking through key scenarios (DR drill, NetBox → automation).  
  - Posts that explain architectural decisions and patterns.

[VID-01 – Thumbnail + link: “Tour of HybridOps.Studio” – ~4–6 lines]  
[VID-02 – Thumbnail + link: “Cost-Aware DR Drill Walkthrough” – ~4–6 lines]

These are designed so that assessors and future collaborators can **see and reuse** the work, not just read about it.

---

## 5. Why This Meets Mandatory Criteria for Exceptional Promise

Taken together, HybridOps.Studio shows that I:

- Own an **end‑to‑end platform design**, from networking, templates and CI/CD to DR, cost and docs.  
- Apply **engineering discipline** (ADRs, runbooks, CI briefs, proof artefacts) typically expected from internal platform/SRE teams.  
- Am building a **public and educational surface** (docs engine, academy, videos) that others can learn from.  
- Have a track record from university to now of investing in **network automation, abstraction and hybrid infrastructure** as a long‑term theme.

This evidence pack will be supported by:

- Recommendation letters from senior professionals who can speak to both the technical depth and the leadership potential shown by this project.  
- Links to the public repo and documentation that allow independent verification and reuse.

[IMG-06 – Optional: small collage of ADR/Howto/Runbook/docs screenshots – ~6 lines]

---

**Context & navigation**

For easier cross-referencing, this PDF is mirrored on the [HybridOps.Studio documentation portal](https://docs.hybridops.studio) and linked from the [Tech Nation assessors’ guide](https://docs.hybridops.studio/briefings/gtv/how-to-review/). The docs site adds navigation only, not new evidence.
