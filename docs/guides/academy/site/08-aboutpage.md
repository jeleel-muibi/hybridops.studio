# About HybridOps.Studio

HybridOps.Studio is a hybrid-cloud operations blueprint and evidence-backed portfolio.  
It is designed to show, in concrete terms, how hybrid operations can be built, automated, and proved across on-prem and public cloud.

The project combines:

- A public codebase.  
- A documentation and proof portal.  
- Structured learning through HybridOps Academy.  
- Consulting and advisory work based on the same patterns.

---

## Purpose and scope

HybridOps.Studio exists to answer a simple question:

> What does a realistic, well-documented hybrid operations platform look like when it is built, exercised, and measured, rather than only described?

To answer that, the platform covers:

- On-prem infrastructure using Proxmox and VMware.  
- Public cloud usage across Azure, GCP, and selected AWS scenarios.  
- Immutable images built with Packer for Linux and Windows.  
- Infrastructure as Code with Terraform and Terragrunt.  
- Configuration management with Ansible (and Nornir for selected network flows).  
- CI/CD using Jenkins and GitHub Actions.  
- GitOps workflows (for example Argo CD) for Kubernetes and selected infrastructure changes.  
- Observability and decision logic using Prometheus federation and a decision service.  
- Multi-vendor networking topologies with dual-ISP, routing protocols, and VPNs.  
- Zero-touch and near zero-touch patterns backed by documented runbooks and proof artefacts.

Everything is wired to produce **evidence**, not just configuration.

---

## Design principles

HybridOps.Studio is built on a small set of principles:

### Evidence-first

Operations are only complete when they are:

- Documented with runbooks and assumptions.  
- Proven with logs, screenshots, and measurable outcomes.  
- Easy to revisit and re-run.

The `docs/proof/` and related folders capture this: each critical flow (for example image builds, DR drills, connectivity tests) has associated artefacts and “latest” pointers for efficient review.

### Cost-aware

Hybrid-cloud designs are always constrained by cost in real environments. The platform explicitly:

- Treats cost as a first-class design driver alongside resilience and maintainability.  
- Documents trade-offs in platform choices, deployment patterns, and DR options.  
- Targets homelab and small team budgets without discarding patterns that scale.

Dedicated documents describe how cost influences architecture, DR strategy, and runbooks.

### Automation over heroics

The platform favours:

- Repeatable automation (Terraform, Terragrunt, Ansible, CI/CD) over manual builds.  
- Standardised patterns (modules, roles, runbooks) over one-off scripts.  
- Git-based workflows and reviewable changes over ad hoc configuration.

Where manual steps are unavoidable, they are captured as explicit runbook entries.

### Vendor-aware, not vendor-locked

HybridOps.Studio uses specific tools and vendors, but the goal is to highlight **patterns**:

- On-prem can be Proxmox, VMware, or similar platforms.  
- Public cloud work can be adapted to other providers beyond Azure and GCP.  
- Network patterns are framed in terms of protocols and roles rather than specific models.

This makes it possible to reuse the ideas even when the exact tooling differs.

---

## Relationship to the public repository

The public repository is the core of the project. It contains:

- Source code for infrastructure, configuration, and automation.  
- Documentation, ADRs, runbooks, and proof trees.  
- Showcases that tie code, diagrams, and evidence together.

The documentation portal (`docs.hybridops.studio`) is built from this repository and provides curated entry points for different audiences.

HybridOps Academy and consulting services both rely on the same codebase and conventions, so there is no separate, private “demo” environment that differs from what is publicly visible.

---

## For assessors and hiring managers

HybridOps.Studio is intentionally structured so that it can be used as:

- A portfolio demonstrating architecture, automation, DR design, and operational discipline.  
- A source of concrete evidence for how systems behave under normal operation and during drills.  
- A reference for how complex topics (multi-cloud, DR, network automation, observability) are explained and documented.

The documentation portal includes:

- A dedicated route for assessors, outlining what to review and in what order.  
- A route for hiring managers, highlighting which parts of the platform speak to design ability, delivery, and maintainability.  
- Clear links from explanations to underlying code and evidence.

---

## For learners and teams

HybridOps.Studio also serves as a practical learning platform:

- Individuals can follow the public Quickstart, How-To guides, and runbooks to explore hybrid operations at their own pace.  
- HybridOps Academy offers structured programmes and labs for those who want guided, cohort-based learning.  
- Teams can adapt the patterns to their own environments and use consulting support where needed.

The intent is not to replace official certification routes, but to provide a realistic environment where skills can be exercised end-to-end.

---

## How to explore next

Depending on your role:

- If you want to see how the platform is built and what it can do, start with the documentation portal.  
- If you are interested in structured training, review the HybridOps Academy material.  
- If you are exploring whether the patterns are a fit for your organisation, review the consulting page and use the contact options provided.

HybridOps.Studio is intended to be long-lived, inspectable, and useful – as a platform, as a portfolio, and as a teaching and advisory foundation.
