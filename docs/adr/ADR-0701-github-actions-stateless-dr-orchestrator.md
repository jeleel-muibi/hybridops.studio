---
id: ADR-0701
title: "Use GitHub Actions as Stateless DR Orchestrator"
status: Accepted
date: 2025-12-01
category: "07-disaster-recovery"

domains: ["platform", "dr", "cicd", "sre"]
owners: ["HybridOps.Studio"]
supersedes: []
superseded_by: []

links:
  prs: []
  runbooks: []
  howtos: []
  evidence:
    - "../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md"
  diagrams: []

draft: false
is_template_doc: false
tags: ["dr", "github-actions", "prometheus", "orchestration"]
access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""

---

# Use GitHub Actions as Stateless DR Orchestrator

## Status
Accepted — Prometheus federation and Alertmanager trigger GitHub Actions workflows that orchestrate DR and burst operations, with decisions gated by a Cost Decision Service.

## 1. Context

HybridOps.Studio needs a repeatable way to orchestrate **disaster recovery (DR)** and **cloud burst** scenarios, including:

- Failing over from on-prem RKE2 and PostgreSQL LXC to cloud capacity when required.
- Running DR drills that are observable, auditable and low-risk.
- Enforcing **cost guardrails** before taking actions that scale cloud resources.

Key requirements:

- The orchestrator must be **stateless** and **out-of-band** relative to the on-prem infrastructure, so it remains available when on-prem systems are degraded.
- The control flow should be **driven by metrics and alerts** (Prometheus federation and Alertmanager) rather than manual, ad-hoc runbook execution.
- All actions must be **traceable** to Git commits, pipeline runs and cost artefacts under `docs/proof/`.

Options considered:

- Use Jenkins on `ctrl-01` as the DR orchestrator.
- Use a custom service hosted on-prem or on cloud VMs.
- Use GitHub Actions as the stateless orchestration layer.

This ADR defines the standard for how DR orchestration is implemented.

## 2. Decision

HybridOps.Studio uses **GitHub Actions** as the **stateless DR orchestrator** for:

- On-prem → cloud DR cutover.
- Cloud → on-prem reversion after recovery.
- Controlled cloud bursting for extra capacity.

The pattern is:

1. **Detection**: Prometheus federation evaluates SLOs and resource health.  
2. **Alerting**: Alertmanager sends DR-relevant alerts (for example, `jenkins_critical_down`, `rke2_cluster_unhealthy`) to a dedicated webhook endpoint.  
3. **Trigger**: The webhook invokes a GitHub Actions workflow via `repository_dispatch` or similar event.  
4. **Decision**: The workflow calls a **Cost Decision Service** that reads cost artefacts from `docs/proof/cost/` and decides whether the proposed DR/burst action is allowed.  
5. **Action**: If allowed, the workflow applies Terraform/Ansible plans (or calls other tools) to:
   - Start or scale cloud Kubernetes clusters.
   - Promote the cloud PostgreSQL replica to primary.
   - Deploy core workloads (for example, Jenkins, NetBox) using GitOps manifests.
   - Update DNS and/or Azure Front Door configuration as per DR runbooks.  
6. **Evidence**: The workflow writes logs and results to `docs/proof/dr/<date>/` and updates dashboards.

GitHub Actions is treated as **the** DR orchestrator. Jenkins remains responsible for normal CI/CD, infra builds and platform operations, but not for DR control when the platform is degraded.

## 3. Rationale

Reasons for choosing GitHub Actions as the DR orchestrator include:

Stateless and out-of-band:

- GitHub-hosted runners and workflows are outside the on-prem failure domain.
- DR orchestration remains available even when RKE2, Proxmox or `ctrl-01` are degraded.
- The orchestration logic is versioned in Git and can be audited or rolled back.

Integration with existing workflows:

- Infrastructure and application code already lives in GitHub repositories.
- GitHub Actions is already used (or will be used) for CI checks and automation on those repos.
- Reusing the same platform for DR avoids adding another tool just for orchestration.

Traceability and compliance:

- Every DR workflow run is tied to:
  - A specific commit (`GITHUB_SHA`).
  - A workflow run ID.
  - Logs and artefacts stored both in GitHub and under `docs/proof/dr/`.
- This supports Evidence 4 and future compliance evidence, making it easy to show what changed, when and why.

Cost-aware design:

- The Cost Decision Service is called from within the workflow to read cost artefacts and guardrails before any destructive or expensive changes.
- This makes cost a **first-class signal** in DR and burst operations, not an afterthought.

Operational separation:

- Jenkins focuses on:
  - Packer image builds.
  - Infrastructure provisioning.
  - Standard application delivery to RKE2.
- GitHub Actions focuses on:
  - DR and burst orchestration.
  - Cross-environment workflows that must remain available during on-prem incidents.

Trade-offs:

- GitHub Actions introduces a dependency on GitHub availability.
- Some sensitive secrets must be managed carefully between GitHub Actions and cloud providers.

## 4. Consequences

### 4.1 Positive consequences

