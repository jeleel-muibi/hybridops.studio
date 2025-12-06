# Evidence Slot 7 – Docs Engine & HybridOps Academy (OC2)

> **Criteria:** Optional Criteria 2 (OC2) – contributions outside of immediate occupation (teaching, documentation, community).  
> **Scope:** MkDocs-based docs engine, ADR/HOWTO/runbook/CI/CASE templates, and HybridOps Academy showcases at docs.hybridops.studio.  
> **Note (working copy only):** `[IMG-XX]` placeholders will be replaced with final screenshots before submission.

---

## 1. Summary – Turning a Platform into an Academy

HybridOps.Studio is not only a hybrid infrastructure platform; it is also a **documentation- and academy-ready platform blueprint**. The documentation is published as a MkDocs site at **docs.hybridops.studio**, with hands-on showcases surfaced at **docs.hybridops.studio/showcase**.

This evidence shows how I built:

- A **documentation system** that turns ADRs, HOWTOs, runbooks, CI briefs and case studies into a coherent site.  
- A **HybridOps Academy** structure that organises hands-on showcases and labs for learners.  

The intent is to make the platform understandable and reusable by others – hiring managers, assessors, engineers and future students – not just by me.

[IMG-01 – Screenshot of docs.hybridops.studio showing the main navigation and ADR/HOWTO/runbook indexes – ~6 lines]

---

## 2. Documentation Engine – MkDocs, Taxonomy and Indexing

### 2.1 MkDocs build pipeline

HybridOps.Studio uses **MkDocs** as the basis for its documentation, with two main entry points:

- `make docs.prepare` – generates indexes and documentation trees.  
- `make docs.build` – builds the documentation sites (public and academy).

The docs pipeline:

- Scans ADRs, HOWTOs, runbooks, CI briefs and case studies.  
- Generates index pages (ADR index, HOWTO index, runbook index, CI index, case study index).  
- Builds a structured navigation for both:
  - A **public** documentation view aimed at external readers.  
  - An **academy** view aimed at learners and workshop/bootcamp participants.

[IMG-02 – Screenshot of ADR / HOWTO / runbook index page – ~6 lines]

### 2.2 Taxonomy and folder structure

Documentation is organised into a clear taxonomy:

- `docs/adr/` – Architectural Decision Records.  
- `docs/howtos/` – HOWTO guides (task-focused, step-by-step).  
- `docs/runbooks/` – Runbooks (incident/operations-focused).  
- `docs/ci/` – CI briefs and pipeline documentation.  
- `docs/cases/` – Case studies and scenario write-ups.  
- `deployment/academy/showcases/` – Academy showcases and labs.  

Each type has a well-defined template, for example:

- `ADR_template.md` – standard front matter, context/decision/consequences, links to HOWTOs/runbooks/evidence.  
- `HOWTO_template.md` – purpose, difficulty, prerequisites, steps, validation, references.  
- `runbook_template.md` – trigger, severity, impact, safety checks, steps, rollback, evidence.  
- `CI_template.md` – pipeline purpose, triggers, steps, artefacts.  
- `CASE_template.md` – scenario, actors, timeline, lessons learned.  
- `show_README_template.md` – how to document a showcase or lab under the academy tree.

These templates make it easy for someone else to:

- Understand the **shape** of documentation.  
- Add new material in a consistent, professional style.

[IMG-03 – Screenshot of a template file (e.g. HOWTO_template.md) rendered in the docs site – ~6 lines]

---

## 3. HybridOps Academy – Showcases and Labs

### 3.1 Academy structure

The **HybridOps Academy** lives under:

- `deployment/academy/showcases/`

Each showcase is a **self-contained learning asset** with:

- A `README.lab.md` following `show_README_template.md`.  
- Links back to relevant ADRs, HOWTOs, runbooks and CI docs.  
- Instructions to reproduce the scenario using the platform.

Examples of planned or existing showcases include:

- **CI/CD Pipeline Showcase**  
  - Demonstrates how code changes flow through linting, validation, Packer/Terraform/Ansible pipelines and into RKE2.  
  - References CI briefs, ADRs for Packer/CI, and evidence folders.

- **DR Drill & Cost Guardrails Showcase**  
  - Walks through a simulated Jenkins outage, Prometheus alert, GitHub Actions DR workflow and cost decision.  
  - Uses `HOWTO_dr_cost_drill.md`, DR runbooks and `docs/proof/dr/` / `docs/proof/cost/`.

