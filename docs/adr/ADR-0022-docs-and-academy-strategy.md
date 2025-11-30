---
id: ADR-0022
title: "Documentation, Public Site, and Academy Strategy"
status: Accepted
date: 2025-11-19
domains: ["docs", "academy", "platform"]
owners: ["HybridOps.Studio"]
supersedes: []
superseded_by: []
links:
  prs: []
  runbooks:
    - "../runbooks/000-INDEX.md"
  evidence:
    - "../evidence_map.md"
  diagrams:
    - "../diagrams/flowcharts/docs-academy-strategy.drawio"
    - "../diagrams/flowcharts/docs-academy-strategy.png"
access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# ADR-0022 — Documentation, Public Site, and Academy Strategy
**Status:** Accepted  
**Domain(s):** docs, academy, platform  
**Owner(s):** HybridOps.Studio  
**Last updated:** 2025-11-19  

---

## Context

HybridOps.Studio is both:

- A hybrid-cloud automation blueprint (Proxmox/VMware, Azure, GCP, and later AWS).
- The basis for commercial offerings:
  - A Docs Library product (deep ADRs, runbooks, HOWTOs, and lab guides).
  - A HybridOps Academy bootcamp and supporting courses (for example CCNA, AZ-104, CKAD-style training anchored in the same ecosystem).

This creates overlapping but distinct audiences:

- Public engineers and community users who want enough detail to trust and reuse the patterns.
- Assessors and hiring managers who need clear evidence, ADRs, and runbooks without reading the full tree.
- Academy learners who pay for a structured, lab-grade learning experience with walkthroughs and support.
- The maintainer, who must keep everything maintainable as a solo owner.

Earlier iterations experimented with `docs-public/` and ad-hoc exposure decisions. That does not scale and makes it unclear which documents are authoritative or how to separate free vs premium content. A deliberate strategy is required for:

- Where documentation lives in the repo.
- What is public vs academy-only.
- How the public docs, Academy, and Moodle interact.
- How to avoid duplication and copy-paste as ADRs, runbooks, and HOWTOs grow.

## Decision

### Single documentation tree with explicit access metadata

- All documentation lives under the main `docs/` tree (plus `showcases/` at the repository root).
- Each document uses front matter with an `access` field, for example:

  ```yaml
  ---
  title: "DR Failback to On-Prem"
  category: dr
  access: public   # or academy, or mixed (later)
  ---
  ```

- Access semantics:

  - `public`  
    - Included in public documentation builds.  
    - Fully visible on `docs.hybridops.studio`.

  - `academy`  
    - Listed in public indices (ADRs, runbooks, HOWTOs) but not fully rendered.  
    - In public builds, the body is replaced by a short stub that links to the Academy.

  - `mixed` (optional later)  
    - Public builds show an overview or trimmed version.  
    - Academy builds render the full teaching version.

- Existing index generators (for example runbooks index, evidence map, future ADR index) are extended to read and surface `access` metadata.

### Public documentation: MkDocs on `docs.hybridops.studio`

- The public documentation site is built with MkDocs (Material theme or similar) and served at:

  - `https://docs.hybridops.studio`

- The public MkDocs build:

  - Uses `docs/` as the source.
  - Renders the landing page, Quickstart, guides, public HOWTOs, runbook indices, ADR indices, and proof/evidence overviews.
  - Includes all items in ADR / runbook / HOWTO indices, but:
    - For `access: public`, shows full content.
    - For `access: academy`, shows a stub with a short description and a link to the relevant Academy URL (opened in a new tab).

- The public docs are positioned as an internal-style documentation site rather than a marketing site. They act as:

  - The primary reference for engineers, assessors, and hiring managers.
  - Context and entry points into the Academy and commercial offerings.

### Academy documentation: separate MkDocs build deployed to the Moodle VM

- A separate MkDocs configuration (for example `mkdocs.academy.yml`) is introduced with:

  - `docs_dir: build/docs_academy`
  - `site_dir: site_academy`

- A generator script (for example `scripts/gen_docs_academy.py`) builds the Academy documentation tree by:

  - Reading from the `docs/` sources.
  - Filtering by `access` (`academy` and, later, `mixed`).
  - Optionally enriching content with additional lab notes and walkthroughs.

- CI then:

  1. Runs the generators (runbook index, ADR index, evidence map, Academy docs tree).
  2. Builds the Academy site with MkDocs using the Academy configuration.
  3. Deploys the generated static site to the Moodle VM over SSH/rsync, for example into `/var/www/academy-docs`.

- The Academy docs are served via a dedicated vhost, for example:

  - `https://academy-docs.hybridops.studio`  
  - or a path under `https://academy.hybridops.studio/docs/`

- Access control for Academy docs is enforced via Moodle (course enrolment) and/or HTTP auth / SSO in front of the Academy vhost.

### Moodle as gatekeeper for premium access

