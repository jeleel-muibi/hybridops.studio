# Showcases — How They Sit on Top of Deployment

Short, reproducible demos that **use the production‑style pipeline** instead of duplicating it. Each showcase is a thin wrapper that calls the canonical targets from **Deployment**, collects evidence, and tells the story for reviewers.

---

## Roles of the main folders (at a glance)

- **Deployment** — environment‑specific playbooks, inventories, and GitOps overlays that do the real work. See **[Deployment Guide](../deployment/README.md)**.
- **Core** — reusable building blocks: the Ansible collection, Python helpers, and the PowerShell module. See **[Core Overview](../core/README.md)**.
- **Control** — operator wrappers and decision tooling. See **[Control](../control/README.md)**.
- **Showcases** — curated scenarios that *invoke* Deployment/Control and then surface diagrams + evidence. See the **[Showcase Catalog](../showcases/README.md)**.

> Principle: **one implementation, many demos.** Showcases don’t carry roles or playbooks; they call the ones in Deployment/Core.

---

## Typical showcase layout

```
showcases/
  <name>/
    README.md              # What the demo proves and how to run it
    Makefile               # `make demo` calls root Make targets
    vars/                  # (optional) scenario overrides passed with -e @vars/*.yml
    diagrams/              # (optional) extra diagrams for the story
    scripts/               # (optional) demo-only helpers (no secrets here)
    evidence/              # copied from output/ after a run
```

**Why this layout?**
- Keeps the operational pipeline in one place (**Deployment**).
- Lets you present a scenario without re‑implementing anything.
- Makes artifact curation easy: copy from **`output/`** → **`evidence/`**.

---

## Quick start — create a new showcase

1) **Create the folder**

```bash
mkdir -p showcases/my-new-demo/{vars,diagrams,scripts,evidence}
```

2) **Add a minimal Makefile** (routes to the repo root Make targets)

```make
# showcases/my-new-demo/Makefile
SHELL := /usr/bin/env bash
ROOT ?= $(shell git rev-parse --show-toplevel 2>/dev/null || echo ../..)

INV ?= $(ROOT)/deployment/inventories/bootstrap/hosts.ini
VARS ?= $(ROOT)/showcases/my-new-demo/vars/demo.env.yml

.PHONY: demo evidence clean

demo: ## Run the demo end-to-end using canonical targets
	$(MAKE) -C $(ROOT) sanity env.setup
	ANSIBLE_INVENTORY=$(INV) 	$(MAKE) -C $(ROOT) dr.db.promote dr.cluster.attach dr.gitops.sync dr.dns.cutover

evidence: ## Copy artifacts from output/ to this showcase's evidence/
	mkdir -p evidence
	rsync -a --delete $(ROOT)/output/ evidence/

clean:
	rm -rf evidence
```

3) **Write `README.md`** with: goal, commands, what to look for (dashboards, timings), and links back to the Evidence Map.

> Tip: in the repo root you can also run `make showcase.my-new-demo.demo` thanks to the **showcase router** entries in the root Makefile.

---

## Passing scenario variables and secrets

- **Scenario values** (e.g., region, DNS suffix, feature toggles): commit under the showcase in `vars/*.yml` and pass with `-e @vars/<file>.yml` from your Makefile or wrapper.
- **Secrets** (tokens, keys): never commit. Source them via CI secrets or Ansible Vault inventories in **Deployment**. See **[Runbooks](./runbooks/README.md)** for the bootstrap flow and **[Technical Architecture › Secrets](./briefings/technical_architecture.md#secrets-management)** for design.

---

## Evidence collection (what to copy)

After a run, copy these for reviewers:

- **Ansible run logs** — `output/artifacts/ansible-runs/<domain>/*.log`
- **Terraform state/outputs (redacted)** — `output/terraform/*.json`
- **Screenshots / exports** — Grafana panels (JSON + PNG), NetBox exports, decision JSONs
- **GitOps / cluster health** — `kubectl get` snapshots saved as text

Organize them under the showcase **`evidence/`** and also curate canonical proofs in the **[Proof Archive](./proof/README.md)**. Cross‑link from the **[Evidence Map](./evidence_map.md)**.

---

## Where “API calls” fit

You are already using cloud/device APIs via **Terraform providers** and **Ansible modules**. Only add direct API code when a provider/module can’t express the operation you need:

- **Reusable integration** → a custom Ansible module under **Core** (e.g., `core/ansible/.../plugins/modules/`).
- **Demo‑only probe** → a small script under the showcase’s `scripts/` and feed it vars from inventory/`-e @vars/*.yml`.

Examples to reference: **[CI Docs](./ci/README.md)** show how inventory rendering and dry‑runs are automated without hard‑coding secrets.

---

## Guardrails

- No roles/playbooks in showcases; **only** wrappers, vars, and docs.
- All logs/artifacts go under **`output/`** (never inside `deployment/`).
- Use **descriptive links** in docs (no raw paths in link text).
- Prefer **root Make targets** (namespaced) over calling tools directly.
- Keep **inventories** under `deployment/inventories/` and **vars** either in Deployment or under the showcase when scenario‑specific.

---

## Useful pointers

- Deployment entry points — **[Deployment Guide](../deployment/README.md)**
- Core roles & helpers — **[Core Overview](../core/README.md)**
- Operator wrappers — **[Control](../control/README.md)**
- Run procedures — **[Runbooks](./runbooks/README.md)**
- Claims → proofs — **[Evidence Map](./evidence_map.md)**
- CI (lint, render, dry‑run) — **[CI Overview](./ci/README.md)**

_Last updated: 2025‑10‑08 (UTC)_
