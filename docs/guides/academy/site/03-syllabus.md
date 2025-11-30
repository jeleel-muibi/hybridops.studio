
docs/docs-public/guides/academy/syllabus.md

# HybridOps Academy — HybridOps Architect Syllabus

This syllabus describes the flagship six-week HybridOps Architect programme.  
It is designed for practitioners who want end-to-end, evidence-backed hybrid-cloud operations experience across on-prem and public cloud.

The programme uses the HybridOps.Studio repository, runbooks, showcases, and proof folders as its practical foundation.

---

## Programme summary

- **Duration:** 6 weeks  
- **Format:** Cohort-based, with live sessions and guided labs  
- **Time commitment:** ~6–8 hours per week (live sessions + self-paced lab work)  
- **Delivery:**  
  - Live classes via video conferencing  
  - Course content via an online learning platform  
  - Documentation and runbooks via the HybridOps.Studio docs portal  
  - Hands-on work against the HybridOps.Studio codebase

The syllabus is organised by week. Each week links to specific parts of the repository, runbooks, and proof artefacts.

---

## Prerequisites

The programme is aimed at practitioners who already have basic familiarity with:

- Linux command line and SSH
- Git fundamentals (clone, commit, push, branch)
- At least one of: Terraform, Ansible, or a major public cloud

Helpful but not mandatory:

- Basic networking (IP addressing, routing, VLANs)
- Prior exposure to CI/CD concepts

Participants are expected to bring their own environment:

- Homelab (for example Proxmox and/or VMware), **or**
- Cloud accounts (for example Azure and GCP free tiers or credits), **or**
- A provided template, if offered for that cohort

An environment preparation checklist is provided during onboarding.

---

## Week 1 — Foundations and platform bootstrap

**Objectives**

- Understand the HybridOps.Studio architecture and evidence model.  
- Bootstrap a control node capable of running Terraform, Packer, Ansible, and CI/CD tooling.  
- Produce the first proof artefacts under the `docs/proof/` and `output/` trees.

**Topics**

- Repository layout and key directories (infra, core, deployment, docs, showcases, output).  
- On-prem focus: Proxmox and VMware as control and workload targets.  
- High-level view of Azure, GCP, and selected AWS usage.  
- Evidence-first design: proof folders, latest symlinks, and the Evidence Map.  
- Control node build: base OS, tools, access to Proxmox/VMware and clouds.

**Hands-on**

- Prepare a control VM (for example on Proxmox or VMware).  
- Install required tooling (Terraform, Terragrunt, Packer, Ansible, Python, Jenkins or CI runner).  
- Connect to at least one on-prem platform and one cloud provider.  
- Run initial validation scripts and capture logs / screenshots into a small proof bundle.

**End-of-week outcome**

- A functioning control node, tracked in version control.  
- An initial set of artefacts linked into the Evidence Map, confirming baseline connectivity.

---

## Week 2 — Infrastructure as Code: Proxmox, VMware, Azure, GCP

**Objectives**

- Use Terraform and Terragrunt to provision control, data, and DR plane workloads.  
- Understand environment separation and state handling for on-prem and cloud targets.

**Topics**

- Terraform module structure for Proxmox/VMware, Azure, and GCP.  
- Terragrunt layouts for dev/staging/prod and on-prem vs cloud.  
- State backends, remote state, and drift considerations.  
- Introducing selected AWS scenarios in a controlled way (for example specific network or DR patterns).

**Hands-on**

- Deploy a minimal topology in Proxmox or VMware (for example `ctrl01`, `db01`, and one workload).  
- Mirror selected components into Azure and/or GCP (for example a control plane VM and one workload VM).  
- Capture Terraform and Terragrunt logs into `output/terraform/` and link from the proof tree.

**End-of-week outcome**

- Reproducible IaC configurations for at least one on-prem and one cloud environment.  
- Clear mapping between Terragrunt structure and environment layout.

---

## Week 3 — Configuration management: Linux, Windows, network, and NetBox

**Objectives**

- Configure workloads using Ansible collections and roles.  
- Integrate NetBox as a source of truth for selected patterns.  
- Understand where configuration ends and image-based builds begin.

**Topics**

- Ansible collections layout (`hybridops.common` and related roles).  
- Linux configuration: users, SSH hardening, services, basic security.  
- Windows configuration: domain join, core services (for example SQL or application roles), updates.  
- Network device configuration using Ansible (and an introduction to Nornir for programmatic flows).  
- NetBox integration as a reference for inventory and topology metadata.

