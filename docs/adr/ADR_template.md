---
id: ADR-XXXX
title: "<Concise, action-oriented title — e.g., 'Adopt Rocky Linux 9 for RKE2 Base Image'>"
status: Proposed              # Proposed | Accepted | Deprecated | Superseded.
date: 2025-10-15              # ISO format; used by ADR index generators.
category: "<CC-name>"           # One of:
                                # "00-governance"
                                # "01-networking"
                                # "02-platform"
                                # "03-security"
                                # "04-observability"
                                # "05-data-storage"
                                # "06-cicd-automation"
                                # "07-disaster-recovery"
                                # "08-cost-optimisation"
                                # "09-compliance"

domains: ["networking"]       # Optional: free-form tags like "proxmox", "azure", "netops"
owners: ["HybridOps.Studio"]  # ADR maintainer(s) or owning team.
supersedes: []                # e.g. ["ADR-0007"].
superseded_by: []             # e.g. ["ADR-0021"].

links:
  prs: []                     # e.g. ["https://github.com/hybridops-studio/hybridops.studio/pull/42"]
  runbooks: ["../runbooks/..."]
  howtos: ["../howto/..."]
  evidence: ["../proof/..."]
  diagrams: ["../diagrams/..."]

draft: true                   # true => exclude from ADR index until ready.
is_template_doc: true                # keeps this file out of generated lists even if draft=false.
tags: ["template"]            # Optional labels, e.g. ["dr", "proxmox", "azure"].

# Access / commercial model:
# - public  : full ADR available in public docs and Academy.
# - mixed   : full ADR available in public docs and Academy; used for positioning/pricing only.
# - academy : public sees only a stub; Academy sees the full ADR when stub.enabled=true.
access: public                # One of: public | mixed | academy.

# Stub metadata.
# Only meaningful when access: academy AND stub.enabled: true.
# In that case:
# - Public docs show content above <!-- STUB_BREAK --> plus stub.blurb/highlights.
# - Academy docs see the full ADR body.
# For public/mixed, build tooling ignores STUB_BREAK and publishes the full ADR.
stub:
  enabled: false
  blurb: |
    This architectural decision record underpins one or more HybridOps Academy scenarios.

    The full version typically includes:
    - Detailed rationale for this decision, including trade-offs and rejected options.
    - Concrete mappings to runbooks, HOWTOs, and evidence folders that exercise this decision.
    - Notes on operational impact, failure modes, and how this decision is validated in drills.

    Code and automation remain open in the main repository.
    This ADR captures the structured reasoning used in the Academy material.

  highlights:
    - "Example per-topic highlight describing what is unique about this ADR."
    - "Replace or remove these lines in real ADRs. Omit the key entirely if not needed."

  cta_url: "https://academy.hybridops.studio/courses/<course-key>/adr-<id-or-topic>"
  cta_label: "View full ADR analysis on HybridOps Academy"

---

# <Concise, action-oriented title>

## Status
Proposed | Accepted | Deprecated | Superseded — <very short human summary of the decision and its impact>.

---

## 1. Context

Describe the background and problem space that led to this decision:

- What problem is being solved.  
- Constraints (technical, cost, skills, vendors, timelines).  
- Where in HybridOps.Studio this decision applies (modules, environments, flows).  

Keep this section factual and neutral.

---

## 2. Decision

State the decision clearly and narrowly:

- Which technology, pattern, or approach is adopted.  
- What configuration or topology is considered standard going forward.  
- Scope boundaries (what is in scope vs out of scope).  

This section should make sense in isolation.

---

## 3. Rationale

Explain why this decision was taken:

- Key drivers (reliability, observability, cost, simplicity).  
- How it aligns with HybridOps.Studio goals (evidence-first, homelab-friendly, DR-aware).  
- Trade-offs being accepted (for example more complexity vs better portability).  

Reference experiments, spikes, or prototypes where useful.

---

## 4. Consequences

### 4.1 Positive consequences

- Benefits for operations, reliability, cost, or developer experience.  
- How this decision simplifies or strengthens other parts of the platform.  
- Evidence that can be collected to demonstrate those benefits.

### 4.2 Negative consequences / risks

- New risks or constraints introduced.  
- Areas where complexity, coupling, or cost increases.  
- Migration or rollback effort if the decision is revisited later.  

Be explicit.

---

## 5. Alternatives considered

List the main alternatives and why they were not chosen, for example:

- Alternative A — rejected because of <reason>.  
- Alternative B — suitable for larger teams but not for current scale.  
- Alternative C — kept as a future option if constraints change.  

---

## 6. Implementation notes

Explain how this decision is implemented:

- Modules, roles, or scripts where this decision appears (`infra/`, `core/`, `deployment/`, etc.).  
- Configuration files or templates that embody the decision.  
- How this decision is validated in CI/CD or drills (pipelines, jobs).  

---

## 7. Operational impact and validation

Describe day-to-day impact and validation:

- Runbooks that exercise this decision.  
- Evidence folders or dashboards that demonstrate it working.  
- Metrics, SLOs, or targets influenced by this decision.  

---

<!-- STUB_BREAK: content below may be academy-only when access: academy and stub.enabled=true -->

## 8. References

Update this section using the `links` block and any additional sources.

Use **markdown links**, not bare paths. Typical patterns:

- Other ADRs, for example:  
  - [ADR-0001 – ADR Process and Conventions](../adr/ADR-0001-adr-process-and-conventions.md)  
  - [ADR-0601 – Nornir + Ansible Hybrid Automation](../adr/ADR-0601-nornir-ansible-hybrid-automation.md)
- Runbooks:  
  - [Runbook – <descriptive name>](../runbooks/<category>/runbook-<slug>.md)
- HOWTOs:  
  - [HOWTO – <descriptive name>](../howtos/HOWTO_<slug>.md)
- Evidence folders:  
  - [`docs/proof/<area>/`](../../docs/proof/<area>/)
- External documentation:  
  - [Vendor or standards documentation](https://example.com/docs)

Replace the placeholders above with the concrete paths for this decision.

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
