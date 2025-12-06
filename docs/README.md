# HybridOps.Studio — Documentation Portal

HybridOps.Studio is an opinionated hybrid-cloud automation blueprint for Proxmox, Azure, and GCP.  
This portal explains what the platform does, how to run it, and how the evidence is organised.

The content here is backed by the main GitHub repository and the `docs/` and `output/` trees, so every major claim can be traced to concrete runs and artefacts.

---

## Who is this for?

Use this table as your “I am X → start here” router.

| I am a…                     | Start here                                                                 | What you will see                                                  |
|-----------------------------|----------------------------------------------------------------------------|--------------------------------------------------------------------|
| Global Talent Visa assessor | [Assessors — Start Here](briefings/gtv/how-to-review.md)                   | Ten-minute tour, criteria mapping, curated evidence links.         |
| Hiring manager              | [What This Demonstrates](guides/hiring-managers/what-this-demonstrates.md) | Skills, design thinking, trade-offs, and delivery patterns.        |
| Learner / practitioner      | [Series Roadmap](tutorials/series-roadmap.md)                             | YouTube and lab journey mapped to real code and artefacts.         |
| Engineer exploring the repo | [Quickstart: Bring Up HybridOps.Studio](guides/quickstart.md)             | Hands-on bootstrap in a homelab or cloud environment.              |
| Academy / bootcamp prospect | [HybridOps Academy Overview](guides/academy/overview.md)                  | Syllabus, outcomes, and enrolment paths.                           |

---

## What you will find here

This documentation portal is organised into a small set of recurring entry points.

| Area                   | Description                                                                                                  |
|------------------------|--------------------------------------------------------------------------------------------------------------|
| Quickstart             | Minimal path to get HybridOps.Studio running. See [Quickstart](guides/quickstart.md).                        |
| How-To Guides          | Task-oriented guides (images, provisioning, platform configuration, burst, DR). See [How-To Index](howto/000-INDEX.md). |
| Runbooks               | Reproducible operational procedures with categories and severities. See [Runbooks Index](runbooks/000-INDEX.md).       |
| Showcases              | End-to-end scenarios (CI/CD, DR, autoscaling, network automation, AVD). See [Showcases Overview](showcases/README.md).     |
| Architecture Decisions | ADR library explaining key design decisions and trade-offs. See [ADR Index](adr/000-INDEX.md).                         |
| Proof and Evidence     | Logs, artefacts, screenshots, and latest runs for key flows. See [Evidence Map](evidence_map.md).                     |
| Reference              | Repository and module maps, pipelines, and supporting libraries. See [Reference Map](guides/reference/repo-and-modules-map.md). |
| HybridOps Academy      | Bootcamp and consulting paths built on this codebase. See [Academy Overview](guides/academy/overview.md).                |

---

## Platform in one paragraph

HybridOps.Studio is a hybrid-cloud operations blueprint built around:

- Proxmox, Azure, and GCP as first-class targets for steady-state workloads, burst capacity, and disaster recovery.  
- Immutable images built with Packer for Linux (Ubuntu, Rocky) and Windows Server / Windows 11.  
- Terraform modules to provision control, data, and DR planes, and Ansible collections for Linux, Windows, network devices, and NetBox to configure and verify them end to end.  
- CI/CD implemented with Jenkins and GitHub Actions, with GitOps workflows (for example Argo CD) for Kubernetes and infrastructure changes.  
- Observability and decision logic using Prometheus federation and a decision service to drive autoscale, burst, failover, and failback.  
- Network topologies using dual-ISP designs, BGP/OSPF, VRRP/CARP, and tunnelling, with zero-touch and near zero-touch patterns (for example AVD deployments and platform bootstrap) backed by runbooks and timestamped evidence for each critical flow.

---

## Evidence-first design

The platform is built to show evidence, not just diagrams.

Start with:

- [Evidence Map](evidence_map.md) — high-level overview of proof areas and how they relate to the platform.  
- [Proof Archive](proof/README.md) — how `docs/proof/` is structured by theme (burst, DR, observability, networking, cost, platform builds).  
- [Runbooks Index](runbooks/000-INDEX.md) — generated table of operational procedures, grouped by category and severity.

Under the hood:

- Runbooks are categorised (for example bootstrap, burst, DR, ops, platform) with generated indexes and per-category views.  
- Proof folders mirror real operations (image builds, DR drills, NCC, observability, VPN, SQL read-only) with `latest` symlinks pointing to the most recent successful run.  
- The `output/` tree contains raw logs and artefacts referenced from proof and runbook pages.

If you are reviewing HybridOps.Studio, you should always be able to go from a documented behaviour to a runbook and then to concrete evidence.

---

## Cost and platform guardrails

Cost is treated as a first-class design driver, alongside security and maintainability.

- [Platform Cost Model](guides/cost-model.md)  
  How the platform is shaped around realistic homelab and small-team budgets, including cloud usage patterns.  

- [OS Baseline Rationale](guides/os_baseline_rationale.md)  
  Why particular operating systems and versions were chosen, and how they are maintained over time.  

- [SecOps Roadmap](guides/secops-roadmap.md)  
  Security posture, hardening steps, and how the platform evolves towards stricter controls.

These guardrails apply across on-prem, Azure, and GCP, and influence everything from DR strategy to how runbooks are written.

---

## Learning and HybridOps Academy

If you want to learn the platform rather than just read about it:

- [Series Roadmap](tutorials/series-roadmap.md)  
  How the YouTube series maps to specific parts of this repository and documentation.  

- [Lab Setup Guide](tutorials/lab-setup.md)  
  What you need to recreate a representative environment for the examples.

For structured, premium training and deeper engagement:

- [HybridOps Academy Overview](guides/academy/overview.md)  
  Positioning and audience.  

- [Bootcamp Syllabus](guides/academy/syllabus.md)  
  Week-by-week modules focused on hybrid automation, DR, and advanced networking.  

- [Pricing and Packages](guides/academy/pricing.md) and [Contact and Booking](guides/academy/contact.md)  
  How to enrol or arrange consulting engagements based on the platform.

---

## Project links

- Main site: https://hybridops.studio  
- Documentation: https://docs.hybridops.studio  
- Source code: https://github.com/hybridops-studio/hybridops.studio  
- Video series: link to the HybridOps.Studio YouTube channel
