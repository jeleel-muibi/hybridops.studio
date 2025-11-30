---
title: "Showcase – <Showcase Name>"
category: "showcase"
summary: "<One-line value proposition for this showcase.>"
difficulty: "Intermediate"

topic: "showcase-<slug>"

video: "https://www.youtube.com/watch?v=<VIDEO_ID>"
source: "https://github.com/hybridops-studio/hybridops-studio"

draft: false
is_template_doc: true
tags: ["showcase", "portfolio"]

audience: ["hiring-managers", "learners"]
access: "mixed"  # public | mixed | academy

academy:
  enabled: true
  package_path: "deployment/academy/showcases/<slug>"
  lab_id: "HOS-SH-XXX"
  access: "academy"
---

# <Showcase Name>

## Executive summary

One or two short paragraphs that explain:

- What this showcase proves.
- Why it matters in a real environment (cost, risk, reliability, speed, observability).
- How it fits into the wider HybridOps.Studio architecture.

Keep this concise and focused on outcomes and decision-making.

---

## Case study – how this was used in practice

Use a simple structure:

- **Context:** Where this scenario sits in the platform and what problem it addresses.
- **Challenge:** Why the “before” state was painful or risky.
- **Approach:** How you applied HybridOps.Studio components (Deployment/Core/Control) to solve it.
- **Outcome:** Concrete improvements (time saved, failure avoided, repeatability gained, visibility improved).

Add links to relevant ADRs and briefings, for example:

- [ADR-00XX – <Related architectural decision>](../../adr/ADR-00XX-some-decision.md)
- [Briefing – <Related design or risk briefing>](../../briefings/<briefing-name>.md)

---

## Demo

### Video walkthrough

Embed or link the YouTube demo for this showcase:

- Video: https://www.youtube.com/watch?v=<VIDEO_ID>
- Playlist (optional): https://www.youtube.com/playlist?list=<PLAYLIST_ID>

Add a short paragraph describing what the viewer will see and what to look out for (for example failover moment, evidence view, dashboards, or pipelines).

### Screenshots

Include a small, curated set of screenshots that support the story:

```markdown
![Dashboard or pipeline view](./screenshots/<image-1>.png)
![Architecture or topology](./diagrams/<image-2>.png)
```

Avoid dumping everything; keep this focused on clarity and evidence.

---

## Architecture

Explain how this scenario fits into the overall architecture:

- Draw from the platform hero diagrams where relevant.
- Highlight which domains are involved (networking, platform, data, security, DR, CI/CD).

Typical content:

- High-level diagram for this scenario:

  ```markdown
  ![Scenario architecture](./diagrams/architecture-overview.png)
  ```

- Key components and flows:
  - What runs on-prem versus in cloud.
  - Which control planes are involved (DNS, GitOps, CI/CD, Kubernetes).
  - Any important constraints or trade-offs.

---

## Implementation highlights

Summarise how the scenario is implemented using the existing platform building blocks:

- **Deployment:** which playbooks, inventories, and overlays are involved.  
  Example: `deployment/environments/<env>/...` or `deployment/academy/showcases/<slug>/overlays/...`
- **Core:** which roles, plugins or helpers are central to this scenario.  
  Example: `core/ansible/...` or `core/powershell/...`
- **Control:** which operator tools or decision helpers are relevant.  
  Example: `control/tools/...` or `control/decisions/...`
- **CI/CD:** which pipelines run to bring this scenario to life.  
  Example: `ci/pipelines/<pipeline-name>.md` or the Jenkins/GitHub Actions definitions.

Focus on patterns and responsibilities; link to code rather than inlining it here.

---

## Assets and source

List the key source locations and artefacts that support this showcase.

Examples:

- **Platform code:**
  - `deployment/.../<path-to-plays-or-overlays>`
  - `core/ansible/.../<role-or-collection>`
  - `control/tools/.../<tool-or-wrapper>`

- **CI/CD definitions:**
  - `ci/.../<pipeline-or-job>.md`
  - `.github/workflows/<workflow>.yml` or Jenkins pipeline definitions if applicable.

- **Evidence and proofs:**
  - Evidence entries from the **Evidence Map**: `../../evidence_map.md`
  - Proof archive paths under `docs/proof/...` if they exist for this scenario.

Use descriptive link text, not raw paths.

---

## Academy track (if applicable)

If `academy.enabled` is `true`, describe how this showcase is packaged as a lab.

Example structure:

- **Lab ID:** `HOS-SH-XXX`
- **Packaging path:** `deployment/academy/showcases/<slug>/`
- **What learners do:**
  - Run one or more pipelines or playbooks.
  - Observe changes in dashboards or system behaviour.
  - Collect a small set of artefacts or answer short questions.

Describe:

- Prerequisites (environment, access, approximate time).
- The main learning outcomes tied to HybridOps.Studio (not just “how to click buttons”).
- How the lab uses the same automation and patterns that production scenarios would use.

---

## Role-based lens (optional)

You can tailor a short section for different personas:

- **Platform Engineer / SRE:** what this scenario demonstrates about reliability, automation and observability.
- **Network / Infrastructure Engineer:** what it shows about resilient networking, DR, connectivity, or infra patterns.
- **Engineering Manager / Hiring Manager:** what this proves about ownership, risk management, and how you think about change.

Keep it short and grounded in what the demo actually shows.

---

## Back to showcase catalogue

- [Back to all showcases](../README.md)

---

**Author:** Jeleel Muibi  
**Project:** HybridOps.Studio Showcase  
**License:** MIT-0 for code, CC-BY-4.0 for documentation
