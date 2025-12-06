---
title: "CI/CD Pipeline Template"
id: "CI-XXXX"                # Optional stable ID if you want to reference this pipeline elsewhere.
owner: "HybridOps.Studio"    # Team or role responsible for the pipeline.
summary: "Template for documenting CI/CD pipelines (excluded from index)."

scope: "platform"            # e.g. platform | images | docs | netbox | terraform | ansible | kubernetes.

draft: true                  # true => skip from any future CI index.
is_template_doc: true               # keeps this file out of generated lists even if draft=false.
tags: ["template"]           # Optional labels, e.g. ["jenkins", "github-actions"].

# Access / commercial model (interpreted by build tooling):
# - public  : pipeline documentation is fully available in public docs.
# - academy : deeper, teaching-focused analysis lives in HybridOps Academy; public may see a stub.
# - mixed   : operational details public; teaching narrative reserved for Academy.
access: public               # One of: public | academy | mixed.

# Stub metadata.
# For academy pipelines, set enabled: true and fill the fields below. Build tooling can then
# derive a public-facing stub and CTA while keeping the full analysis in Academy.
stub:
  enabled: false             # Set true when this pipeline is part of Academy material.
  blurb: |
    This CI/CD pipeline is covered in depth as part of the HybridOps Academy material.

    The full version typically includes:
    - A stage-by-stage walkthrough of the pipeline flow and failure modes.
    - Screenshots or excerpts of key jobs, logs, and dashboards.
    - Evidence patterns for validating outcomes (for example image integrity, DR drills, or promotion gates).
    - Discussion of trade-offs in tooling, agents, and integration points.

    Code and automation for this pipeline remain open in the main repository.
    This document adds the structured, teaching-focused analysis used in the Academy.

  highlights:
    - "Example highlight describing what is unique about this pipeline (for example Proxmox Packer builds)."
    - "Replace or remove these lines in real pipelines. Omit the key entirely if not needed."

  cta_url: "https://academy.hybridops.studio/courses/<course-key>/ci-<pipeline-key>"
  cta_label: "View full CI/CD walkthrough on HybridOps Academy"

---

# CI/CD Pipeline — <Descriptive name>

**Purpose:** One or two sentences describing what this pipeline delivers (for example “build and publish Proxmox templates”).  
**Owner:** Team or role.  
**Scope:** Where this pipeline runs (for example Jenkins controllers, GitHub Actions, or both).  
**Triggers:** Branches, tags, schedules, or external events that start this pipeline.

---

## 1. Entry points

Describe how the pipeline is invoked:

- Manual entry points (for example “Run with parameters” in Jenkins).  
- Automatic triggers (push, PR, nightly, scheduled drills).  
- Required parameters and typical values.

If relevant, include links to the CI system views:

- Jenkins: `https://jenkins.example/job/...`  
- GitHub Actions: `.github/workflows/<file>.yml`

---

## 2. Pipeline map

Give a concise overview of the stages and jobs:

- High-level stage list (for example lint → build → test → package → publish).  
- Important parallel branches.  
- Any gates or approvals between stages.

Where useful, include an ASCII or mermaid-style outline for maintainers.

---

## 3. Inputs and dependencies

List the main dependencies for this pipeline:

- Repositories and branches it expects.  
- Secrets and credentials (referenced generically, not with values).  
- External services (for example Proxmox API, Azure, GCP, Docker registries).  
- Required agents or runners (for example Jenkins LXC agents, self-hosted GitHub runners).

Reference where these are defined (for example credential IDs, secret names).

---

## 4. Execution flow (stage-by-stage)

For each major stage, describe:

- What the stage does and why it exists.  
- Key jobs/steps within the stage.  
- Important environment variables, parameters, or configuration.  
- Expected outputs or artefacts.

Keep this section factual; avoid copy-pasting large YAML snippets when a short description is enough. Link to source where needed.

---

## 5. Evidence and observability

Describe how to verify that the pipeline is behaving correctly:

- Logs or reports produced by the pipeline.  
- Dashboards that surface results (for example Grafana panels, build trend views).  
- Evidence locations (for example `output/ci/<pipeline>/...`, `docs/proof/platform/...`).  

Note any “latest” links or symlinks used for portfolio evidence.

---

## 6. Failure modes and recovery

Summarise typical failure patterns and how to respond:

- Common causes of failure (for example agent capacity, credential expiry, integration issues).  
- How to distinguish transient vs systemic problems.  
- Runbooks or HOWTOs to follow when builds fail repeatedly.

If relevant, point to specific sections in runbooks for DR or bootstrap scenarios.

---

## 7. Extensibility and change guidelines

Describe how this pipeline should evolve:

- Safe extension points (for example adding new stages or jobs).  
- Patterns to avoid (for example long-lived mutable agents, manual approvals without audit).  
- When to split the pipeline vs adding more to an existing one.

This helps future changes stay consistent with the current design.

---

## 8. References

Update this section to match the actual pipeline. Use **markdown links**, not bare paths. Typical patterns:

- CI config:  
  - [GitHub Actions workflow](../../.github/workflows/<file>.yml)  
  - [Jenkinsfile](../../ci/jenkins/<pipeline>/Jenkinsfile)
- Related runbooks:  
  - [Runbook – <descriptive name>](../runbooks/<category>/runbook-<slug>.md)
- Related HOWTOs:  
  - [HOWTO – <descriptive name>](../howtos/HOWTO_<slug>.md)
- ADRs influencing this pipeline:  
  - [ADR-XXXX – <short title>](../adr/ADR-XXXX-<slug>.md)
- Evidence folders:  
  - [`docs/proof/<topic>/`](../../docs/proof/<topic>/)

Replace the placeholders above with the concrete paths for this pipeline.

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation
