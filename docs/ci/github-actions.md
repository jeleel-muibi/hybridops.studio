# GitHub Actions

A portfolio‑friendly set of workflows that validate code and render non‑destructive outputs.

| Workflow file | Purpose | Triggers | Secrets |
|---|---|---|---|
| `lint-ansible.yml` | Run `ansible-lint` / `yamllint` | `push`, `pull_request` | — |
| `lint-terraform.yml` | `terraform fmt -check`, `validate`, `tfsec` | `push`, `pull_request` | Cloud creds (optional for `validate`) |
| `molecule.yml` | Role tests where present | `push`, `pull_request`, manual | — |
| `render-inventory.yml` | Render NetBox → inventory (dry) | manual | `NETBOX_URL`, `NETBOX_TOKEN` (optional) |
| `gitops-dry-run.yml` | Kustomize/Helm template (no apply) | manual | — |

**Notes**
- Secrets are configured in the repository settings under **Settings → Secrets and variables → Actions**.
- Where cloud credentials are required for validation, provide read‑only identities.
- For local checks, use `pre-commit` and `make sanity`.

**See also:** CI Overview and Jenkins docs for the apply paths.
