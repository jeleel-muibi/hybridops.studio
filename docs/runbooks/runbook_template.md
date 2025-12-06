---
title: "<Short, action-oriented title>"
category: "bootstrap"        # bootstrap | dr | burst | ops | platform | networking | tooling.
summary: "1–2 sentences focused on the outcome this runbook delivers."
severity: "P2"               # P1 = critical, P2 = high, P3 = normal.

topic: "example-topic"       # Short handle, e.g. dr-failback, vpn-bringup, packer-templates.

draft: true                  # true => skip from generated runbook index.
is_template_doc: true               # keeps this file out of generated lists even if draft=false.
tags: ["template"]           # Optional labels, e.g. ["dr", "proxmox", "azure"].

# Access / commercial model:
# - public  : full runbook available in public docs and Academy.
# - mixed   : full runbook available in public docs and Academy; used for positioning/pricing only.
# - academy : public sees only a stub; Academy sees the full runbook when stub.enabled=true.
access: public               # One of: public | mixed | academy.

# Stub metadata.
# Only meaningful when access: academy AND stub.enabled: true.
# In that case:
# - Public docs show content above <!-- STUB_BREAK --> plus stub.blurb/highlights.
# - Academy docs see the full runbook body.
# For public/mixed, build tooling ignores STUB_BREAK and publishes the full runbook.
stub:
  enabled: false
  blurb: |
    This runbook is part of the HybridOps Academy teaching material.

    The full version typically includes:
    - A step-by-step operational procedure for this scenario.
    - Screenshots and timing notes for each major phase or cutover.
    - Evidence patterns for validating objectives (for example RTO/RPO, SLOs) and “latest” runs.
    - Common failure modes and recovery tactics used in the labs.

    Code and automation for this scenario remain open in the main repository.
    This document adds the guided, teaching-focused operational walkthrough used in the Academy.

  highlights:
    - "Example per-topic highlight describing what is unique about this runbook."
    - "Replace or remove these lines in real runbooks. Omit the key entirely if not needed."

  cta_url: "https://academy.hybridops.studio/courses/<course-key>/<runbook-key>"
  cta_label: "View full runbook on HybridOps Academy"

---

# <Short, action-oriented title>

**Purpose:** One sentence describing the operational outcome of this runbook.  
**Owner:** <team/role>  
**Trigger:** <alert/signal, scheduled drill, change request>  
**Impact:** <what is affected if this runbook is invoked>  
**Severity:** <P1 | P2 | P3>  
**Pre-reqs:** Accounts, contexts, VPNs, approvals, and environment assumptions.  
**Rollback strategy:** Where to find failback or reversal steps (for example separate runbook or section).

---

## Context

Briefly describe:

- When this runbook is used (incident, drill, maintenance, change window).  
- The high-level flow (for example failover → validate → DNS cutover → failback).  
- Scope boundaries (what this runbook does and does not cover).

---

## Preconditions and safety checks

List the checks that must pass before executing main steps:

- Correct environment (staging vs production).  
- Required services reachable (VPN, control plane, bastion).  
- Approvals or tickets in place.  
- Snapshots or backups taken where required (databases, configs).

---

## Steps

Each step should state what to do, how to do it, what “good” looks like, and where to capture evidence.

1) **<Step title>**  
   - Action: describe the action in one or two lines.  
   - Command or procedure:
     ```bash
     # replace with real commands
     some-cli --flag value
     ```
   - Expected result: describe the success condition.  
   - Evidence: where to save proof, for example  
     `output/artifacts/<area>/<YYYYMMDDThhmmssZ>_<name>.txt`.

2) **<Step title>**  
   - Action: …  
   - Command or procedure:
     ```bash
     # replace with real commands
     another-command --option
     ```
   - Expected result: …  
   - Evidence: …

(Add additional steps as required. Keep numbering and wording consistent.)

---

## Verification

Summarise how to confirm success once steps are complete:

- KPIs or objectives satisfied (for example RTO ≤ 15 minutes, RPO ≤ 5 minutes, SLO restored).  
- Dashboards or views to check (Grafana panels, NetBox status, Jenkins jobs).  
- Final evidence locations (`docs/proof/<topic>/`, `output/artifacts/<area>/`).

---

## Post-actions and clean-up

List follow-up work:

- Remove temporary overrides or feature flags.  
- Normalise routing, DNS, or traffic splits.  
- Rotate credentials used during the run, if appropriate.  
- Update tickets, incident timelines, or change records.

---

<!-- STUB_BREAK: content below may be academy-only when access: academy and stub.enabled=true -->

## References

Update this section to match the topic and use **markdown links**, not bare paths. Typical patterns:

- Related HOWTOs:  
  - [HOWTO – <descriptive name>](../howtos/HOWTO_<slug>.md)
- Related runbooks:  
  - [Runbook index by category](../runbooks/by-category/README.md)  
  - [Runbook – <descriptive name>](../runbooks/<category>/runbook-<slug>.md)
- Evidence map and proof folders:  
  - [Evidence Map](../evidence_map.md)  
  - [`docs/proof/<topic>/`](../../docs/proof/<topic>/)
- ADRs influencing this runbook:  
  - [ADR-XXXX – <short title>](../adr/ADR-XXXX-<slug>.md)
- Source code or automation:  
  - [GitHub – relevant module or script](https://github.com/<org>/<repo>/<path>)

Replace the placeholders above with the concrete paths for this runbook.

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation
