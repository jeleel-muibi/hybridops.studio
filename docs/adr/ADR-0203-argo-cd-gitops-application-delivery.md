---
id: ADR-0203
title: "Adopt Argo CD as GitOps Controller for Application Delivery"
status: Accepted
date: 2025-12-02
category: "02-platform"       # One of:
                              # "00-governance"
                              # "01-networking"
                              # "02-platform"
                              # "03-security"
                              # "04-observability"
                              # "05-data-storage"
                              # "06-cicd-automation"
                              # "07-disaster-recovery"
                              # "08-cost-optimisation"
                              # "09-compliance"

domains: ["platform", "sre"]
owners: ["HybridOps.Studio"]
supersedes: []
superseded_by: []

links:
  prs: []
  runbooks:
    - "../runbooks/dr/runbook_dr_cutover_onprem_to_cloud.md"
    - "../runbooks/dr/runbook_dr_failback_cloud_to_onprem.md"
  howtos:
    - "../howtos/HOWTO_rke2_bootstrap_from_proxmox_templates.md"
    - "../howtos/HOWTO_netbox_migration_docker_to_rke2.md"
    - "../howtos/HOWTO_dr_cost_drill.md"
  evidence:
    - "../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md"
  diagrams: []
  related_docs:
    - "./ADR-0202-rke2-primary-runtime-for-platform-and-apps.md"
    - "./ADR-0603-jenkins-controller-docker-agents-rke2.md"
---

_Status: Accepted (2025-12-02)_

---

# Adopt Argo CD as GitOps Controller for Application Delivery

## 1. Context

HybridOps.Studio uses:

- **RKE2** as the primary runtime for platform and applications (ADR-0202).  
- **Jenkins** on `ctrl-01` with agents on RKE2 (ADR-0603) to orchestrate image builds, Terraform plans and Ansible runs.  

Early experiments used Jenkins or ad-hoc `kubectl` apply steps for application deployment. This approach:

- Couples application rollout logic tightly to CI workflows.  
- Encourages imperative changes against clusters, making drift hard to detect.  
- Makes it difficult to reason about which version of an application is currently desired vs actually running.

For platform and application delivery, we want:

- A **declarative, pull-based GitOps model** where the cluster reconciles itself from Git.  
- A clean separation between:
  - **CI**: build, test, and security scanning of artefacts.  
  - **CD/GitOps**: promotion and rollout of versioned manifests across environments.  
- A pattern that is recognisable to enterprise teams and easy to explain in Academy materials.

## 2. Decision

HybridOps.Studio adopts **Argo CD** as the **GitOps controller** for application delivery to RKE2 clusters.

- Jenkins remains the **CI orchestrator** for image builds, infrastructure pipelines and DR workflows.  
- Argo CD becomes the **system of record for application desired state** on Kubernetes clusters.  
- Application environments (for example, `dev`, `staging`, `prod`) are represented as:
  - Separate Argo CD Applications or ApplicationSets.  
  - Directly mapped to Git branches, directories or overlays.

In practice:

- CI pipelines publish container images and update versioned manifests in Git.  
- Argo CD detects the change in Git and reconciles RKE2 to match, with:
  - Rollout status,  
  - Drift detection, and  
  - Easy rollbacks via Git history.

## 3. Rationale

### 3.1 Why a dedicated GitOps controller?

Using a dedicated GitOps controller rather than CI-driven `kubectl`:

- Provides a **continuous reconciliation loop**:
  - Any manual drift at cluster level is detected and, if configured, corrected.  
- Centralises **application deployment state**:
  - Argo CD UI and API show which versions of which apps are deployed in which namespaces.  
- Simplifies **promotion flows**:
  - Promotion becomes a Git operation (for example, merging a PR or updating an image tag), which is:
    - Auditable,
    - Reviewable, and
    - Aligned with standard change processes.

### 3.2 Why Argo CD instead of alternatives?

Argo CD was chosen over alternatives such as Flux because:

