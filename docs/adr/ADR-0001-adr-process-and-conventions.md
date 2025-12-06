---
id: ADR-0001
title: "ADR Process & Conventions"
status: Accepted
date: 2025-10-05

category: "00-governance"
supersedes: []
superseded_by: []

links:
  prs: []
  runbooks: []
  howtos: []
  evidence: []
  diagrams: []

draft: false
tags: ["adr", "governance", "documentation", "conventions"]
access: public
---

# ADR Process & Conventions

## 1. Purpose

Architectural Decision Records (ADRs) capture **why** HybridOps.Studio is designed the way it is.

They provide:

- A durable log of key technical decisions.
- Context and rationale for future maintainers and assessors.
- Cross-links to runbooks, HOWTOs, and proof artefacts.

ADRs are **not** general documentation. They are focused, decision-centric documents.

---

## 2. When to Write an ADR

Create or update an ADR when:

- You introduce or change a significant architectural pattern (networking, security, DR, CI/CD, etc.).
- A decision affects multiple components, environments, or repositories.
- The decision carries risk, cost, or long-term impact.
- You need a stable reference you can link to from runbooks, HOWTOs, or evidence.

You generally **do not** need an ADR for:

- Small refactors with no change in behaviour.
- Purely cosmetic changes.
- One-off experiments that are not part of the supported blueprint.

---

## 3. ADR Lifecycle & Status Values

Each ADR uses a `status` field to indicate where it is in its lifecycle:

- `Proposed` – Draft; under consideration; may change significantly.
- `Accepted` – Agreed pattern; should be implemented and followed.
- `Deprecated` – Still documented but no longer recommended for new work.
- `Superseded` – Replaced by a newer ADR; keep for historical context.
- `Rejected` – Considered but not adopted; recorded to avoid re‑discussion.

### Updating Status

- When accepting a proposal, set `status: Accepted` and update `supersedes` / `superseded_by` as needed.
- When deprecating or superseding, always update **both** ADRs:
  - Older ADR: add `superseded_by: ["ADR-XXXX"]`.
  - Newer ADR: add `supersedes: ["ADR-YYYY"]`.

All changes go through normal Git flow (branch + PR), so history is auditable.

---

## 4. ADR ID & Numbering Convention

ADRs follow a **category-based numeric scheme** so that IDs convey both area and sequence.

### 4.1 ID Format

`ADR-CCNN`

- `ADR` – Fixed prefix.
- `CC` – Category code (00–09).
- `NN` – Sequence within category (01–99).

Example: `ADR-0105` → category **01-networking**, sequence **05**.

### 4.2 Category Codes

| Code | Category              | Range              | Examples                        |
|------|-----------------------|--------------------|---------------------------------|
| 00   | Governance & Process  | ADR-0001–ADR-0099  | ADR-0001                        |
| 01   | Networking            | ADR-0101–ADR-0199  | ADR-0101, ADR-0105, ADR-0108    |
| 02   | Platform              | ADR-0201–ADR-0299  | ADR-0201                        |
| 03   | Security              | ADR-0301–ADR-0399  | ADR-0301                        |
| 04   | Observability         | ADR-0401–ADR-0499  | ADR-0401                        |
| 05   | Data & Storage        | ADR-0501–ADR-0599  | (reserved)                      |
| 06   | CI/CD & Automation    | ADR-0601–ADR-0699  | ADR-0602                        |
| 07   | Disaster Recovery     | ADR-0701–ADR-0799  | (reserved)                      |
| 08   | Cost Optimisation     | ADR-0801–ADR-0899  | (reserved)                      |
| 09   | Compliance            | ADR-0901–ADR-0999  | (reserved)                      |

### 4.3 File Naming Pattern

ADRs live under `docs/adr/` with filenames:

`ADR-<CCNN>-<descriptive-slug>.md`

Examples:

- `ADR-0101-vlan-allocation-strategy.md`
- `ADR-0102-proxmox-intra-site-core-router.md`
- `ADR-0105-dual-uplink-ethernet-wifi-failover.md`
- `ADR-0401-unified-observability-prometheus.md`

The `id` in frontmatter and the filename **must** match.

---

## 5. ADR Frontmatter

Each ADR starts with YAML frontmatter:

```yaml
---
id: ADR-0101
title: "VLAN Allocation Strategy"
status: Accepted
date: 2025-11-30

category: "01-networking"
supersedes: []
superseded_by: []

links:
  prs: []
  runbooks: []
  howtos: []
  evidence: []
  diagrams: []

draft: false
tags: ["vlan", "network-segmentation"]
access: public
---
```

Guidelines:

- `id` – Must follow `ADR-CCNN` scheme.
- `title` – Short, decision‑focused, sentence case.
- `category` – Mirrors the category code (`"01-networking"`, `"04-observability"`, etc.).
- `owners` – GitHub handle or name of the accountable owner(s).
- `links` – Optional helper arrays; use them when specific PRs, diagrams or evidence artefacts exist.
- `draft` – `true` for work in progress; `false` once ready for review or accepted.
- `access` – Typically `public` unless a private fork is required.

---

## 6. ADR Content Structure

Within the body of the ADR, follow a consistent outline:

1. **Context** – What problem are we solving? What constraints or drivers exist?  
2. **Decision** – The chosen approach, written clearly and unambiguously.  
3. **Rationale** – Why this option over alternatives; trade-offs and reasoning.  
4. **Consequences** – Positive, negative, and neutral outcomes.  
5. **Implementation** – High-level notes on where this shows up (modules, playbooks, topologies).  
6. **References** – Links to related ADRs, runbooks, HOWTOs, diagrams, and proof paths.

Not every section must be long, but every **Accepted** ADR should address each one explicitly.

### Style Guidelines

- Use short paragraphs and bullet points.
- Prefer concrete statements over vague intentions.
- Keep ADRs **technology-agnostic where reasonable**, but be precise when the product choice is part of the decision.
- Cross-link related ADRs, runbooks, and HOWTOs so readers can follow the reasoning chain.

---

## 7. Relationship to Runbooks, HOWTOs, and Evidence

ADRs are the **source of truth for decisions**, not step-by-step guides.

- **Runbooks** – Operational checklists for incidents, maintenance, and routine tasks.  
  - Example: `docs/runbooks/networking/dual-isp-loadbalancing.md` (executes ADR‑0106).

- **HOWTOs** – Teaching guides and walk-throughs for learning and practising the pattern.  
  - Example: `docs/howtos/HOWTO_dual-isp-pfsense-csr.md` (demonstrates ADR‑0106).

- **Evidence / proof** – Logs, screenshots, metrics, and artefacts that show the decision in action.  
  - Example: `docs/proof/networking/dual-isp-tests/`.

ADRs should **reference** these where helpful, but must remain readable even if a reader does not open every link.

---

## 8. Storage, Indexing, and Tooling

- ADRs live under `docs/adr/` in the Git repository.
- A Python script (ADR index generator) builds an index grouped by category and status.
- The public and academy documentation trees include an ADR index page for navigation.

The index generator relies on:

- `id`, `title`, `status`, `category`, and `access` fields.
- Filenames following the `ADR-CCNN-slug.md` pattern.

When creating a new ADR, ensure these fields are present and correct so that:

- The index remains stable.
- MkDocs navigation is generated deterministically.
- Filtering by category/status works as expected.

---

## 9. Working with ADRs Day-to-Day

**Creating a new ADR**

1. Copy the ADR template: `docs/adr/ADR_template.md`.  
2. Choose the next free ID in the appropriate category (e.g. `ADR-0109`).  
3. Fill in `Context`, `Decision`, `Rationale`, and initial `Consequences`.  
4. Open a PR and request review.  
5. Once agreed, set `status: Accepted` and merge.

**Updating an existing ADR**

- Small clarifications: update text directly with a clear commit message.  
- Behavioural change or reversal: create a new ADR that supersedes the old one and update `supersedes` / `superseded_by` links accordingly.

**Retiring an ADR**

- Mark as `Deprecated` or `Superseded` (do **not** delete the file).
- Add a brief note in `Context` or `Decision` to explain the transition.

---

## 10. Benefits

By following this process, HybridOps.Studio ensures that:

- Architectural reasoning is explicit, reviewable, and discoverable.
- Major decisions are easy to trace from ADR → runbook → evidence → diagrams.
- Assessors can quickly understand both the **design intent** and the **operational reality**.

---

**Maintainer:** HybridOps.Studio
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
