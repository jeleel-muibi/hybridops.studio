# Evidence 5 – Documentation, Teaching & Community  
**HybridOps.Studio – Docs Engine, Academy & Public Artefacts**

---

## Evidence Context

This document is **Evidence 5 of 5** for my UK Global Talent application (digital technology).

- **Evidence 1** – Hybrid network & connectivity blueprint.  
- **Evidence 2** – WAN edge, dual ISP and hybrid cloud connectivity.  
- **Evidence 3** – Source of truth and automation (NetBox, Terraform, Nornir, Ansible).  
- **Evidence 4** – Delivery platform, GitOps and cluster operations (Packer, Jenkins, RKE2, DR & cost).

This fifth evidence focuses on how I **explain, teach, and package** HybridOps.Studio:

- A **documentation engine** (MkDocs) that produces both a public docs site and an “academy” view from the same repo.  
- A structured system of **ADRs, HOWTOs, runbooks, case studies and showcases**, wired together by indexing scripts.  
- An emerging **HybridOps Academy** – labs and showcases that reuse the same infrastructure as the “real” platform.  
- Foundations for **community artefacts** – Ansible Galaxy collections, CI templates, and teaching materials.

It shows that I can take a complex hybrid platform and turn it into **clear, reusable, and teachable material** for engineers, students and hiring managers.

---

## 1. Executive Summary

HybridOps.Studio is not just a private homelab. It is designed as a **teaching and consulting asset** with:

- A **MkDocs-based documentation platform** that builds two views:
  - A **public** site (for hiring managers, assessors, community).  
  - An **academy** site (for deeper labs and bootcamps).
- A disciplined structure for:
  - **ADRs** (architectural decisions)  
  - **HOWTOs** (practical labs & learning guides)  
  - **Runbooks** (operational checklists)  
  - **Showcases / case studies** (reader-friendly stories with demos).
- A “docs as platform” mindset:
  - Docs are generated, indexed and published via **Make + Python tooling**, just like infrastructure.  
  - Evidence (logs, screenshots, cost JSON, DR artefacts) lives under `docs/proof/` and is surfaced through the docs site.
- A roadmap towards **public impact**:
  - HybridOps Academy labs mapped to showcases (for example, “DR drill”, “CI/CD pipeline”, “Hybrid network”).  
  - Ansible Galaxy roles/collections and future bootcamps built on top of the same artefacts.

The key question this evidence answers is:

> **Can this person design documentation, teaching flows, and community assets around a complex platform in a way that is systematic and reusable – not just ad-hoc wiki pages?**

---

## 2. Documentation Platform Architecture

### 2.1 MkDocs – Public & Academy Views

The documentation engine is built on **MkDocs**, driven by Make targets and Python helpers.

Key elements:

- **Two MkDocs configs** (example paths):
  - Public docs: `control/tools/docs/mkdoc/mkdocs.public.yml`  
  - Academy docs: `control/tools/docs/mkdoc/mkdocs.academy.yml`
- **Make targets** (simplified):

  - `make docs.prepare` – generate indexes and prepare trees:
    - ADR index  
    - HOWTO index  
    - Runbook index  
    - CI index  
    - Case study index  
    - Stub filtering and MkDocs tree generation
  - `make docs.build` – build:
    - Public site under `deployment/build/docs/public`  
    - Academy site under `deployment/build/docs/academy`

- **Indexing scripts** in `control/tools/docs/indexing/`:
  - Walk `docs/adr/`, `docs/howtos/`, `docs/runbooks/`, `docs/ci/`, `docs/cases/`.  
  - Generate machine-readable indexes that MkDocs turns into human-friendly catalogues.

These pieces mean that **adding a new ADR/HOWTO/runbook** automatically surfaces it in the right section of the site without hand-editing navigation.

---

### 2.2 Documentation Taxonomy

HybridOps.Studio documentation is intentionally structured:

- `docs/adr/` – Architectural Decision Records  
  - Governed by [ADR-0001 – ADR Process & Conventions](../adr/ADR-0001-adr-process-and-conventions.md).  
  - Category codes for networking, platform, CI/CD, DR, cost, etc.

- `docs/howtos/` – Learning guides and labs  
  - Use `HOWTO_template.md` to enforce consistent frontmatter (topic, difficulty, tags, video, access).  
  - Example: [HOWTO – Run a Cost-Aware DR Drill](../howtos/HOWTO_dr_cost_drill.md).

