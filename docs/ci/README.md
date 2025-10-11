# CI Overview

HybridOps.Studio uses two CI paths:
- **GitHub Actions** — linting, static checks, lightweight renders, and dry‑runs.
- **Jenkins** — environment‑aware plans/applies and end‑to‑end flows (Ansible ↔ Terraform ↔ GitOps).

**Standards**
- Non‑destructive by default (`plan`, `--check`, `--diff`).
- Artifacts stored under `out/` (logs) and `out/artifacts/` (exports) for auditability.
- Secrets are injected via CI secret stores (never committed).
- Evidence (screenshots/JSON) is curated under `docs/proof` and linked from the Evidence Map.

**References**
- [GitHub Actions](./github-actions.md)
- [Jenkins](./jenkins.md)