- Moodle is the authoritative system for:

  - Enrolment in the Docs Library course.
  - Enrolment in the HybridOps Architect bootcamp and future courses.
  - Enforcing which learners can see premium teaching materials.

- Product flows:

  1. Docs Library product  
     - Learners enrol in a “Docs Library” course.  
     - The course exposes structured access to premium ADRs, runbooks, and HOWTOs with deep links or iframes into the Academy docs site.

  2. Bootcamp product  
     - Learners enrol in the Bootcamp course, which includes:
       - Sessions, videos, labs, quizzes, and capstone.
       - Access to the Docs Library course as part of the bundle.

- From public docs:

  - Stubs for `access: academy` items link to canonical Academy URLs, for example:

    ```markdown
    [View full runbook on HybridOps Academy](https://academy.hybridops.studio/courses/docs-library/dr-failback){ target=_blank }
    ```

  - Moodle decides per user:

    - Not logged in or not enrolled → show login or enrolment/checkout page.  
    - Enrolled in Docs Library or Bootcamp → show full content.

### Public code vs premium teaching material

- The codebase (Terraform modules, Ansible collections, Nornir scripts, CI pipelines and so on) remains public with a permissive licence (MIT-0).

- Teaching material (Academy-level ADRs, runbooks, HOWTOs, lab guides, walkthroughs, and videos) is monetised and gated by:

  - Using `access: academy` front matter and excluding full content from public builds.
  - Mapping Academy documents to Moodle courses and products.

This allows HybridOps.Studio to function simultaneously as:

- A credible, inspectable public portfolio.
- A reusable technical framework for engineers.
- A commercial education and consulting platform.

## Decision Drivers

- Single source of truth  
  One documentation tree (`docs/`) with explicit metadata is easier to maintain than multiple overlapping trees (`docs/` and `docs-public/`).

- Monetisation model  
  Deep, lab-grade teaching content has standalone value; it should be monetised through a Docs Library and Bootcamp product, while code and basic understanding remain public.

- Portfolio and assessor needs  
  Assessors and hiring managers must be able to see that the work is substantial, structured, and maintained, even if some details are gated.

- Operational maintainability  
  The maintainer must be able to use generators and CI to keep indices, evidence maps, and Academy builds up-to-date without hand-editing dozens of files.

- Tooling cost and flexibility  
  MkDocs and Moodle, combined with custom generators, provide more control and lower recurring cost than a fully hosted docs and learning platform.

## Consequences

### Positive

- Clear structure  
  There is a single documentation tree with explicit `access` metadata. Public and Academy docs are two views over the same source, not separate documentation silos.

- Strong portfolio posture  
  Public indices show the breadth of ADRs, runbooks, and HOWTOs. Gated content is visible as a concept while preserving the value of the Academy products.

- Monetisation-ready  
  It is straightforward to define “Docs Library” and Bootcamp SKUs in Moodle and map them to concrete sets of premium documents, runbooks, and lab guides.

- Automation-friendly  
  Existing and future generators can read front matter, add access columns, and emit both public and Academy views. CI can automate both builds and deployments.

### Negative / trade-offs

- Higher initial complexity  
  Two MkDocs configurations, generator scripts, and the Moodle integration are more complex than a single static docs site.

- Expectation management for public users  
  Public indices will list items that are Academy-only. Messaging has to be clear that some documents are part of a paid Docs Library or Bootcamp.

- Additional operational integration  
  Payment and enrolment flows (for example Stripe → Moodle) will require further design and implementation outside this ADR.

## Implementation Notes

- Introduce or extend a shared front-matter schema that includes `access` for ADRs, runbooks, HOWTOs, and guides.

- Update index generators (for example `gen_runbook_index.py`, ADR index, and evidence map) to:
  - Parse `access`.
  - Include an Access column where appropriate.
  - Optionally emit Academy URLs or keys that map to Moodle course content.

- Add an Academy MkDocs configuration (`mkdocs.academy.yml`) and a generator script (`scripts/gen_docs_academy.py`) that builds `build/docs_academy` from `docs/` based on `access` values.

- Extend CI to:
  - Run all documentation generators.
  - Build the public docs site and deploy to `docs.hybridops.studio`.
  - Build the Academy docs site and deploy over SSH/rsync to the Moodle VM.

- Use Moodle to:
  - Define at least two courses:
    - Docs Library.
    - HybridOps Architect Bootcamp.
  - Gate access to Academy URLs or embedded Academy docs based on enrolment.

## References

- Runbooks: [Runbooks Index](../runbooks/000-INDEX.md)  
- Evidence: [Evidence Map](../evidence_map.md)  
- Showcases: [Showcases Overview](../showcases/README.md)  
- Diagrams: [Docs and Academy Strategy](../diagrams/flowcharts/docs-academy-strategy.png)  
- Repository-wide documentation notes: [Docs Landing Page](README.md)

---

**Author / Maintainer:** HybridOps.Studio (Jeleel Muibi)  
**Project:** HybridOps.Studio  
**Licence:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