- `docs/runbooks/` – Operational runbooks  
  - Based on `runbook_template.md` with clear triggers, severity, checks and rollback.

- `docs/ci/` – CI/CD scenario briefs  
  - Use `CI_template.md` to describe specific pipelines and their evidence.

- `docs/cases/` – Case studies / narrative stories  
  - Use `CASE_template.md` to turn technical scenarios into concise business/engineering stories.

- `deployment/academy/showcases/` – Showcase & lab packaging  
  - Each showcase has a **Show README** based on `show_README_template.md`.  
  - Example locations:  
    - `deployment/academy/showcases/ci-cd-pipeline/...`  
    - `deployment/academy/showcases/avd-zerotouch-deployment/...`

The same patterns that power the Global Talent evidences also power **public docs and academy materials**.

---

## 3. HybridOps Academy & Showcases

### 3.1 Showcases as First-Class Artefacts

Showcases represent curated “stories” built on top of the platform:

- Each showcase has a `show_README.md` derived from  
  [`show_README_template.md`](../showcases/show_README_template.md).
- The template forces:

  - A clear **executive summary** (“what this proves and why it matters”).  
  - A **case study** section (context, challenge, approach, outcome).  
  - Links to **ADRs**, **briefings**, and **evidence**.  
  - A **demo** section with YouTube links and screenshots.  
  - An **academy track** block (lab ID, packaging path, learner outcomes).

These showcases become **landing pages** for assessors, hiring managers and learners: each one explains a concrete scenario and then points back into the deeper docs and proof folders.

---

### 3.2 Academy Packaging

HybridOps Academy uses the same repository as the platform:

- Labs live under `deployment/academy/showcases/<slug>/`.  
- Each lab maps to a showcase and one or more HOWTOs, for example:

  - “Cost-Aware DR Drill” lab:
    - Showcase: “Hybrid DR with Cost Guardrails”.  
    - HOWTO: [Run a Cost-Aware DR Drill](../howtos/HOWTO_dr_cost_drill.md).  
    - Evidence paths under:
      - `docs/proof/dr/`  
      - `docs/proof/cost/`.

- Labs are designed to be delivered via a **learning platform** (for example Moodle) without changing the underlying automation:
  - Learners run the same pipelines and playbooks used in the main platform.  
  - Documentation explains **why** a step exists, not just what to click.

This design means that academy content can be reused for:

- **Bootcamps**,  
- **Customer training**, and  
- **Public workshops** built on HybridOps.Studio.

---

## 4. Public & Community Artefacts

### 4.1 Code & Docs Licensing

To make community contribution straightforward, the repo uses:

- **MIT-0** for code.  
- **CC-BY-4.0** for documentation.

This is reflected in many docs footers:

> **Maintainer:** HybridOps.Studio  
> **License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.

That choice allows:

- Easy reuse of code snippets, scripts and automation in client environments.  
- Safe sharing of documentation, runbooks and HOWTOs in public spaces (blogs, LinkedIn, academy).

---

### 4.2 Ansible & Automation Contributions

HybridOps.Studio is designed to back Ansible Galaxy roles/collections and similar public artefacts:

- **Collections & roles** are structured in `core/ansible/` so that:
  - Each role has its own README, defaults, and tests.  
  - Pipelines can run Molecule tests and publish to Ansible Galaxy.

- For Evidence 5, the emphasis is on:

  - The **framework** for publishing (CI templates, docs templates, evidence folders).  
  - The ability to **loop downloads via pipelines** and capture usage as part of the evidence story.

As collections mature, they plug neatly into the same documentation and academy framework (HOWTOs, showcases, labs).

---

### 4.3 CI & Case Templates

To keep contributions consistent, HybridOps.Studio includes dedicated templates:

- [`CI_template.md`](../ci/CI_template.md) – explains how to document a pipeline:
  - Frontmatter with topic, tags, audience.  
  - Sections for objectives, pipeline stages, validation, and evidence.

- [`CASE_template.md`](../cases/CASE_template.md) – explains how to write a narrative case:
  - Focus on context, challenge, approach, and outcome.  
  - Links to ADRs, HOWTOs and proof.

These templates make it easier to:

- Turn internal successes into **shareable stories**.  
- Align future blog posts, talks and LinkedIn articles with the same structure.

---

## 5. Implementation Highlights

### 5.1 Docs Preparation & Build Flow (Excerpt)

A simplified view of the docs tooling:

