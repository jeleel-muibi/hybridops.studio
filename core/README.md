# Core — Shared Automation

Shared automation libraries that support HybridOps.Studio across on-prem and cloud environments. This area contains:

- A lightweight Python helper package.
- A PowerShell module for Windows-oriented tasks.
- Jenkins CI/CD assets (shared library and pipeline templates).

Environment-specific playbooks and GitOps overlays live under `deployment/`. Ansible collections (for example `hybridops.common`, `hybridops.network`) are published as separate repositories and consumed from Ansible Galaxy.

---

## What’s included

- **Python package:** `libhybridops`  
  Utility functions for orchestration, decision logic, evidence emission, and glue code between platform components.

- **PowerShell module:** `HybridOps.Common`  
  Helpers for Windows administration (for example domain join flows, SQL installation preparation, OS configuration tasks).

- **CI/CD (Jenkins):** shared library and pipeline templates  
  Reusable steps for Terraform plan/apply, Ansible runs (using external `hybridops.*` collections), GitOps sync, and evidence archiving to `output/`.

---

## CI/CD (Jenkins) at a glance

Jenkins pipelines in this repository use a shared library to standardise workflows such as:

- Environment sanity checks.
- Terraform plan/apply for on-prem and cloud.
- Ansible runs that consume `hybridops.*` Galaxy collections.
- GitOps sync to Kubernetes clusters.
- Evidence export into `output/artifacts` and `output/logs`.

Example (simplified):

```groovy
@Library('hybridops-shared@main') _

pipeline {
  agent any

  stages {
    stage('Sanity') {
      steps {
        sh 'make env.sanity'
      }
    }
    stage('Terraform Plan') {
      steps {
        terraformRun(
          dir: 'infra/terraform/live-v1/onprem/dev',
          action: 'plan'
        )
      }
    }
    stage('GitOps Sync') {
      steps {
        gitOpsSync(kubeContext: 'onprem-rke2')
      }
    }
  }

  post {
    always {
      evidenceArchive(outDir: 'output/artifacts/ci-runs')
    }
  }
}
```

Additional CI documentation is provided in the documentation repository (for example CI overview, GitHub Actions usage, Jenkins patterns).

---

## Layout

- `core/ci-cd/jenkins/` – shared library and pipeline templates for Jenkins.
- `core/python/libhybridops/` – reusable Python helpers.
- `core/powershell/HybridOps.Common/` – Windows administration helpers.

Typical usage:

- Jenkins jobs load the shared library from `core/ci-cd/jenkins/shared-library`.
- Python tooling imports `libhybridops` for decision logic and evidence export.
- PowerShell automation imports `HybridOps.Common` on Windows hosts.

---

## External Ansible collections

HybridOps.Studio Ansible collections are published as separate repositories and to Ansible Galaxy. This repository consumes them as dependencies; the collections themselves are not vendored under `core/`.

- `hybridops.app` – application and platform roles (for example Jenkins controller, RKE2, NetBox, Moodle, Windows workloads).  
  - Source: [github.com/hybridops-studio/ansible-collection-app](https://github.com/hybridops-studio/ansible-collection-app)  
  - Galaxy: [galaxy.ansible.com/hybridops/app](https://galaxy.ansible.com/hybridops/app)

- `hybridops.common` – common utilities, inventory generation, environment guards, and shared plugins.  
  - Source: [github.com/hybridops-studio/ansible-collection-common](https://github.com/hybridops-studio/ansible-collection-common)  
  - Galaxy: [galaxy.ansible.com/hybridops/common](https://galaxy.ansible.com/hybridops/common)

- `hybridops.helper` – helper roles for evidence collection and NetBox-driven inventory.  
  - Source: [github.com/hybridops-studio/ansible-collection-helper](https://github.com/hybridops-studio/ansible-collection-helper)  
  - Galaxy: [galaxy.ansible.com/hybridops/helper](https://galaxy.ansible.com/hybridops/helper)

- `hybridops.network` – network automation roles (for example base configs, routing, BGP/OSPF, backups, compliance).  
  - Source: [github.com/hybridops-studio/ansible-collection-network](https://github.com/hybridops-studio/ansible-collection-network)  
  - Galaxy: [galaxy.ansible.com/hybridops/network](https://galaxy.ansible.com/hybridops/network)

These collections are referenced from `deployment/` playbooks and inventories rather than from `core/` directly.

---

## Quality and testing

- **Python:** formatted and linted via standard tooling (for example `black`, `flake8`, `pytest` where applicable).
- **PowerShell:** validated with common style and script analysis checks (for example `PSScriptAnalyzer`).
- **Jenkins library:** covered by lightweight pipeline examples and smoke tests executed via CI.

Automation in this directory is treated as shared infrastructure code: changes are version-controlled, reviewed, and exercised through CI before promotion to primary branches.

---

## Related components

- [deployment/](../deployment/README.md) – environment-specific playbooks and GitOps overlays that consume external `hybridops.*` Ansible collections and call into `core/` libraries where needed.
- [output/](../output/) – canonical logs and artifacts produced by pipelines (referenced from showcases and runbooks).
- [docs.hybridops.studio](https://docs.hybridops.studio) – CI/CD, collections, and runbooks describing how these components are used end-to-end.
