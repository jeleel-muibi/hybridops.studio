# Assessors — How to Review HybridOps.Studio

> **Purpose of this page**  
> This is a short navigation guide for reviewers.  
> It explains how the Tech Nation evidence PDFs map to the underlying Markdown sources in this repository and where to find supporting material if you want more depth.

HybridOps.Studio is treated as a **hybrid platform blueprint and reference implementation**.  
Each Tech Nation evidence PDF you receive is generated from a corresponding Markdown file under `docs/briefings/gtv/`.

This page does **not** add new evidence; it simply shows you how the submitted documents relate to the rest of the documentation.

---

## 1. What you already have (Tech Nation submission)

In the Tech Nation portal you will see:

- A **personal statement** (PDF, max 1,000 words).
- Up to **10 evidence PDFs** (each max 3 pages), covering:
  - Mandatory Criteria (MC).
  - Optional Criteria 1 (OC1) – innovation / technical contributions.
  - Optional Criteria 2 (OC2) – contributions outside employment.

Each of those PDFs is generated from a single Markdown source file in this folder.  
The PDFs are the **canonical** artefacts for the application.

If there is ever a difference between a PDF and a Markdown view, the **PDF should be treated as the source of truth**.

---

## 2. Suggested reading order

If you are reviewing the application with this docs portal open, the most efficient order is:

1. **Personal statement**  
   - Source: [`personal_statement.md`](personal_statement.md)  
   - Role: Overall narrative – HybridOps.Studio, academic background, Latymer role, UK plans.

2. **MC Slot 1 – Platform Overview & Trajectory**  
   - Source: [`MC/01_platform-overview.md`](MC/01_platform-overview.md)  
   - Role: Explains HybridOps.Studio as a **hybrid platform blueprint and reference implementation** and how it demonstrates leadership potential.

3. **MC Slot 2 – Academic Excellence & Early Innovation**  
   - Source: [`MC/02_academic-early-innovation.md`](MC/02_academic-early-innovation.md)  
   - Role: First-class BSc Computer Science, departmental award, top-15 final-year project, and ongoing structured training.

4. **MC Slot 3 – Real-World Contributions in Employed Roles (Latymer)**  
   - Source: [`MC/03_real-world-contributions-latymer.md`](MC/03_real-world-contributions-latymer.md)  
   - Role: Concrete impact as an IT Technician with system administration responsibilities and early platform thinking in a live school environment.

5. **OC1 Slots – Innovation / Technical Contributions**

   - Hybrid network & WAN edge  
     → [`OC1/03_hybrid-network-wan-edge.md`](OC1/03_hybrid-network-wan-edge.md)

   - Source of truth & automation (NetBox)  
     → [`OC1/04_source-of-truth-automation.md`](OC1/04_source-of-truth-automation.md)

   - Hybrid DR & cost-aware automation  
     → [`OC1/05_hybrid-dr-cost.md`](OC1/05_hybrid-dr-cost.md)

6. **OC2 Slots – Contributions outside occupation**

   - Public impact: open source & learning surface  
     → [`OC2/06_public-impact.md`](OC2/06_public-impact.md)

   - Docs engine & HybridOps Academy  
     → [`OC2/07_docs-engine-academy.md`](OC2/07_docs-engine-academy.md)

   - Teaching & public content around HybridOps  
     → [`OC2/08_teaching-public-content.md`](OC2/08_teaching-public-content.md)

   - Public adoption & external recognition  
     → [`OC2/10_public-adoption-external-recognition.md`](OC2/10_public-adoption-external-recognition.md)

For a concise one-page view of all slots, criteria and “one-line impact” statements, see:

- [`gtv_cover_sheet.md`](gtv_cover_sheet.md)

---

## 3. Relationship between PDFs and this documentation

For each evidence slot:

- The **Tech Nation PDF** is a 2–3 page export from the corresponding Markdown file listed above.
- The Markdown page:
  - Uses the same headings and narrative.
  - Contains the same `[IMG-XX]` / `[ART-XX]` placeholders that were replaced with diagrams and screenshots in the submitted PDF.
- Any additional links (for example ADRs, HOWTOs, runbooks) are **supporting context**, not separate evidence documents.

To avoid redundancy:

- This portal does **not** host separate “annotated” versions of the PDFs.
- Instead, it lets you:
  - Read exactly the same text in HTML form.
  - Click through to the underlying technical documentation if you wish.

---

## 4. Where to find supporting technical material

Each evidence slot points to specific technical artefacts.  
If you want to verify a claim, the main entry points are:

- **Architecture decisions (ADRs)**  
  → [`adr/000-INDEX.md`](../../adr/000-INDEX.md)  
  Library of decisions (for example Packer image pipeline, NetBox as source of truth, DR signal design).

- **How-To guides**  
  → [`howto/000-INDEX.md`](../../howto/000-INDEX.md)  
  Task-focused guides (for example Packer builds, RKE2 bootstrap, NetBox migration, DR drills).

- **Runbooks**  
  → [`runbooks/000-INDEX.md`](../../runbooks/000-INDEX.md)  
  Operational procedures (for example DR cutover/failback, Jenkins outage, db-01 failover).

- **Evidence Map and proof folders**  
  - [`Evidence Map`](../../evidence_map.md) – overview of proof areas grouped by theme (networking, DR, cost, images, GitOps, source of truth) and pointers into proof and runbook material.  
  - `docs/proof/` – structured logs, screenshots and artefacts for key flows such as image builds, DR drills, networking tests and cost runs.

### Evidence Map – verifiable behaviours

To support assessors and hiring managers, the docs portal includes an [Evidence Map](../../evidence_map.md) that groups proof by theme (networking, DR, cost, images, GitOps, source of truth) and links each claim to:

- The relevant **proof folder** under `proof/...`, and  
- The corresponding **runbooks** and CI logs.

This page does not add new evidence beyond the submitted PDFs; it simply makes it easy to cross-check behaviours like “DR flow is repeatable” or “cost guardrails are enforced” against concrete runs and artefacts.

These supporting materials are there so that you can:

- Trace a described behaviour (for example “cost-aware DR drill”)  
  → to a **runbook / HOWTO**  
  → to **real logs and artefacts** in `docs/proof/` and `output/`.

---

## 5. Reading guidance

If you have limited time, a pragmatic path is:

1. **Personal statement** → [`personal_statement.md`](personal_statement.md)  
2. **MC Slot 1** (platform overview) → [`MC/01_platform-overview.md`](MC/01_platform-overview.md)  
3. **One strong OC1 slot** (for depth) → for example [`OC1/05_hybrid-dr-cost.md`](OC1/05_hybrid-dr-cost.md)  
4. **One strong OC2 slot** (for contributions outside work) → for example [`OC2/07_docs-engine-academy.md`](OC2/07_docs-engine-academy.md)

You can then:

- Skim the **cover sheet** for the remaining slots → [`gtv_cover_sheet.md`](gtv_cover_sheet.md)  
- Dip into ADR / HOWTO / runbook indexes if you want to check specific flows in more detail.

---

**Note for assessors**

This briefing area is intended purely as a **navigation aid** and a way to inspect the same material in HTML form.  
It does not introduce additional annexes or separate evidence beyond the PDFs submitted to Tech Nation.
