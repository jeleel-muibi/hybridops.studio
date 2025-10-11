# Maintenance Guide

This guide defines what must stay current in the repository and the lightweight automation that keeps ADR and runbook indexes in sync.

---

## Items That Must Stay Up to Date

Automation keeps ADR and runbook indexes synchronized; other areas require periodic review.

- **Root** — `README.md`, `Makefile`, `LICENSE`, `NOTICE`
- **Docs overview** — `docs/README.md`; diagrams under `docs/diagrams/**`; social preview in `docs/diagrams/flowcharts/renders/`
- **Evidence** — `docs/evidence_map.md`; proof archive in `docs/proof/**`
- **Runbooks** — `docs/runbooks/**` (see _Automation → Runbooks index generation_)
- **Architecture decisions** — `docs/adr/**` (see _Automation → ADR index and by-domain pages_)
- **GitOps** — `deployment/gitops/{base,apps,overlays/**}`
- **Terraform** — `terraform-infra/**` (providers pinned; backends configured; `*.tfvars.example` present)
- **Ansible** — `core/ansible/**` (roles/playbooks referenced by runbooks and demos)
- **Decision Service** — `core/python/libhybridops/decision/**` (policies and inputs)
- **Output** — `output/**` (artifacts, logs, exported evidence; _no secrets_)

---

## Automation

### ADR index and by-domain pages

- **Script:** `control/tools/repo/indexing/gen_adr_index.py`
- **Make target:** `make adr.index`
- **Writes:**
  - `docs/adr/README.md` (index)
  - `docs/adr/by-domain/*.md` (filtered views)
- **Expectations:** ADR files live in `docs/adr/` as `ADR-XXXX_<slug>.md` with YAML front matter: `id`, `title`, `status`, `decision_date`, and `domain` **or** `domains` (one or more). Optional: `tags`. Use `draft: true` until finalized.

**Workflow**

```bash
# Create a new ADR from template and regenerate indexes
cp docs/adr/TEMPLATE.md docs/adr/ADR-0005_<topic>.md
make adr.index
```

---

### Runbooks index generation

- **Script:** `control/tools/repo/indexing/gen_runbook_index.py`
- **Make target:** `make runbooks.index`
- **Writes:**
  - `docs/runbooks/000-INDEX.md` (table with legend and category navigation)
  - `docs/runbooks/by-category/*.md` (category lists)
  - Updates the block in `docs/runbooks/README.md` between: `<!-- RUNBOOKS:INDEX START -->` … `<!-- RUNBOOKS:INDEX END -->`
- **Expectations:** Runbooks reside under `docs/runbooks/<category>/<file>.md` with categories such as `bootstrap`, `dr`, `burst`, `ops`. Front matter includes `title`, `category`, optional `severity` (`P1|P2|P3`), and optional flags `draft: true`, `template: true`. The generator derives `last_updated` from file mtime when omitted.

**Workflow**

```bash
# Create a new runbook from template and regenerate indexes
cp docs/runbooks/runbook_template.md docs/runbooks/dr/dr_cutover.md
make runbooks.index
```

---

## Release Checklist

- Diagrams and overview pages current; social preview renders up to date.
- Evidence Map links verified; new screenshots/exports added under `docs/proof/**`.
- Runbooks reviewed; `make runbooks.index` executed.
- ADRs reviewed; `make adr.index` executed.
- Lint/format checks pass in CI (Ansible/YAML/Terraform); `make fmt` applied for Terraform.
- Makefile targets for showcases and domains run clean (`make help` enumerates targets).
- Secrets are absent from the repository; tokens stored as CI secrets or local `.env` files.

---

## Responsibilities

- **Documentation & evidence:** documentation maintainers
- **Runbooks:** platform SRE (primary), DB SRE / NetOps (contributors)
- **ADRs:** technical lead (editor), contributors (authors)
- **CI & tooling:** repository maintainers

---

_Last updated: 2025-10-11 (UTC)_