**Hands-on**

- Apply Linux and Windows roles to the previously provisioned workloads.  
- Run at least one NetBox-related role or playbook (for example seeding or aligning inventory).  
- Capture Ansible output into `output/artifacts/ansible-*` and link into the proof tree.

**End-of-week outcome**

- Configured workloads with repeatable Ansible runs.  
- At least one example of NetBox being used to enrich automation.

---

## Week 4 — Networking and connectivity

**Objectives**

- Design and validate resilient connectivity between on-prem and cloud environments.  
- Understand how network design underpins DR, burst, and observability.

**Topics**

- EVE-NG topologies and how they map to HybridOps.Studio scenarios.  
- Dual-ISP edge patterns, BGP/OSPF, and VRRP/CARP.  
- VPN and NCC-style multi-cloud connectivity.  
- Use of multi-vendor devices (for example Fortinet, pfSense, VyOS, CSR1000v, Nexus) in lab contexts.  
- Practical use of Wireshark or equivalent tooling for WAN analysis.

**Hands-on**

- Deploy or import at least one core EVE-NG topology that mirrors a HybridOps.Studio showcase.  
- Implement and validate connectivity between on-prem and at least one cloud environment.  
- Perform a failover or path change and capture traces (for example ping, traceroute, or packet captures) into the relevant proof folder.

**End-of-week outcome**

- A documented, tested connectivity pattern with evidence showing normal and failover behaviour.

---

## Week 5 — Observability, decision logic, and GitOps

**Objectives**

- Implement observability patterns that support scaling and DR decisions.  
- Connect metrics and alerts to infrastructure changes using CI/CD and GitOps.

**Topics**

- Prometheus federation across on-prem and cloud.  
- Dashboards focused on capacity, latency, and health for DR and burst decisions.  
- Decision service patterns that read metrics and trigger actions.  
- CI/CD tooling: Jenkins and GitHub Actions as orchestrators.  
- Introduction to GitOps workflows with Argo CD and/or Flux for Kubernetes and selected infra changes.

**Hands-on**

- Configure Prometheus (and optionally Grafana) to observe at least one critical path.  
- Implement a simple decision flow from thresholds → action (for example scale out a tier, adjust routing, or initiate a pre-DR step).  
- Use GitOps or pipeline-driven updates for at least one change, and capture logs into `output/decision/` or equivalent.

**End-of-week outcome**

- A working example of observability-driven change with supporting dashboards and logs.

---

## Week 6 — Disaster recovery drills and capstone

**Objectives**

- Design, execute, and document a full DR drill, including failback.  
- Package the work into a coherent artefact bundle suitable for review.

**Topics**

- DR patterns: failover to cloud and failback to on-prem.  
- Runbook design and severity categorisation.  
- RTO/RPO measurement and communication.  
- Structuring a capstone: scenario, diagrams, runbooks, logs, and proof evidence.

**Hands-on**

- Choose a scenario (for example application tier, database tier, or complete service).  
- Execute a DR drill using the relevant runbooks (bootstrap, burst, DR, ops, platform).  
- Perform failback where feasible.  
- Capture all logs, screenshots, decisions, and timings into a capstone proof folder, cross-linked from the Evidence Map.

**End-of-week outcome**

- A complete DR capstone with sufficient artefacts to be reviewed by a hiring manager, assessor, or internal stakeholder.

---

## Assessment and artefacts

Assessment is based on:

- Participation in live sessions (where applicable).  
- Completion of core labs and submission of selected artefacts.  
- A final capstone bundle with a concise written summary and linked evidence.

Examples of artefacts produced during the programme include:

- Terraform and Terragrunt logs for on-prem and cloud resource provisioning.  
- Ansible run outputs for Linux, Windows, network, and NetBox roles.  
- Network connectivity tests and traces for WAN and VPN scenarios.  
- Observability dashboards, decision logs, and CI/CD pipeline runs.  
- DR runbooks, timings, and screenshots of failover and failback.

Participants are encouraged to adapt their capstone for use in their own portfolio or internal documentation, subject to their organisation’s policies.

---

## Beyond the flagship programme

The HybridOps Architect bootcamp is intended as the core path. Additional specialist labs and certification-aligned tracks build on the same foundation and may be taken separately.

For planned labs and tracks, see the [Academy roadmap](./roadmap.md).
