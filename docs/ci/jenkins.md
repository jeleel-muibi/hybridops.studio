---
title: "CI/CD Pipeline – Jenkins Orchestrator"
id: "CI-JENKINS"
pipeline_id: "CI-JENKINS"
owner: "HybridOps.Studio"
summary: "Jenkins pipelines that orchestrate environment-aware plan/apply flows, end-to-end scenarios, and evidence collection."
scope: "platform"
area: "jenkins"
tier: "orchestrator"
tooling: "Jenkins"
video_url: ""

draft: false
is_template_doc: false
tags: ["jenkins", "ci", "orchestrator"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# CI/CD Pipeline — Jenkins Orchestrator

**Purpose:** Orchestrate full plan/apply flows across Proxmox, cloud, and Kubernetes, and capture evidence for portfolio and DR scenarios.  
**Owner:** HybridOps.Studio (platform / SRE).  
**Scope:** Jenkins controller and shared library used for image builds, environment provisioning, DR drills, and end-to-end showcases.  
**Triggers:** Multibranch scans, scheduled jobs (for example nightly smoke runs, DR rehearsals), and manual “run with parameters” invocations.

---

## 1. Entry points

Jenkins is the main apply surface for HybridOps.Studio. Typical entry points:

- **Multibranch pipelines**
  - Automatically discover Jenkinsfiles in key repos/branches.
  - Trigger on pushes and PR updates.

- **Parameterised jobs**
  - Pipelines such as `hos-platform-deploy` or `hos-dr-failover` with parameters:
    - `ENVIRONMENT` (for example `lab`, `demo`, `dr-test`).
    - `CHANGE_TYPE` (for example `plan`, `apply`, `drill`).
    - `DRY_RUN` flags where supported.

- **Scheduled jobs**
  - Nightly or weekly runs to:
    - Validate template builds.
    - Exercise DR and failback paths.
    - Regenerate or refresh proof artifacts.

Key locations:

- Shared library: `core/ci-cd/jenkins/shared-library/`  
- Pipeline templates: `core/ci-cd/jenkins/pipeline-templates/`  
- Operational Jenkinsfiles: `control/tools/ci/jenkins/` (or equivalent)

---

## 2. Pipeline map

A typical Jenkins pipeline for HybridOps.Studio follows this pattern:

1. **Environment sanity**
   - Validate that required variables, credentials, and targets are available.
   - Run lightweight checks (for example connectivity to Proxmox, cloud APIs, NetBox).

2. **Plan**
   - Run Terraform plan for the requested scope (on-prem, cloud, or both).
   - Optionally run Ansible “check mode” for core roles.

3. **Approval / gating (where needed)**
   - Manual approval step for higher-risk changes (for example DR, network edges).
   - Automated policy checks in future iterations.

4. **Apply**
   - Terraform apply for approved changes.
   - Ansible playbooks to converge systems to the desired state.

5. **Verification and smoke tests**
   - Run basic checks (for example service health endpoints, ping, DNS resolution).
   - Invoke HOWTOs or runbook snippets where appropriate.

6. **Evidence archiving**
   - Push logs, plans, and summaries into `output/` and `docs/proof/` structures.
   - Update “latest” symlinks for key scenarios.

Individual pipelines (for example DR failover, template builds, showcase runs) specialise this map but follow the same overall structure.

---

## 3. Inputs and dependencies

**Repositories and branches**

- Primary pipeline definitions live under `control/tools/ci/jenkins/`.
- Supporting roles and modules:
  - `core/ansible/...`
  - `infra/terraform/...`
  - `infra/packer-multi-os/...`

**Credentials and secrets**

Stored in Jenkins credentials with IDs referenced from the shared library and pipelines, including for example:

- Proxmox API token (for VM templates and infra changes).
- Cloud service principals (Azure, GCP) with least privilege.
- GitHub tokens for interacting with Git repos where required.
- NetBox API token for SoT-driven inventory.

Actual IDs and secrets are documented in internal operator notes, not in this page.

**Agents and runners**

- **Jenkins LXC agents** on Proxmox (preferred):
  - Provide fast spin-up / tear-down for CI workloads.
  - Use standardised images built via Packer.
- Optional VM agents for heavier workloads or Windows-specific tasks.

**External services**

- Proxmox VE, Azure, GCP, Kubernetes clusters.
- NetBox, DNS, observability stack (Prometheus, Grafana).

---

## 4. Execution flow (stage-by-stage)

A representative “environment deploy” pipeline:

### Stage: Env sanity

- Verify:
  - Jenkins shared library version.
  - Required credentials exist.
  - Target environment is supported and not in a blocked state.
- Abort early with clear messaging if prerequisites are missing.

### Stage: Plan

- Run `terraform plan` for the selected environment and scope.
- Run Ansible sanity checks where relevant.
- Publish plan artefacts for review (for example plan files, summaries).

### Stage: Approval (optional)

- Manual input step for higher-risk environments (for example `prod-like`, DR).
- In low-risk lab contexts, this may be auto-approved.

### Stage: Apply

- Run `terraform apply` using the pre-generated plan or re-calculated state.
- Execute Ansible playbooks to configure:
  - OS baseline (Linux, Windows).
  - Platform components (Kubernetes, observability, control plane).
  - Networking or DR-specific configuration.

### Stage: Verification

- Trigger smoke tests:
  - Service availability checks.
  - DNS and routing verification.
  - Simple application-level probes.
- Summarise success/failure outcomes.

### Stage: Evidence

- Archive:
  - Logs under `output/logs/ci/jenkins/<pipeline>/...`
  - Plan and apply summaries under `output/artifacts/...`
  - Curated proof nodes under `docs/proof/...` for scenarios that matter to the portfolio.

---

## 5. Evidence and observability

Jenkins is tightly coupled to the evidence-first model:

- **Build logs**
  - Stored per run, accessible via Jenkins UI.
  - Linked from proof pages where appropriate.

- **Artefacts**
  - Terraform plans, Ansible logs, and rendered inventories.
  - Exported and mirrored into `output/` and `docs/proof/` trees for long-term reference.

- **Dashboards**
  - Grafana panels may show:
    - Build trends.
    - DR drill timing.
    - Success vs failure rate of key pipelines.

Evidence patterns for this pipeline are usually referenced from:

- Relevant runbooks (for example DR failover / failback, template builds).
- Proof entries under `docs/proof/ci/jenkins/...`.

---

## 6. Failure modes and recovery

Common failure modes:

- **Agent capacity or image drift**
  - LXC agents unavailable, or images missing required tooling.
  - Recovery: rebuild agents from Packer templates; verify agent labels and images.

- **Credential or API failures**
  - Expired tokens, changed permissions, or unreachable endpoints.
  - Recovery: rotate credentials, validate connectivity, re-run sanity checks.

- **Terraform / Ansible errors**
  - Misconfigured modules or playbooks.
  - Recovery: fix code, test in lab environment, re-run with plan/apply stages.

- **DR and failover-specific issues**
  - Timeouts or partial cutovers during DR drills.
  - Recovery: follow DR runbooks (`docs/runbooks/dr/...`), use evidence to pinpoint where the flow failed.

When a failure pattern repeats, capture it in:

- A runbook under `docs/runbooks/`.
- The relevant CI pipeline doc (this page) under “Failure modes and recovery”.

---

## 7. Extensibility and change guidelines

When extending Jenkins pipelines:

- **Reuse the shared library**
  - Centralise repeated steps (env sanity, evidence archiving, notifications).
- **Keep pipelines environment-aware**
  - Parameterise environment, scopes, and DRY_RUN behaviour rather than cloning jobs.
- **Align with GitHub Actions guardrails**
  - Use Jenkins for apply flows; ensure corresponding lint/validate checks exist in GitHub Actions.
- **Capture new evidence patterns**
  - For significant scenarios (for example new DR flow, new showcase), add:
    - Proof entries in `docs/proof/...`
    - Cross-links from relevant ADRs, HOWTOs, and runbooks.

For pipelines that become Academy material, update tags and `stub` metadata so build tooling can generate tailored stubs or CTAs.
