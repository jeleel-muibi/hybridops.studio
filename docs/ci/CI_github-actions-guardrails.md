---
title: "CI/CD Pipeline – GitHub Actions Guardrails"
id: "CI-GHA"
pipeline_id: "CI-GHA"
owner: "HybridOps.Studio"
summary: "Non-destructive GitHub Actions workflows that provide fast lint, validate, and render checks for HybridOps.Studio."
scope: "platform"
area: "github-actions"
tier: "guardrail"
tooling: "GitHub Actions"
video_url: ""

draft: false
is_template_doc: false
tags: ["github-actions", "ci", "guardrail"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# CI/CD Pipeline — GitHub Actions Guardrails

**Purpose:** Provide fast, non-destructive feedback on infrastructure and configuration changes before they reach apply paths.  
**Owner:** HybridOps.Studio (platform / CI maintainer).  
**Scope:** GitHub Actions workflows under `.github/workflows/` for lint, validate, and render-only operations.  
**Triggers:** Pull requests and pushes to tracked branches, with optional manual runs for specific checks.

---

## 1. Entry points

This “pipeline” is implemented as a set of related workflows rather than a single monolith. The main entry points are:

- **Pull requests to main / primary branches**
  - `lint-ansible.yml`
  - `lint-terraform.yml`
  - `molecule.yml` (where roles include Molecule tests)

- **Push events to tracked branches**
  - Same workflows as above, giving fast feedback to branch owners.

- **Manual runs (workflow dispatch)**
  - `render-inventory.yml` — render NetBox → inventory as a dry run.
  - `gitops-dry-run.yml` — render Kustomize/Helm manifests without applying.

Typical usage:

- Contributors open a PR; lint and validate workflows run automatically.
- Platform maintainers trigger `render-inventory` or `gitops-dry-run` manually when testing changes to SoT or GitOps layouts.

Relevant locations:

- GitHub Actions workflows: `.github/workflows/*.yml`
- CI documentation: `docs/ci/github-actions.md` (this page)

---

## 2. Pipeline map

At a high level, the GitHub Actions surface is organised into:

- **Lint and quality checks**
  - `lint-ansible.yml`: `ansible-lint`, `yamllint`.
  - `lint-terraform.yml`: `terraform fmt -check`, `terraform validate`, `tfsec`.

- **Role and collection tests**
  - `molecule.yml`: runs Molecule scenarios for roles that define them.

- **Render-only previews**
  - `render-inventory.yml`: NetBox → inventory render; no writes to targets.
  - `gitops-dry-run.yml`: Kustomize/Helm template to YAML; no apply.

There is no “apply” or destructive path in this surface by design. Apply flows live in Jenkins pipelines documented separately.

---

## 3. Inputs and dependencies

**Repositories and branches**

- Primary repository: `hybridops-studio/hybridops.studio`.
- Runs on PRs and pushes to main and feature branches as configured per workflow.

**Secrets and credentials**

- `NETBOX_URL`, `NETBOX_TOKEN` (optional)  
  Used by `render-inventory.yml` when rendering against a live NetBox instance.
- Cloud credentials (optional for `lint-terraform.yml`)  
  Read-only identities can be configured if external validation against cloud APIs is required.

Secrets are stored in:

- GitHub → **Settings → Secrets and variables → Actions** for the repository or organisation.

**Runners**

- Default GitHub-hosted runners (Ubuntu) are sufficient.
- No self-hosted runners are required for the current guardrail set.

**External services**

- NetBox API (for inventory rendering).
- Optional: cloud APIs (Azure, GCP) for deeper Terraform validation.

---

## 4. Execution flow (stage-by-stage)

Each workflow is small and focused. Typical patterns:

### `lint-ansible.yml`

- **Checkout** — clone repository.
- **Setup Python / dependencies** — install Ansible, ansible-lint, yamllint.
- **Lint roles and playbooks**
  - Run `ansible-lint` against roles and playbooks.
  - Run `yamllint` on playbooks, vars, and inventory snippets.
- **Report status**
  - Fail the job on lint violations.
  - Surface annotations directly in the PR.

### `lint-terraform.yml`

- **Checkout** — clone repository.
- **Setup Terraform / tfsec** — install required tooling.
- **Format and validate**
  - `terraform fmt -check` to enforce consistent formatting.
  - `terraform validate` for basic structural checks.
- **Security scan**
  - Run `tfsec` to flag obvious misconfigurations.
- **Report status**
  - Fail on formatting, validation, or tfsec findings.

### `molecule.yml`

- **Discovery**
  - Identify roles with `molecule/` directories.
- **Matrix execution**
  - Run Molecule scenarios in parallel across target roles.
- **Report status**
  - Fail the workflow if any scenario fails.

### `render-inventory.yml`

- **Optional NetBox connection**
  - Use `NETBOX_URL` and `NETBOX_TOKEN` if provided.
- **Render inventory**
  - Run the same logic as operator tooling to render Ansible inventory from SoT.
- **Artifacts**
  - Upload rendered inventory as workflow artefacts for inspection.

### `gitops-dry-run.yml`

- **Checkout overlays**
  - Fetch the GitOps repo and environment overlays.
- **Template manifests**
  - Run `kustomize build` / `helm template` for the relevant workloads.
- **Artifacts**
  - Export rendered YAML for review.

---

## 5. Evidence and observability

Evidence for these workflows is primarily build logs and artefacts:

- **GitHub Actions UI**
  - Per-workflow logs visible on each run.
  - Annotated errors on files and lines for lint failures.
- **Artifacts**
  - Rendered inventory and GitOps manifests uploaded as downloadable artifacts for specific runs.
- **Cross-linking**
  - References from HOWTOs and runbooks that describe pre-flight checks (for example “verify inventory render before applying changes”).

Where runs are used as proof for the portfolio, they can be mirrored to:

- `docs/proof/ci/github-actions/` — curated proof entries.
- `output/logs/ci/github-actions/` — raw logs taken from Actions runs.

---

## 6. Failure modes and recovery

Typical failure patterns:

- **Lint failures**
  - Misformatted YAML, Ansible best-practice violations.
  - Recovery: fix the code, run `pre-commit` locally, push updates.

- **Terraform validation and tfsec failures**
  - Incorrect module wiring or obvious security issues.
  - Recovery: adjust modules or configuration; re-run locally with `terraform validate` and `tfsec`.

- **Inventory render failures**
  - NetBox model inconsistencies or missing data.
  - Recovery: correct SoT entries, re-run `render-inventory.yml`.

- **GitOps dry-run failures**
  - Invalid Kustomize overlays or Helm values.
  - Recovery: fix overlays/values, run Kustomize/Helm locally before re-triggering the workflow.

Where a failure affects multiple PRs or branches, treat it as a systemic issue and, if needed, capture a short runbook update.

---

## 7. Extensibility and change guidelines

When extending the GitHub Actions surface:

- **Keep workflows focused**
  - One domain per file (lint, test, render), rather than large combined pipelines.
- **Prefer non-destructive operations**
  - Reserve apply / destructive paths for Jenkins and controlled runbooks.
- **Align with pre-commit and local tooling**
  - Ensure developers can reproduce checks locally before pushing.
- **Document new workflows**
  - Add entries here and link to related HOWTOs or runbooks when a new guardrail becomes part of the standard flow.

For any workflow that becomes part of the Academy material, flip `stub.enabled` to `true` and add appropriate highlights and CTA pointing to the course.
