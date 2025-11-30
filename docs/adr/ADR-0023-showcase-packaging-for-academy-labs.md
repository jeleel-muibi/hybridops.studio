---
id: ADR-0023
title: "Showcase packaging for Academy labs"
status: Proposed
date: 2025-11-22

domains: ["docs", "academy", "showcases"]
owners: ["HybridOps.Studio"]
supersedes: []
superseded_by: []

links:
  prs: []
  runbooks: []
  evidence: []
  diagrams: []

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---
## Context

HybridOps.Studio uses *showcases* to tell end-to-end stories about the platform:
architecture, automation and evidence. These are primarily documented under the
MkDocs tree as:

- `docs/showcases/<slug>/README.md` for the narrative; and
- auto-generated catalogue and by-audience views.

The same scenarios are also strong candidates for **Academy labs**. Lab users
need task-focused material and a stable way to run the scenarios themselves.
Previously, there was an idea to keep a separate `showcases/` tree at the repo
root, with per-showcase Makefiles, vars and scripts. This risks duplication and
drift from the canonical automation in:

- `deployment/` (environment orchestration, inventories, overlays),
- `core/` (reusable roles, modules and helpers),
- `control/` (operator tools and decision helpers),
- `ci/` (lint, render, dry-run, and pipelines).

We want:

- A **single source of truth** for automation and infrastructure definitions.
- A clean separation between **docs lenses** and **lab packaging**.
- A repeatable pattern for turning any showcase into a lab, without forking or
  re-implementing core logic.
- A clear signal in documentation that a given showcase has an Academy variant
  and where it is packaged.

## Decision

1. **No separate root `showcases/` code tree**

   There will be no dedicated `showcases/` folder at the repository root for
   holding roles, playbooks or pipelines. All automation remains in the
   existing platform folders:

   - `deployment/` for inventory, vars, overlays and orchestration;
   - `core/` for roles, collections, helpers and modules;
   - `control/` for tools, wrappers and decision artefacts;
   - `ci/` for CI/CD definitions and pipeline documentation.

2. **Showcases remain a documentation lens under `docs/showcases/`**

   Each showcase has a narrative page in the docs tree:

   ```text
   docs/showcases/<slug>/README.md
   ```

   This page:

   - tells the story (executive summary, case study, architecture);
   - links to ADRs, runbooks, briefings and CI docs;
   - links to evidence via the Evidence Map and Proof Archive;
   - advertises any associated Academy lab.

3. **Academy lab packaging lives under `deployment/academy/showcases/`**

   When a showcase is promoted to a full lab, its **packaging** (not core
   automation) lives under:

   ```text
   deployment/academy/showcases/<slug>/
   ```

   Typical contents:

   - `README.lab.md` — student-facing lab instructions (tasks, pre-reqs,
     expected outcomes);
   - `tasks/` — step-by-step task descriptions, checklists or YAML task specs;
   - `solutions/` — model answers, diff outputs, or reference scripts;
   - `overlays/` — inventory/vars overlays specific to the lab flavour of the
     scenario;
   - `files/` — any lab-only assets that do not belong in core roles or
     environment overlays.

   This folder **must not** contain independent copies of roles, core playbooks
   or pipelines. It only composes and constrains the existing platform code for
   the lab use case.

4. **Showcase README advertises the lab via `academy` front-matter**

   The showcase docs template is extended with an `academy` block, for example:

   ```yaml
   academy:
     enabled: true
     package_path: "deployment/academy/showcases/<slug>"
     lab_id: "HOS-SH-001"
     access: "academy"
   ```

   The `Academy track` section in `docs/showcases/<slug>/README.md` explains
   what the lab covers and references this packaging path and lab id.

5. **CI/CD and evidence remain platform-wide**

   Labs use the same CI/CD pipelines and evidence collection patterns as the
   rest of the platform. Where extra scripts are needed for lab ergonomics,
   they are added under appropriate `control/` tooling or `deployment/` helpers,
   not under `docs/`.

## Rationale

- **Single source of truth**  
  Keeping all automation in `deployment/`, `core/`, `control/` and `ci/`
  prevents drift between “demo code” and “real code”. Labs become thin overlays
  on top of the same system that backs the portfolio and production-style
  examples.

- **Clear separation of concerns**  
  `docs/showcases/` focuses on narrative, diagrams and links.  
  `deployment/academy/showcases/` focuses on learner tasks, overlays and
  packaging. Neither tries to duplicate the other.

- **Better story for assessors and hiring managers**  
  Assessors see that each showcase:

  - has a rigorous underlying implementation;
  - can be turned into a lab without creating a forked codebase;
  - is wired into evidence and CI/CD like the rest of the platform.

- **Scalable for Academy growth**  
  As new labs are added, they follow the same pattern. `gen_showcase_index.py`
  and the docs templates can surface which showcases have labs without
  introducing per-lab logic into the codebase.

## Consequences

### Positive

- Labs and showcases both reuse the same core building blocks.
- No duplicate roles, playbooks or pipelines under a separate `showcases/`
  tree.
- Easier maintenance: changes to environment definitions or roles automatically
  flow through to labs and demos.
- Documentation cleanly separates story (docs) from lab packaging
  (`deployment/academy/showcases/`).
- Future Academy-specific tooling (for example lab launchers or grading scripts)
  can target the `deployment/academy/showcases/` structure consistently.

### Negative / trade-offs

- There is no single `showcases/` folder that can be zipped and shipped as a
  standalone bundle without additional tooling. Packaging a lab for external
  delivery may require a dedicated script or export process.
- Lab authors must understand the platform layout (deployment/core/control/ci)
  rather than working in a completely isolated mini-project.
- Some scenarios may need care to avoid putting large artefacts in the docs
  tree; heavy artefacts remain in proof/evidence locations and are only linked
  from showcase READMEs.

## Options considered

1. **Dedicated `showcases/` project tree at repo root**  
   Rejected due to duplication risk, maintenance overhead and drift from
   canonical automation.

2. **Labs implemented only as docs (Markdown + copy-paste commands)**  
   Rejected as too weak: lacks structured packaging, overlays and solution
   material for serious Academy use.

3. **Academy packaging under `deployment/academy/showcases/` (chosen)**  
   Balances re-use of existing automation, clarity of structure and room for
   future tooling.

## Follow-up actions

- Update the showcase README template to include the `academy` front-matter
  block and refined `Academy track` section.
- Create an initial example lab package under
  `deployment/academy/showcases/<slug>/` to validate the pattern end-to-end.
- Extend internal documentation for lab authors to reference this ADR and
  provide a checklist for new labs.
- Optionally, add a small CI smoke test that validates the presence and basic
  structure of `deployment/academy/showcases/*` packages.
