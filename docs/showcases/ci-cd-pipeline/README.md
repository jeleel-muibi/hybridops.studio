---
title: "Showcase – CI/CD Pipeline for HybridOps.Studio"
category: "showcase"
summary: "End-to-end CI/CD pipeline that builds images, provisions infrastructure, deploys workloads, and captures evidence."
difficulty: "Intermediate"

topic: "showcase-ci-cd-pipeline"

video: "https://www.youtube.com/watch?v=CI_CD_PIPELINE_DEMO"
source: "https://github.com/hybridops-studio/hybridops-studio"

draft: false
is_template_doc: false
tags: ["showcase", "portfolio", "ci-cd", "automation"]

audience: ["hiring-managers", "learners", "cloud-native"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# CI/CD Pipeline for HybridOps.Studio

## Executive summary

This showcase demonstrates an opinionated CI/CD pipeline that:

- Builds Proxmox VM templates and container images using Packer and Docker.
- Provisions and updates infrastructure using Terraform and Ansible.
- Deploys workloads to Kubernetes and on-prem services.
- Captures build and deployment evidence as first-class artefacts.

It is designed to look and feel like a production-ready pipeline that can be extended to real customer environments.

---

## Case study – how this was used in practice

- **Context:** Hybrid lab environment combining Proxmox, Kubernetes and public cloud, with a requirement to prove repeatability and auditability.
- **Challenge:** Manual, ad-hoc builds and inconsistent environments made it hard to trust test results or reproduce demos.
- **Approach:** Introduced a CI/CD pipeline that standardised image builds, infra changes and workload deploys, with evidence collected at each stage.
- **Outcome:** Reduced “works on my machine” issues, improved confidence in demos, and created reusable patterns suitable for enterprise teams.

Related decisions (for example):

- [ADR-00XX – Packer + Cloud-Init VM Templates](../../adr/ADR-0016-packer-cloudinit-vm-templates.md)
- [ADR-00YY – Jenkins as CI/CD Orchestrator](../../adr/ADR-00YY-jenkins-architecture.md)

---

## Demo

### Video walkthrough

- Video: https://www.youtube.com/watch?v=CI_CD_PIPELINE_DEMO  

In the demo, you will see:

1. A change pushed to GitHub.
2. The pipeline building updated images and infrastructure.
3. Application deployment to the lab environment.
4. Evidence collection (logs, screenshots, build metadata) for later review.

### Screenshots

```markdown
![Pipeline overview](./diagrams/pipeline-overview.png)
![Evidence dashboard](./screenshots/evidence-dashboard.png)
```

---

## Architecture

- High-level diagram:

  ```markdown
  ![High-level architecture](./diagrams/architecture-overview.png)
  ```

- Key components:
  - **Source control:** GitHub, with protected branches for main/trunk.
  - **CI/CD engine:** Jenkins and/or GitHub Actions for pipelines.
  - **Infra-as-code:** Terraform and Ansible to manage Proxmox, cloud and services.
  - **Templates:** Packer-built images with cloud-init for zero-touch VM provisioning.
  - **Observability:** Grafana and Prometheus used to visualise build and runtime metrics.

Optional detailed diagrams:

- [Network topology](./diagrams/network-topology.png)
- [Pipeline stages](./diagrams/pipeline-stages.png)

---

## Implementation highlights

- Pipelines split into stages for **lint → build → test → deploy → evidence**.
- All builds run against repeatable IaC definitions, with no manual configuration.
- Evidence (logs, screenshots, metadata) is stored under a dedicated `evidence/` tree.
- Designed to run in a home lab but aligned with patterns used by enterprise CI/CD platforms.

---

## Assets and source

- GitHub folder for this showcase:  
  https://github.com/hybridops-studio/hybridops-studio/tree/main/showcases/ci-cd-pipeline

- CI/CD pipelines:
  - `control/tools/ci/jenkins/` (Jenkins pipelines)
  - `.github/workflows/` (GitHub Actions workflows, if used)

- Infrastructure as Code:
  - `infra/terraform/` – environment provisioning
  - `core/ansible/` – configuration management

- Evidence:
  - `./evidence/` – logs, screenshots and exported dashboards for this showcase.

---

## Academy track (if applicable)

In the Academy, this showcase can be extended into a hands-on lab where learners:

- Create or modify a pipeline stage.
- Introduce a controlled failure and use evidence to troubleshoot.
- Capture a short runbook describing how to recover from a failed deployment.

---

## Role-based lens (optional)

- **Platform Engineer / SRE:** demonstrates standardised build/deploy flows and evidence-driven operations.
- **Network / Infrastructure Engineer:** shows how infra changes are integrated into CI/CD safely.
- **Engineering Manager / Hiring Manager:** highlights ownership of the full delivery lifecycle and a focus on repeatability.

---

## Back to showcase catalogue

- [Back to all showcases](../000-INDEX.md)
