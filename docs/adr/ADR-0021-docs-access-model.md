---
id: ADR-0021
title: "Documentation Access and Gating Model"
status: Accepted
date: 2025-11-19

domains: ["docs", "platform", "commercial"]
owners: ["HybridOps.Studio"]
supersedes: []
superseded_by: []

links:
  prs: []
  runbooks: ["../runbooks/000-INDEX.md"]
  howtos: ["../howto/000-INDEX.md"]
  evidence: ["../evidence_map.md"]
  diagrams: ["../diagrams/flowcharts/docs-access-model.drawio"]

draft: false
is_template_doc: true
tags: ["docs", "access", "commercial-model"]

access: public

stub:
  enabled: false
  blurb: |
    This ADR defines how documentation is split between public and academy-only
    material across HOWTOs, runbooks, ADRs, and proof artefacts.

  highlights: []
  cta_url: ""
  cta_label: ""

---

# Documentation Access and Gating Model

**Status:** Accepted  
**Domain(s):** docs, platform, commercial  
**Owner(s):** HybridOps.Studio  
**Last updated:** 2025-11-19  

---

## 1. Context

HybridOps.Studio has two overlapping but distinct goals:

- Act as a **public, evidence-backed portfolio** for assessors, hiring managers, and engineers.
- Act as the **foundation for HybridOps Academy**, a commercial training and consulting offering.

The same codebase, runbooks, HOWTOs, and proof artefacts need to serve:

- Public readers (GitHub/MkDocs): learn from the architecture, see real evidence, and reuse code.
- Academy learners (Moodle/Academy): follow guided, teaching-focused material with additional depth.
- Assessors and hiring managers: review concrete proof without having to understand every internal detail.

Without a clear access model, documentation risks becoming:

- Too open: all teaching material is effectively free, undermining the commercial model.
- Too closed: assessors and hiring managers cannot see enough to understand the scope and quality.
- Inconsistent: some pages are written as if they are public, others as if they are internal-only.

We need a simple, explicit way to:

- Mark which documents are **public** vs **academy-focused**.
- Allow the same source file to generate both **full** and **stubbed** variants via build tooling.
- Keep the **file structure stable** so indexes (HOWTO index, runbook index, ADR index, evidence map) remain accurate.

---

## 2. Decision

We introduce a **three-level documentation access model** implemented in front matter and enforced by build tooling:

- `access: public` — document is intended to be fully visible in public docs.
- `access: academy` — document is intended primarily for HybridOps Academy; public may see only a stub.
- `access: mixed` — document has both public and academy-only aspects; build tooling treats it as academy by default.

In addition, each document can define a `stub` block in front matter:

- `stub.enabled: true|false`
- `stub.blurb`: short narrative explaining that this is part of Academy material and what the full version contains.
- Optional `stub.highlights`: a small number of per-topic bullets summarising unique aspects.
- Optional `stub.cta_url` and `stub.cta_label` for pointing to Academy landing pages.

**Authoring rules:**

- Authors always write the **full document** (HOWTO, runbook, ADR) in a single file.
- The file’s front matter carries `access` and `stub` metadata; the body is not manually split.
- Build tooling is responsible for producing public and academy variants (for example, stripping sections or replacing with stubs).

**Index rules:**

- Public indexes (for example `000-INDEX.md` for HOWTOs and runbooks, ADR index, Evidence Map) can list **all items**, including academy ones.
- Academy-only items are clearly marked in the index (for example via a column or label), and links for public readers route to **stub pages** with a CTA.
- Academy learners, once authenticated in Moodle/Academy, follow links that render the **full document** (for example via embedded MkDocs or direct HTML).

---

## 3. Rationale

This model is chosen because it:

- Supports a **single source of truth**: one file per HOWTO/runbook/ADR, authored once and reused for both public and academy contexts.
- Keeps the **repository and indexes stable**: code and documentation remain navigable for engineers and assessors, even when some content is gated.
- Enables a **commercial layer** (HybridOps Academy) without hiding the existence of the deeper material.
- Avoids complex role-based logic in the docs themselves; all access control is implemented by the **publishing pipeline and Academy platform**.