- **Robust DR control plane**
  - DR workflows are not lost when on-prem systems fail.
  - Alert-driven orchestration reduces manual error during incidents.

- **Better auditability**
  - DR and burst actions are captured as GitHub Actions runs with artefacts and logs.
  - Evidence 4 can point to both repo history and `docs/proof/dr/` for verification.

- **Consistent automation story**
  - CI/CD and DR automation both live next to the code they operate on.
  - The same patterns used for standard workflows can be applied to DR pipelines.

### 4.2 Negative consequences and risks

- **External dependency**
  - Reliance on GitHub Actions means a GitHub outage could affect DR automation.
  - In extreme scenarios, manual runbook execution must still be possible.

- **Secret management**
  - Cloud credentials and limited-scope tokens must be stored securely in GitHub.
  - Misconfiguration could expose credentials or allow unintended actions.

- **Complexity of DR pipelines**
  - DR workflows can become complex if not carefully designed and documented.
  - Needs clear runbooks and HOWTOs to avoid confusion in high-pressure situations.

Mitigations:

- Maintain **manual DR runbooks** that can be followed without GitHub Actions, for worst-case scenarios.
- Use **least-privilege credentials** for GitHub Actions (scoped to DR resources only).
- Keep DR workflows **small, composable and well-documented**, with clear inputs and outputs.
- Regularly run **DR drills** in a safe environment to validate and refine workflows.

## 5. Alternatives considered

Use Jenkins on ctrl-01 as DR orchestrator:

- Would keep all automation within a single tool.
- Tightly couples DR orchestration to on-prem availability:
  - If `ctrl-01` or Jenkins is unavailable, DR workflows are also unavailable.
- Reduces the ability to demonstrate “out-of-band” DR control in Evidence 4.

Build a custom DR microservice:

- Flexible but adds another system to maintain and secure.
- Duplicates capabilities already present in GitHub Actions (pipelines, secrets, logs).
- Less transparent to assessors than a widely known, auditable CI platform.

Use cloud-native orchestrators only (for example, Azure Automation, Cloud Functions):

- Ties DR orchestration strongly to a single cloud provider.
- Conflicts with the multi-cloud, hybrid positioning of HybridOps.Studio.
- Harder to align with the Git-centric workflow and evidence story.

## 6. Implementation notes

Trigger path:

- Prometheus federation sends alerts to Alertmanager.
- Alertmanager routes DR-relevant alerts to a webhook receiver.
- The webhook triggers a GitHub Actions workflow via `repository_dispatch` or another supported trigger.

Workflow structure:

- Workflows live under `.github/workflows/` in the relevant repository.
- Key jobs:
  - Fetch cost artefacts (for example, `docs/proof/cost/<env>/latest.json`).
  - Call the Cost Decision Service (Python or similar script).
  - If allowed, run Terraform/Ansible or other tools to:
    - Scale or create cloud clusters.
    - Promote PostgreSQL replicas.
    - Update DNS and load balancer configuration.
  - Write logs and artefacts into `docs/proof/dr/<date>/`.

Evidence:

- DR runs (live or drills) must produce:
  - GitHub Actions logs and artefacts.
  - Snapshots of Prometheus/Alertmanager events.
  - Records in `docs/proof/dr/` with timestamps and links back to workflow runs.

## 7. Operational impact and validation

Operational impact:

- Platform and SRE teams must:
  - Maintain and test DR workflows in GitHub Actions.
  - Ensure Prometheus/Alertmanager routes DR alerts correctly.
  - Keep cost artefacts and the Cost Decision Service up to date.

Validation:

- Runbooks to be created:
  - DR cutover – on-prem → cloud.
  - DR reversion – cloud → on-prem.
  - Cost guardrail breach (DR/burst blocked).
- HOWTOs to be created:
  - Run a cost-aware DR drill (Prometheus → GitHub Actions → DR).
- Evidence folders:
  - [`docs/proof/dr/`](../../docs/proof/dr/) for DR drills and live events.
  - [`docs/proof/cost/`](../../docs/proof/cost/) for cost artefacts.
  - [`docs/proof/infra/rke2/`](../../docs/proof/infra/rke2/) and related infra for cluster state.

Validation is considered successful when:

- Test alerts from Prometheus lead to GitHub Actions runs that complete successfully in simulation mode.
- Cost guardrails are enforced as expected (for example, DR blocked when projected cost exceeds threshold).
- Real DR drills (non-production) show end-to-end evidence from alert all the way to cluster and DNS state.

## 8. References

- [ADR-0001 – ADR Process and Conventions](../adr/ADR-0001-adr-process-and-conventions.md)  
- [ADR-0202 – Adopt RKE2 as Primary Runtime for Platform and Applications](../adr/ADR-0202-rke2-primary-runtime-for-platform-and-apps.md)  
- [ADR-0603 – Run Jenkins Controller on Control Node, Agents on RKE2](../adr/ADR-0603-jenkins-controller-docker-agents-rke2.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)

---

**Maintainer:** HybridOps.Studio
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