- It has a mature, widely adopted **GitOps UX** with strong visualisation.  
- It fits well into a **consulting / academy** context where visual demos help explain:
  - Desired vs live state,
  - Sync status, and
  - Rollbacks.  
- It has well understood patterns for:
  - Multi-environment application deployment, and  
  - ApplicationSet-driven fleet patterns, which keeps options open for future expansion.

This aligns with HybridOps.Studio’s goal of being:

- Recognisable to enterprise teams, and  
- A good teaching platform for modern GitOps workflows.

## 4. Consequences

### 4.1 Positive

- **Clear separation of concerns**  
  - Jenkins focuses on CI and orchestration.  
  - Argo CD focuses on CD and environment reconciliation.

- **Improved observability for application state**  
  - Argo CD provides a single place to view sync status, health, and version for platform and application workloads.

- **Stronger change governance**  
  - All configuration changes flow through Git.  
  - Rollbacks are **Git revert** operations rather than ad-hoc cluster edits.

- **Better alignment with teaching and consulting**  
  - Demonstrates a standard GitOps pattern that clients and students can adopt.

### 4.2 Negative / trade-offs

- **More components to operate**  
  - Argo CD itself must be installed, upgraded and monitored on RKE2.

- **Additional conceptual surface area**  
  - CI pipelines, image registries, Git repos and Argo CD Applications all need to be introduced clearly in documentation and Academy content.

- **Bootstrap considerations**  
  - The bootstrap path for Argo CD (who deploys the GitOps controller) needs to be defined and automated over time.

## 5. Implementation

### 5.1 Repository structure

- Application manifests live under a `deploy/` or `k8s/` directory hierarchy.  
- Environment overlays can be implemented using:
  - Kustomize,  
  - Helm values, or  
  - A simple directory-per-environment structure.

Argo CD Applications reference those directories/overlays directly.

### 5.2 CI integration

- Jenkins pipelines build container images and push them to a registry.  
- Pipelines update:
  - Image tags, or
  - Version fields in manifests
  in the Git repo used by Argo CD.

Whenever a pipeline updates manifests on the main branch for an environment:

- Argo CD detects the change and begins reconciliation.  
- Status is visible in Argo CD UI and via API.

### 5.3 DR and multi-cluster

For DR scenarios where a secondary cluster exists (for example, a cloud RKE2 or managed K8s cluster):

- Argo CD can be deployed per-cluster, pointing at:
  - The same or a subset of Git repos, with environment-specific configuration.

DR runbooks (on-prem → cloud, cloud → on-prem) remain orchestrated by GitHub Actions and Jenkins, but application deployment on each cluster is driven by that cluster’s Argo CD instance.

## 6. Operational considerations

- Argo CD instance(s) must be included in:
  - Backup and DR planning.  
  - Monitoring via Prometheus (for example, health and sync metrics).  

- Access control should be integrated with:
  - The same identity provider as other platform components where possible, or  
  - Bounded local accounts with clear role separation.

- Academy material and internal HOWTOs should demonstrate:
  - Onboarding a new application into GitOps.  
  - Rolling forward and back using Git.  
  - Reading Argo CD’s status views during incidents and DR drills.

## 7. References

- [ADR-0202 – Adopt RKE2 as Primary Runtime for Platform and Applications](./ADR-0202-rke2-primary-runtime-for-platform-and-apps.md)  
- [ADR-0603 – Jenkins Controller on ctrl-01 with RKE2 Agents](./ADR-0603-jenkins-controller-docker-agents-rke2.md)  
- [HOWTO – Bootstrap an RKE2 Cluster from Proxmox Templates](../howtos/HOWTO_rke2_bootstrap_from_proxmox_templates.md)  
- [HOWTO – Migrate NetBox from Docker on ctrl-01 to RKE2](../howtos/HOWTO_netbox_migration_docker_to_rke2.md)  
- [HOWTO – Run a Cost-Aware DR Drill (Prometheus → GitHub Actions → DR Workflow)](../howtos/HOWTO_dr_cost_drill.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation
