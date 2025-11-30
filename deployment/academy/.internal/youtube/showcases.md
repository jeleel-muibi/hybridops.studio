# Showcases — How They Sit on Top of Deployment

Short, reproducible demos that **use the production‑style pipeline** instead of duplicating it. Each showcase is now primarily a *documentation lens* that points to the canonical automation in **Deployment/Core/Control**, and curates the story and evidence for reviewers.

---

## Roles of the main folders (at a glance)

- **Deployment** — environment‑specific playbooks, inventories, and GitOps overlays that do the real work. See **[Deployment Guide](../../deployment/README.md)**.
- **Core** — reusable building blocks: the Ansible collection, Python helpers, and the PowerShell module. See **[Core Overview](../../core/README.md)**.
- **Control** — operator wrappers and decision tooling. See **[Control](../../control/README.md)**.
- **Showcases (docs layer)** — curated scenarios under `docs/showcases/` that *reference* Deployment/Core/Control and evidence. See the **[Showcase Catalogue](../../showcases/README.md)**.

> Principle: **one implementation, many demos.** Showcases do not carry their own roles, playbooks or pipelines; they link to the ones in Deployment/Core/Control and surface the narrative plus a small set of curated artefacts.

---

## Where showcases live

Showcases are documented under the docs tree:

```text
docs/showcases/
  <slug>/
    README.md        # narrative page that MkDocs renders
    diagrams/        # architecture / flow diagrams for the story
    screenshots/     # UI or dashboard screenshots
```

The README for each showcase is what assessors and hiring managers will see. It explains:

- What the scenario proves.
- How it relates to the platform architecture.
- Which ADRs, runbooks and evidence back it.
- Where to find the underlying automation in Deployment/Core/Control.

All **implementation** (Terraform, Ansible, scripts, pipelines) remains in the main folders:

- `deployment/` — environment orchestration, inventories, GitOps overlays.
- `core/` — roles, collections, helpers.
- `control/` — operator tools, decision helpers, wrappers.
- `ci/` — linting, rendering, dry‑runs and pipeline orchestration.

The showcase docs simply point into these locations.

---

## Quick start — create a new showcase (docs side)

1) **Pick a slug**

Decide on a slug that will be used in both docs and links, for example:

- `ci-cd-pipeline`
- `dr-failover-to-cloud`
- `network-automation`

2) **Create the docs folder**

```bash
mkdir -p docs/showcases/my-new-demo/{diagrams,screenshots}
```

3) **Create `docs/showcases/my-new-demo/README.md`**

Use the showcase README template and fill in:

- Executive summary (what this proves and why it matters).
- Case study narrative (context → challenge → approach → outcome).
- Architecture diagrams from `diagrams/`.
- Links to ADRs, runbooks and decision briefings.
- Links to GitHub folders under `deployment/`, `core/`, `control/`.
- Links into the Evidence Map / Proof Archive.

4) **Wire it into the catalogue**

Once the README exists with proper front matter (including `audience:`), the docs index tooling:

- Adds it to **[Showcase Catalogue](../../showcases/README.md)**.
- Includes it in the **By Audience** views under `docs/showcases/by-audience/`.

No extra Makefiles or code are required under `docs/showcases/`.

---

## Connecting a showcase to the implementation

A good showcase README should answer:

- **Where is the automation?**
  - Point to `deployment/` playbooks and overlays.
  - Point to roles or helpers in `core/`.
  - Point to wrappers or decisions in `control/`.
  - Point to CI pipelines that exercise the scenario.

- **Where is the evidence?**
  - Reference the relevant entries in the **[Evidence Map](../../evidence_map.md)**.
  - Link to canonical proofs in the Proof Archive (for example `docs/proof/...`).
  - Optionally embed a small, curated subset of screenshots/exports directly under `docs/showcases/<slug>/`.

This keeps the docs thin while still giving reviewers a direct path to “how this works in the real system”.

---

## Passing scenario variables and secrets

The patterns for variables and secrets remain the same:

- **Scenario values** (regions, DNS suffixes, feature toggles) are defined under `deployment/` inventories or vars files and reused across scenarios. If a scenario needs a special toggle, document it in the showcase README and keep the value in the appropriate `deployment/` vars file.

- **Secrets** (tokens, keys) are never documented in showcases or committed under docs. They are sourced via:
  - CI secrets,
  - Ansible Vault,
  - or cloud‑native secret stores, as designed in the platform.

For the operational details, see **[Runbooks](../../runbooks/README.md)** and the secrets section of the technical architecture briefing.

---

## Evidence collection (what to surface from docs)

The heavy‑weight artefacts stay in the operational folders; showcases surface a curated view.

Typical evidence sources:

- **Ansible run logs** — for example `output/artifacts/ansible-runs/<domain>/*.log`.
- **Terraform state/outputs (redacted)** — for example `output/terraform/*.json`.
- **Screenshots / exports** — Grafana panels (JSON + PNG), NetBox exports, decision artefacts.
- **GitOps / cluster health** — `kubectl get` snapshots saved as text.

From these, you can:

- Link to canonical proofs via the **[Proof Archive](../../proof/README.md)**.
- Embed selected screenshots or diagrams directly into `docs/showcases/<slug>/` so that the narrative page is self‑explanatory.

The goal is to let reviewers see enough to trust the story, while keeping the full raw artefacts in the dedicated proof/evidence structures.

---

## Where “API calls” fit

You are already using cloud/device APIs via **Terraform providers** and **Ansible modules**. Only add direct API code when a provider/module cannot express the operation you need.

When that happens:

- **Reusable integration** → implement as a custom Ansible module or helper under **Core** (for example `core/ansible/.../plugins/modules/`), and document its use in the relevant showcase README.
- **Demo‑only probe** → a small script under an appropriate location in `control/` or a tool wrapper, and reference it from the showcase README. Avoid putting executable scripts under `docs/showcases/`.

Examples and patterns are described in the **[CI Overview](../../ci/README.md)**, which shows how inventory rendering and dry‑runs are automated without hard‑coding secrets.

---

## Guardrails

- No roles/playbooks or runtime automation under `docs/showcases/`; only Markdown, diagrams, screenshots and links.
- All logs and heavy artefacts stay under `output/` / proof directories, not in `deployment/` and not duplicated under docs.
- Use descriptive links in docs (no raw paths in link text).
- Prefer root Make targets and CI pipelines over ad‑hoc commands in documentation examples.
- Keep inventories and vars under `deployment/inventories/` or relevant deployment vars files; the showcase docs should point to them, not re‑define them.

---

## Useful pointers

- Deployment entry points — **[Deployment Guide](../../deployment/README.md)**
- Core roles & helpers — **[Core Overview](../../core/README.md)**
- Operator wrappers — **[Control](../../control/README.md)**
- Run procedures — **[Runbooks](../../runbooks/README.md)**
- Claims → proofs — **[Evidence Map](../../evidence_map.md)**
- CI (lint, render, dry‑run) — **[CI Overview](../../ci/README.md)**

_Last updated: 2025‑10‑08 (UTC)_