1. `make docs.prepare`:
   - Runs Python scripts in `control/tools/docs/indexing/` to:
     - Build ADR, HOWTO, runbook, CI, and case indexes.  
     - Generate any stub entries for missing or draft docs.  
   - Runs a MkDocs tree builder so that public and academy navs are generated from the same source.

2. `make docs.build`:
   - Invokes MkDocs with:
     - `mkdocs.public.yml` → `deployment/build/docs/public/`  
     - `mkdocs.academy.yml` → `deployment/build/docs/academy/`

3. CI integration:
   - A CI pipeline can run both targets on push and publish static sites to a docs host (for example, GitHub Pages or a small static host VM).

The effect is that documentation is **repeatable, auditable, and deployable** – treated like application code.

---

### 5.2 HOWTO – Cost-Aware DR Drill (Representative Example)

[HOWTO_dr_cost_drill.md](../howtos/HOWTO_dr_cost_drill.md) shows the full pattern:

- Frontmatter describes:
  - Topic (`dr-cost-drill`)  
  - Difficulty, tags, access (public/academy).  
  - Video URL and source repository.

- Body walks through phases:

  - Setting up Prometheus/Alertmanager and a DR alert.  
  - Wiring a webhook into a GitHub Actions DR workflow.  
  - Integrating the **Cost Decision Service** to authorise or deny actions.  
  - Capturing artefacts under:
    - `docs/proof/dr/`  
    - `docs/proof/cost/`.

- Ends with a **validation checklist** so learners and assessors can verify the outcome.

This illustrates how technical content, DR patterns, and cost discipline are turned into a **teachable exercise** with clear evidence.

---

### 5.3 Evidence Integration

Evidence 5 ties back into the rest of the system:

- ADRs such as:

  - [ADR-0001 – ADR Process & Conventions](../adr/ADR-0001-adr-process-and-conventions.md)  
  - Platform/DR/cost ADRs (for example, RKE2 runtime, DR orchestrator, cost-as-signal) referenced in HOWTOs and runbooks.

- Proof archives such as:

  - `docs/proof/infra/packer/…`  
  - `docs/proof/infra/terraform/…`  
  - `docs/proof/infra/ansible/…`  
  - `docs/proof/dr/…`  
  - `docs/proof/cost/…`

The documentation engine makes these discoverable via indexes, and showcases/academy material tell the story around them.

---

## 6. Links & Artefacts

**Docs engine & structure**

- ADR governance: [ADR-0001 – ADR Process & Conventions](../adr/ADR-0001-adr-process-and-conventions.md)  
- ADR catalogue: [`docs/adr/`](../adr/)  
- HOWTO catalogue: [`docs/howtos/`](../howtos/)  
- Runbooks catalogue: [`docs/runbooks/`](../runbooks/)  
- CI docs: [`docs/ci/`](../ci/)  
- Case studies: [`docs/cases/`](../cases/)

**Templates**

- HOWTO template: [HOWTO_template.md](../howtos/HOWTO_template.md)  
- Runbook template: [runbook_template.md](../runbooks/runbook_template.md)  
- CI template: [CI_template.md](../ci/CI_template.md)  
- Case template: [CASE_template.md](../cases/CASE_template.md)  
- Showcase README template: [show_README_template.md](../showcases/show_README_template.md)

**Showcases & Academy**

- Academy showcases directory: `deployment/academy/showcases/` (for example, CI/CD pipeline, AVD zero-touch deployment showcase).  
- Example HOWTO tied to a lab:  
  - [Run a Cost-Aware DR Drill](../howtos/HOWTO_dr_cost_drill.md)

**CI docs**

- [CI – GitHub Actions Guardrails](../ci/github-actions.md)  
- [CI – Jenkins Orchestrator](../ci/jenkins.md)  
- [CI – Emit Cost Artefacts from Pipelines](../ci/CI_cost_artefacts_from_pipelines.md)  

**Proof & Evidence**

- DR drill and cost evidence:  
  - `docs/proof/dr/`  
  - `docs/proof/cost/`
- Infrastructure and automation evidence (referenced by academy content):  
  - `docs/proof/infra/packer/`  
  - `docs/proof/infra/terraform/`  
  - `docs/proof/infra/ansible/`  
  - `docs/proof/apps/`

Together, these artefacts show that HybridOps.Studio is not only a technically sophisticated hybrid platform, but also a **documented, teachable and reusable system** – ready to support Global Talent evidence, consulting work, and future learners.

---

**Owner:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation
