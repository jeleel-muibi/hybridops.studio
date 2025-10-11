# Contributing (Portfolio Policy)

**HybridOps.Studio** is a public, evidence‑backed portfolio. To keep the project stable and reviewable, **external pull requests are not accepted**. You are welcome to open **issues** for clarifications, documentation fixes, or questions.

- **Reuse:** Roles/modules are published separately (Ansible Galaxy / Terraform Registry) or scaffolded under **contrib**. See **contrib/README.md** for how to publish your own copies.
- **Forks:** The code is MIT‑0. Fork and adapt for your environment; attribution is appreciated.
- **Security:** Please follow **SECURITY.md** for reporting vulnerabilities.

---

## For maintainers (internal)

### Workflow
- **Default branch:** `main`
- **Branches:** `feat/<scope>-<desc>` or `fix/<scope>-<desc>`
- **Commits:** Conventional style welcome (`feat:`, `fix:`, `docs:`), not mandatory.
- **PRs:** Maintainers only.

### Local setup
```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```
Recommended toolchain: Terraform ≥ 1.5, Ansible ≥ 2.12, kubectl, yamllint, ansible-lint, molecule, tflint, tfsec.

### CI (GitHub Actions)
- Terraform fmt/validate (+ optional security scan)
- Ansible lint + yamllint
- Molecule for roles that define scenarios
- GitOps kustomize dry‑run
- Optional: NetBox inventory render (dry‑run)

> Configs live under `.github/workflows/` and `.config/linters/` to keep the repo root tidy.

### Secrets & credentials
- Never commit secrets. Use environment variables, GitHub Secrets, or local `.env` files (git‑ignored).
- Scope tokens minimally (NetBox/cloud/WAL‑G). Prefer on‑prem Jenkins for local runs; GitHub Secrets for CI.
- For Kubernetes, prefer Sealed/External Secrets with cloud KMS. See ADR‑0003.

### Repository layout (high level)
- `deployment/` — runnable playbooks, inventories, GitOps overlays, orchestration
- `terraform-infra/` — environment roots, shared providers, modules
- `core/` — reusable roles/modules (Ansible, decision service)
- `docs/` — briefings, diagrams, Evidence Map, Proof Archive, runbooks, ADRs
- `showcases/` — focused demos with evidence
- `control/` — operator shortcuts (wrappers)

### Make targets (common)
```bash
make env.setup sanity
make linux.baseline
make kubernetes.rke2_install
make netbox.seed
make dr.db.promote dr.cluster.attach dr.gitops.sync dr.dns.cutover
```

### Documentation & evidence
- Update the **Evidence Map** and add artifacts to the **Proof Archive** when changes affect KPIs or architecture.
- Keep **runbooks** current (DR cutover/failback, WAL‑G restore, SoT pivot, GitOps bootstrap).
- Record significant choices in **ADRs**.

### Quick links
- Maintenance Guide → `docs/MAINTENANCE.md`
- Evidence Map → `docs/evidence_map.md`
- Proof Archive → `docs/proof/`
- Runbooks → `docs/runbooks/`
- ADRs Index → `adr/README.md`

### Style
- Markdown ≤ 120 chars/line where possible; prefer lists, short sections.
- Diagrams/screenshots under `docs/` (use UTC timestamps for evidence files).
- Names and labels should be reviewer‑friendly (no internal nicknames).

### Maintainer checklist (per change)
- [ ] CI green (fmt/validate, lint, molecule where applicable)
- [ ] Evidence added under `docs/proof/` if claiming outcomes
- [ ] `docs/evidence_map.md` updated
- [ ] Runbooks updated where behavior changed
- [ ] ADR added/updated if a decision changed
- [ ] Links in top‑level README verified

---

## Community & support

- **Issues:** welcome for questions/clarifications.
- **PRs:** closed by policy (portfolio stays read‑only).
- **Security disclosures:** see **SECURITY.md**.
- **Engagements:** see **CONTRACTING.md** for services and contact details.