- **Hybrid Network & SoT Showcase**  
  - Shows how NetBox drives network and infrastructure automation.  
  - Links to networking ADRs, NetBox HOWTOs, and SoT runbooks.

These showcases are surfaced through the academy entry point at **docs.hybridops.studio/showcases**, so learners can browse and follow them without cloning the repository.

[IMG-04 – Screenshot of an academy showcase README showing objectives, prerequisites and steps – ~6 lines]

### 3.2 Teaching orientation

Each academy showcase is written as if it were:

- Material for a **bootcamp lab** or  
- A **consulting engagement** deliverable explaining the design to a client team.

They include:

- Clear **learning objectives**.  
- Pre-requisites and required environment.  
- Step-by-step actions.  
- Validation checks (“what you should see”).  
- Links to deeper design documents (ADRs, evidence packs).

This turns HybridOps.Studio into a **repeatable teaching platform**, not just a one-off experimental environment.

---

## 4. Examples of Documentation in Use

### 4.1 DR drill HOWTO and runbooks

The DR work described in another evidence pack is fully documented in the academy and docs engine:

- `HOWTO_dr_cost_drill.md`  
  - Aimed at learners/operators who want to run a DR drill end-to-end.  

- DR runbooks:
  - DR cutover (on-prem → cloud).  
  - DR failback (cloud → on-prem).  
  - Cost guardrail breach (decision `block` or `warn`).  
  - Jenkins outage and db-01 failover.

[IMG-05 – Screenshot of HOWTO_dr_cost_drill.md as rendered in the docs site – ~6 lines]

Someone who has never seen HybridOps.Studio before could follow this HOWTO and the associated runbooks to:

- Trigger a DR drill.  
- Observe the Prometheus → Alertmanager → GitHub Actions → Cost Decision Service flow.  
- Verify artefacts in `docs/proof/dr/` and `docs/proof/cost/`.

### 4.2 ADR index and cross-linking

Each ADR links out to:

- Relevant HOWTOs and runbooks.  
- Proof artefacts and CI docs.  
- Diagrams or case studies where appropriate.

For example:

- The ADR for the Packer image pipeline references:
  - The Packer HOWTO.  
  - CI docs for the image pipeline.  
  - Proof artefacts under `docs/proof/infra/packer/`.

This cross-linking shows an intentional effort to make the documentation **navigable and coherent**, not just a pile of files.

[IMG-06 – Screenshot of ADR index with clickable links to ADRs and related docs – ~6 lines]

---

## 5. Contribution Beyond Occupation

This documentation and academy work is explicitly **beyond any single job**:

- It is **self-directed** work, built in my own time, at a level of structure and polish that could be used:
  - To onboard new team members in an enterprise environment.  
  - As the basis for workshops, bootcamps or online courses.  
  - As high-quality support material for consulting engagements.

It demonstrates that I:

- Think about engineering work in terms of **reusability and teaching**.  
- Am willing to invest in extensive **supporting materials** (templates, indexes, showcases) so that others can stand on my shoulders.  
- Can translate complex platform and DR designs into **clear, consumable documentation** for different audiences.

[IMG-07 – Optional collage: docs home, academy showcase, template snippet – ~6 lines]

---

## 6. How This Meets Optional Criteria 2 (Contributions Outside Occupation)

This evidence supports Optional Criteria 2 by showing that I have:

- Designed and implemented a **documentation engine** that turns HybridOps.Studio into a structured, navigable body of knowledge rather than a private experiment.  
- Built a **HybridOps Academy** structure – templates, showcases and labs – that is explicitly intended for learners, mentees and clients, with public access via the docs portal and premium bootcamps layered on top.  
- Made it easy for others to extend and maintain the system through standardised ADR, HOWTO, runbook, CI and CASE templates, plus automated indexes and evidence folders.  
- Grounded all of this in **real technical content** – networking, SoT, delivery, DR, cost – so that the documentation and Academy are anchored in genuine platform/SRE work, not generic tutorials.

This shows that I am not only capable of designing and operating complex hybrid platforms, but also of **explaining, systematising and teaching those designs to others** – a core expectation for someone on a leadership trajectory under Tech Nation’s OC2.

---

**Context & navigation**

For easier cross-referencing, this PDF is mirrored on the [HybridOps.Studio documentation portal](https://docs.hybridops.studio) and linked from the [Tech Nation assessors’ guide](https://docs.hybridops.studio/briefings/gtv/how-to-review/). The docs site adds navigation only, not new evidence.
