# HybridOps.Studio

HybridOps.Studio is a hybrid-cloud operations blueprint for on-prem and public cloud.  
It is built to be inspected, reproduced, and extended – and to show clear evidence of how it works.

This site is the front door to the platform, documentation, Academy, and consulting services.

---

## What HybridOps.Studio is

HybridOps.Studio is a practical implementation of hybrid-cloud operations that combines:

- On-prem platforms such as Proxmox and VMware.
- Public clouds including Azure, GCP, and selected AWS scenarios.
- Immutable images built with Packer for Linux (Ubuntu, Rocky) and Windows.
- Terraform and Terragrunt for control, data, and DR plane provisioning.
- Ansible collections for Linux, Windows, network devices, and NetBox.
- CI/CD with Jenkins and GitHub Actions, with GitOps workflows (for example Argo CD) for Kubernetes and selected infrastructure changes.
- Observability and decision logic driven by Prometheus federation and a decision service.
- Multi-vendor networking (for example Fortinet, pfSense, VyOS, CSR1000v, Nexus) and dual-ISP, BGP/OSPF, VRRP/CARP, VPN patterns.
- Zero-touch and near zero-touch flows (for example AVD deployments and platform bootstrap) backed by runbooks and timestamped proof.

The same codebase underpins:

- A public, evidence-backed portfolio.
- A technical documentation portal.
- HybridOps Academy programmes.
- Consulting and advisory work.

---

## Who this is for

HybridOps.Studio is intended for:

- **Assessors and reviewers**  
  Who need to understand what has been built, how it behaves, and what evidence exists for it.

- **Hiring managers and technical leads**  
  Who want to see concrete examples of architecture, automation, disaster recovery, and operational discipline.

- **Practitioners (DevOps, SRE, Cloud, Network)**  
  Who want to learn hybrid-cloud operations by working against a real platform rather than isolated lab snippets.

- **Teams and organisations**  
  Who want to adapt proven patterns for their own homelab, pilot, or production environments, and may require tailored consulting.

Each of these audiences has a defined entry point in the documentation and Academy material.

---

## How the ecosystem fits together

HybridOps.Studio is deliberately structured as a small ecosystem rather than a single project.

### Platform

The core is the open repository:

- Infrastructure code, configuration management, and CI/CD definitions.
- Network topologies and connectivity patterns.
- Runbooks, ADRs, proof artefacts, and showcases.

It is kept public and evidence-driven so that decisions, trade-offs, and outcomes can be examined.

### Documentation

The documentation portal (for example `docs.hybridops.studio`) provides:

- Quickstart guides to bring up the platform.
- How-To guides and operational runbooks.
- Architecture Decisions (ADR library).
- Showcases, case-style walkthroughs, and the proof archive.
- Dedicated entry points for assessors, hiring managers, practitioners, and Academy participants.

Documentation is sourced from the same repository and follows an evidence-first model.

### HybridOps Academy

HybridOps Academy is the structured learning layer built on the platform:

- **HybridOps Architect** — a flagship, cohort-based programme focused on hybrid DR, IaC, configuration management, observability, and connectivity across on-prem and cloud.
- **Specialist labs** — shorter, intensive programmes (for example network automation and multi-vendor WAN, GitOps and Kubernetes SRE, polyglot IaC).
- **Certification-aligned tracks** — using the same environment to support exam-oriented practice (for example network fundamentals, Azure operations, Kubernetes application workflows).

Academy content reuses real runbooks, showcases, and proof folders, with additional lab notes and walkthroughs reserved for participants.

### Consulting and advisory

The same patterns used in the platform and Academy inform consulting work, which typically includes:

- Hybrid-cloud operations design and review.
- DR and failover/failback pattern design.
- Network automation and multi-vendor WAN validation.
- Platform bootstrap, cost-conscious homelab design, and evidence-first runbook development.

Consulting is scoped so that outputs are concrete (diagrams, runbooks, scripts, and validation evidence), not just slideware.

---

## Evidence-first operations

A central theme across HybridOps.Studio is that operations should be **provable**, not just declared.

The platform maintains:

- A structured proof tree (`docs/proof/`) covering image builds, DR drills, connectivity, observability, VPN, SQL read-only patterns, and other flows.
- Generated indexes and “latest” pointers to make review efficient.
- Runbooks categorised by purpose (bootstrap, burst, DR, ops, platform), with associated artefacts.

Assessors, hiring managers, and learners can see not only how flows are described, but also how they were run in practice.

For details, the documentation portal includes:

- An Evidence Map summarising all proof areas.  
- A proof archive overview explaining conventions and folder structure.  
- Runbook indexes and DR scenarios that link directly to underlying artefacts.

---

## Learning and progression

HybridOps.Studio is designed to support different ways of engaging with the material.

- **Self-guided exploration**  
  Use the public docs to follow Quickstart and How-To guides, inspect ADRs, and study runbooks and proof artefacts.

- **Structured learning via HybridOps Academy**  
  Join a cohort to work through the HybridOps Architect programme or later specialist labs, using the same repository with additional support and lab material.

- **Targeted upskilling and exam practice**  
  Use the platform as a realistic environment to reinforce skills relevant to networking, cloud administration, and Kubernetes-focused certifications.

The intention is to provide a path from initial exploration to deeper, structured practice and, where relevant, to supported preparation for more formal goals.

---

## Next steps

Depending on your role and interest:

- To read the technical documentation and see how the platform is organised, visit the documentation portal (for example `https://docs.hybridops.studio`).  
- To understand the Academy programmes, cohort format, and roadmap, review the HybridOps Academy pages in the docs and on the Academy site (for example `https://academy.hybridops.studio`).  
- To discuss consulting, tailored engagements, or integration of these patterns into your environment, use the contact options provided on this site.

HybridOps.Studio is intended to be a practical, inspectable example of hybrid-cloud operations, and a foundation for both learning and delivery.
