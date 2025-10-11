# Core — Shared Automation

Reusable building blocks that power HybridOps.Studio: an internal Ansible collection, lightweight Python helpers, a PowerShell module, and Jenkins CI/CD assets. These components back deployment playbooks and showcases, and are **portable across on‑prem and cloud targets**.

---

## What’s included

- **Ansible collection:** `hybridops.common`
  Opinionated roles and small plugins for Linux, Windows, NetBox, and network devices.

- **Python package:** `libhybridops`
  Utility functions used by orchestration/decision logic and supporting scripts.

- **PowerShell module:** `HybridOps.Common`
  Helpers for Windows administration tasks (domain join, SQL install prep, etc.).

- **CI/CD (Jenkins)**
  A shared library and reference pipelines that standardize build/test/deploy across showcases.

> **Naming note:** The PowerShell module **HybridOps.Common** (PascalCase) is distinct from the Ansible collection **hybridops.common** (lowercase).
>
> | Technology        | Name               | Typical import/use                  |
> |-------------------|--------------------|-------------------------------------|
> | PowerShell module | `HybridOps.Common` | `Import-Module HybridOps.Common`    |
> | Ansible collection| `hybridops.common` | `collections: [ hybridops.common ]` |

---

## CI/CD (Jenkins) at a glance

**Shared library functions** provide consistent steps—Terraform plan/apply, Ansible run, GitOps sync, and evidence archiving.
**Pipeline templates** illustrate common flows for Linux, Kubernetes, Windows, Network, NetBox, and DR.

**Example Jenkinsfile**

```groovy
@Library('hybridops-shared@main') _

pipeline {
  agent any
  stages {
    stage('Sanity') {
      steps { sh 'make env.setup sanity' }
    }
    stage('Terraform Plan') {
      steps {
        terraformRun(
          dir: 'terraform-infra/environments/onprem/dev',
          action: 'plan'
        )
      }
    }
    stage('Ansible Baseline') {
      steps {
        ansibleRun(
          inventory: 'deployment/inventories/bootstrap/hosts.ini',
          playbook:  'deployment/linux/playbooks/baseline.yml',
          logDir:    'out/logs/ansible'
        )
      }
    }
    stage('GitOps Sync') {
      steps { gitOpsSync(kubeContext: 'onprem-rke2') }
    }
  }
  post { always { evidenceArchive(outDir: 'out/artifacts/ansible-runs') } }
}
```

**CI documentation:** See **[CI Overview](../docs/ci/README.md)** · **[GitHub Actions](../docs/ci/github-actions.md)** · **[Jenkins](../docs/ci/jenkins.md)**

---

## Quick usage (inside this repository)

```yaml
- name: Baseline Linux
  hosts: linux:&tag_baseline
  gather_facts: false
  collections:
    - hybridops.common
  roles:
    - role: hybridops.common.harden_ssh
    - role: hybridops.common.user_management
```

NetBox‑driven inventories and environment variables are consumed by deployment playbooks in the **Deployment** area.

---

## Layout

```
core/
  ansible/
    collections/
      ansible_collections/
        hybridops/
          common/
            README.md           ← collection overview + role index
            roles/…             ← each role (with its own README)
            plugins/…           ← optional: filter/lookup/modules
  python/
    libhybridops/               ← reusable Python helpers
  powershell/
    HybridOps.Common/           ← Windows administration helpers
  ci-cd/
    jenkins/
      pipeline-templates/       ← reference Jenkinsfile patterns
      shared-library/
        vars/                   ← shared steps (groovy)
```

---

## Role index (high‑level)

| Role (collection) | Purpose | Notes |
|---|---|---|
| `linux.harden_ssh` (`hybridops.common`) | CIS‑leaning SSH hardening | Reloads `sshd` |
| `linux.user_management` | System users, groups, sudoers | Idempotent create/lock/delete |
| `linux.rke2_install` | Install & pin RKE2 | Control plane / worker flags |
| `linux.deploy_nginx` | Smoke‑test web server | Optional TLS via template |
| `netbox.seed` | Seed NetBox with core objects | Token required (HTTP modules) |
| `network.base_config` | Baseline device config | Platform variables per vendor |
| `network.configure_bgp` | eBGP/VPN edge config | Route‑maps / communities |
| `windows.domain_join` | Join host to AD | WinRM / PowerShell |
| `windows.install_sql` | SQL Server install & config | Basic HA hooks |
| `windows.windows_updates` | Patch orchestration | Maintenance window aware |

> Each role contains its own README with variables and a runnable example.

---

## Quality & testing

- **Lint:** `ansible-lint` for roles; `yamllint` for YAML; `flake8` for Python.
- **Tests:** `molecule` kept **inside each role** (closest to the code under test).
- **Style & CI:** pre‑commit hooks and GitHub Actions run lint/format jobs across the repo.

---

## Stability & reuse

This collection underpins the portfolio’s deployment flows (paths, conventions, GitOps). Where external reuse is appropriate, roles/modules are mirrored to public registries with semantic versions.

---

## Related

- **Deployment** — environment‑specific playbooks and GitOps overlays.
- **Evidence Map** — claim → proof links for KPIs and architecture.
- **Proof Archive** — curated screenshots and exports.
- **Runbooks** — DR/burst/bootstrap/DNS/VPN/secrets procedures.
