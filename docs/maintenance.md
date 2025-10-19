# 🧭 Repository Maintenance Guide

This document describes how all automated indexes and lists are generated across the HybridOps.Studio repository.
It is intended for maintainers, contributors, and reviewers.

> **Note:** These processes rely on simple Python scripts under `control/tools/repo/indexing/`.
> They can be run directly or through corresponding `make` targets defined in the root Makefile.

---

&nbsp;

### ADR index generation

- **Script:** `control/tools/repo/indexing/gen_adr_index.py`
- **Make target:** `make adr.index`
- **Writes:**  
  - `docs/adr/README.md` (index)  
  - `docs/adr/by-domain/*.md` (filtered by domain)
- **Expectations:**  
  - ADRs are named `ADR-xxxx_*.md`  
  - Each ADR must begin with a YAML front‑matter block.
- **Typical workflow:**
  ```bash
  make adr.index
  git add docs/adr/
  git commit -m "update ADR index"
  ```

---

&nbsp;

### Runbooks index generation

- **Script:** `control/tools/repo/indexing/gen_runbook_index.py`
- **Make target:** `make runbooks.index`
- **Writes:**  
  - `docs/runbooks/000-INDEX.md` (main index)  
  - `docs/runbooks/by-category/*.md` (filtered by category)
- **Expectations:**  
  - Each runbook begins with YAML front‑matter keys: `title`, `category`, `summary`, `severity`, `draft`, `template`  
  - `draft: true` and `template: true` entries are excluded from indexes.
- **Typical workflow:**
  ```bash
  make runbooks.index
  git add docs/runbooks/
  git commit -m "update runbook index"
  ```

---

&nbsp;

### HOWTO index generation

- **Script:** `control/tools/repo/indexing/gen_howto_index.py`
- **Make target:** `make howto.index`
- **Writes:**  
  - `docs/howto/README.md` (index)  
  - `docs/howto/by-topic/*.md` (filtered by topic)
- **Expectations:**  
  - Each HOWTO begins with YAML front‑matter keys: `title`, `topic`, `summary`, `draft`, `template`  
  - `draft: true` and `template: true` entries are excluded from indexes.
- **Typical workflow:**
  ```bash
  make howto.index
  git add docs/howto/
  git commit -m "update HOWTO index"
  ```

---

&nbsp;

### Ownership

- **ADRs:** technical lead (editor), contributors (authors)  
- **Runbooks:** SRE / operations team  
- **HOWTOs:** documentation or training contributors  
- **CI & tooling:** repository maintainers

---

**End of document.**
