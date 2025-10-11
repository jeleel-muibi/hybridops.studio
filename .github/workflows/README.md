# GitHub Actions — Workflow Index

This folder contains **developer‑facing** documentation for the repository’s GitHub Actions. It is a quick map for anyone browsing `.github/workflows/` directly.

For a narrative overview, see **[CI Overview](../../docs/ci/README.md)** and **[GitHub Actions (full docs)](../../docs/ci/github-actions.md)**. Jenkins details live under **[Jenkins CI](../../docs/ci/jenkins.md)**.

---

## Workflows at a glance

| File | What it does | Typical triggers | Notes / Secrets |
|---|---|---|---|
| `pre-commit.yml` | Runs pre‑commit hooks (YAML/Markdown/Python formatters, lint) | `push`, `pull_request` | No secrets required |
| `lint-ansible.yml` | `ansible-lint` + `yamllint` across Ansible content | `push`, `pull_request` | No secrets required |
| `lint-terraform.yml` | `terraform fmt -check`, `terraform validate`, `tfsec` | `push`, `pull_request` | Cloud creds optional for `validate`; tfsec requires no creds |
| `molecule.yml` | Executes Molecule scenarios when defined per role | `push`, `pull_request`, manual | No secrets required |
| `render-inventory.yml` | Renders NetBox → Ansible inventory (dry) | manual | `NETBOX_URL`, `NETBOX_TOKEN` if you want live calls |
| `gitops-dry-run.yml` | Kustomize/Helm template/render check (no apply) | manual | No secrets required |
| `auto-close-external-prs.yml` | Auto‑closes PRs from forks with a courteous message | `pull_request` from forks | Keeps the portfolio read‑only |

> **Artifacts & logs:** Workflows write non‑sensitive logs into the Actions tab and (when useful) produce artifacts for download. Runtime repo logs/artifacts for live runs are written under `out/` and `out/artifacts/` by Makefile targets and Jenkins jobs.

---

## Secrets (names used in this repo)

If you choose to wire live systems, define secrets under **Settings → Secrets and variables → Actions**:

- `NETBOX_URL` — API base (e.g., `https://netbox.example.com/api`)
- `NETBOX_TOKEN` — read‑only token for inventory rendering
- Cloud creds (optional for Terraform `validate` or module checks): `AZURE_*`, `GOOGLE_*`

> Keep CI identities **read‑only**. The portfolio workflows are designed to be non‑destructive by default.

---

## Reproduce locally

Useful when iterating on a change before pushing:

```bash
# Repo‑wide preflight
make env.setup sanity

# Ansible lint (what the workflow runs)
ansible-lint || true
yamllint . || true

# Terraform checks (what the workflow runs)
terraform -chdir=terraform-infra fmt -recursive -check
terraform -chdir=terraform-infra validate
tfsec terraform-infra || true

# Molecule (run from inside a role that has scenarios)
cd core/ansible/collections/ansible_collections/hybridops/common/roles/<role>
molecule test
```

---

## Conventions

- **Non‑destructive** by default: lint, validate, render, and dry‑run workflows. Apply paths are handled in Jenkins.
- **Readable logs**: keep outputs concise; link to full logs/artifacts when long.
- **Evidence‑friendly**: where practical, export JSON/CSV alongside screenshots (curated under Proof/Evidence docs).

---

## Further reading

- **[CI Overview](../../docs/ci/README.md)**
- **[GitHub Actions (full docs)](../../docs/ci/github-actions.md)**
- **[Jenkins CI](../../docs/ci/jenkins.md)**