It also aligns with the overall ethos of HybridOps.Studio:

- Code and automation are **MIT-0** and open for reuse.
- Documentation is **CC-BY-4.0**, with some teaching-optimised content offered commercially.
- Evidence and runbooks remain structured and reproducible, even when some narrative layers are gated.

---

## 4. Consequences

### 4.1 Positive consequences

- Authors can focus on **one high-quality document** per topic, regardless of where it will be surfaced.
- Public readers see a clear, honest picture of what exists (via indexes and stubs), without being misled about the scope of the Academy.
- The Academy can offer **added value** (guided walkthroughs, deeper commentary, lab patterns) without forking the codebase.
- Assessors and hiring managers can be given **temporary or special access** to Academy material (for example via shared credentials or exports) without changing the public site.

### 4.2 Negative consequences / risks

- Build tooling becomes more complex; bugs in the pipeline could expose too much or too little content.
- Some readers may be frustrated by seeing Academy-only items in public indexes, even if stubs explain the model clearly.
- Over time, it may be tempting to push too much content into `academy`, reducing the public value of the project.

These risks are mitigated by:

- Automated tests for the docs build pipeline (for example snapshot tests on generated public docs).
- Clear labelling of academy content and CTAs.
- A governance habit: periodic review of what is public vs academy to keep the public side genuinely useful.

---

## 5. Alternatives considered

**Alternative A — Everything public, no gating**  
Rejected because it undermines the commercial viability of HybridOps Academy and makes it difficult to justify premium pricing for teaching material.

**Alternative B — Fully separate public and private repositories**  
Rejected because it introduces duplication and drift: two ADR trees, two sets of runbooks, two HOWTO libraries. This is difficult to maintain and weakens the evidence story.

**Alternative C — Ad-hoc per-page decisions with no front-matter model**  
Rejected because it is not machine-readable; automation cannot reliably build different views (public vs Academy), and the intent of each document is unclear to future maintainers.

---

## 6. Implementation notes

- All ADRs, runbooks, and HOWTOs include an `access` field and a `stub` block in front matter.
- Existing index generators (for example `gen_runbook_index.py`, HOWTO index generator, ADR index generator) are updated to:
  - Respect `template: true` and `draft: true` flags.
  - Optionally annotate academy entries (for example with a separate column or label).
- A new docs build pipeline is introduced that:
  - Reads the source Markdown files and front matter.
  - Produces a **public docs tree** for MkDocs/GitBook (with stubs where appropriate).
  - Produces an **Academy docs bundle** (HTML/Markdown) for import into Moodle or private MkDocs.
- Links from public docs to Academy use stable URLs, for example:
  - `https://academy.hybridops.studio/courses/hybridops-architect/dr-failback`

---

## 7. Operational impact and validation

Operationally, this decision affects:

- How new documentation is authored (front matter must include `access` and `stub`).
- How the docs pipeline is run (public vs Academy builds).
- How bootcamp and docs-only offerings are packaged in Moodle/Academy.

Validation patterns include:

- Automated checks to ensure all non-template documents have a valid `access` field.
- Automated checks to ensure academy documents have either a `stub.blurb` or are excluded from public builds.
- Manual review of generated public docs before major releases to confirm that:
  - Public content is rich enough for assessors, hiring managers, and engineers.
  - Academy-only stubs render cleanly with clear CTAs.
  - Evidence links (for example `docs/proof/` and `output/`) remain valid.

---

## 8. References

- Runbooks index: `../runbooks/000-INDEX.md`  
- HOWTO index: `../howto/000-INDEX.md`  
- Evidence Map: `../evidence_map.md`  
- Diagrams: `../diagrams/` (planned: docs-access-model flowchart)  
- Future ADRs that may refine this model (for example pricing, Academy packaging, or content tiers).

---

**Author / Maintainer:** Jeleel Muibi  
**Project:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation
