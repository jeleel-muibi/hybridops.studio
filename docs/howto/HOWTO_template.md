---
title: "HOWTO Template"
category: "bootstrap"        # Logical bucket, e.g. bootstrap | dr | burst | ops | platform | networking | tooling.
summary: "Template for authoring new HOWTO guides (excluded from index)."
difficulty: "Intermediate"   # Beginner | Intermediate | Advanced.

topic: "example-topic"       # Short handle, e.g. netbox-bootstrap, docker-baseline, vpn-bringup.

# Demo / source metadata.
# Always populate when available; build tooling decides how to expose them.
video: ""                    # Optional public demo URL, e.g. https://youtu.be/VIDEO_ID.
source: ""                   # Optional GitHub or script reference for this HOWTO.

draft: true                  # true => skip from generated HOWTO index.
is_template_doc: true               # true => always skipped, even if draft=false.
tags: ["template"]           # Optional labels, e.g. ["packer", "proxmox"].

# Access / commercial model:
# - public  : full HOWTO available in public docs and Academy.
# - mixed   : full HOWTO available in public docs and Academy; used for positioning/pricing only.
# - academy : public sees only a stub; Academy sees the full HOWTO when stub.enabled=true.
access: public               # One of: public | mixed | academy.

# Stub metadata.
# Only meaningful when access: academy AND stub.enabled: true.
# In that case:
# - Public docs show content above <!-- STUB_BREAK --> plus stub.blurb/highlights.
# - Academy docs see the full HOWTO body.
# For public/mixed, build tooling ignores STUB_BREAK and publishes the full HOWTO.
stub:
  enabled: false
  blurb: |
    This HOWTO is part of the HybridOps Academy teaching material.

    The full version typically includes:
    - A step-by-step walkthrough of this scenario.
    - Screenshots and timing notes for each major phase.
    - Evidence patterns for validating objectives (for example service availability, performance, or DR targets) and “latest” runs where applicable.
    - Common failure modes and recovery tactics used in the labs.

    Code and automation for this scenario remain open in the main repository.
    This document adds the guided, teaching-focused walkthrough used in the Academy.

  highlights:
    - "Example per-topic highlight describing what is unique about this HOWTO."
    - "Replace or remove these lines in real HOWTOs. Omit the key entirely if not needed."

  cta_url: "https://academy.hybridops.studio/courses/<course-key>/<howto-key>"
  cta_label: "View full HOWTO on HybridOps Academy"

---

# <Short, descriptive HOWTO title>

**Purpose:** One or two sentences describing the outcome of this HOWTO.  
**Difficulty:** <Beginner | Intermediate | Advanced>  
**Prerequisites:** Required accounts, access, tools, or lab state.

---

## Demo (optional)

If this HOWTO has a public video, add it here.

- Demo: [Watch on YouTube](https://youtu.be/VIDEO_ID)  
- Source: [View script or module on GitHub](https://github.com/<org>/<repo>/<path>)

Optional embedded player for public HOWTOs:

<details>
  <summary><strong>Show embedded demo</strong></summary>

  <iframe
    width="100%"
    height="400"
    src="https://www.youtube.com/embed/VIDEO_ID"
    frameborder="0"
    allowfullscreen>
  </iframe>

</details>

---

## Context

Explain when and why to use this HOWTO:

- Problem or task it addresses.  
- Where it fits in the wider HybridOps flow (bootstrap, DR drill, burst, administration).  
- Assumptions about environment, scale, or prior steps.

---

## Steps

### 1. <Step heading>

- Describe what is done and why.  
- Show example commands or configuration:
  ```bash
  # replace with real commands
  some-cli --flag value
  ```
- State the expected result and how to confirm it.

### 2. <Step heading>

- Explanation.  
- Commands or configuration.  
- Expected result.

(Add additional step sections as required. Keep steps atomic and verifiable.)

---

## Validation

Describe how to confirm success:

- Checks to run (CLI, UI, dashboards).  
- Key metrics or conditions (pods ready, services reachable, VPN up, etc.).  
- Where to capture evidence (for example `docs/proof/...`, `output/artifacts/...`).

---

## Troubleshooting

List common issues and resolutions:

- Symptom → likely cause → fix.  
- When to escalate or fall back to a DR/runbook.

---

<!-- STUB_BREAK: content below may be academy-only when access: academy and stub.enabled=true -->

## References

Update to match the topic:

- Related runbooks: `../runbooks/...`  
- Evidence Map: `../evidence_map.md`  
- ADRs influencing this HOWTO: `../adr/ADR-XXXX-something.md`  
- Source code or modules: `https://github.com/<org>/<repo>/<path>`

---

**Author:** Jeleel Muibi  
**Project:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation
