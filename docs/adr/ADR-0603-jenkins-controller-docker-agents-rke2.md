---
id: ADR-0603
title: "Run Jenkins Controller on Control Node, Agents on RKE2"
status: Accepted
date: 2025-12-01
category: "06-cicd-automation"

domains: ["platform", "cicd", "sre"]
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
tags: ["jenkins", "cicd", "rke2", "platform"]
access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""

---

# Run Jenkins Controller on Control Node, Agents on RKE2

## Status
Accepted — the Jenkins controller runs as a Docker container on the Proxmox control node, while Jenkins agents run as ephemeral containers and, once RKE2 is available, as pods inside the RKE2 cluster.

## 1. Context

HybridOps.Studio needs a CI/CD orchestration layer that can:

- Trigger and co-ordinate Packer, Terraform and Ansible pipelines.
- Drive application deployments to RKE2 and cloud environments.
- Integrate with evidence collection scripts and cost-aware DR workflows.

Jenkins is used as the primary CI orchestrator for:

- Packer image builds for Proxmox templates.
- Infrastructure provisioning and configuration (Terraform and Ansible).
- Application deployments to RKE2 (for example, NetBox) and future demo workloads.

Key questions:

- Where should the **Jenkins controller** run for reliability and simplicity?
- Where should **Jenkins agents** run to be close to workloads and infrastructure, without coupling the controller to any single cluster?
- How should this setup evolve as RKE2 becomes the primary runtime?

Options considered:

- Run both controller and agents on a single VM or LXC.
- Run controller and agents entirely on RKE2.
- Run controller on the Proxmox control node, with agents initially on Docker and later on RKE2.

This ADR records the standard for where the controller and agents live and how the system evolves.

## 2. Decision

HybridOps.Studio adopts the following pattern:

- The **Jenkins controller** runs as a Docker container on the Proxmox control node (`ctrl-01`).
- **Jenkins agents**:
  - Initially run as ephemeral Docker containers on `ctrl-01` during the early bootstrap phase.
  - Once the RKE2 cluster is deployed, move to running primarily as Kubernetes pods on RKE2 in a dedicated namespace.

Additional rules:

- The controller does not run inside RKE2, so that the CI brain is not lost if the cluster fails.
- Agent definitions (Kubernetes pod templates) are managed as code and can be recreated from Git.
- Agents are treated as stateless and disposable; they do not store long-lived artefacts locally.

## 3. Rationale

This split between controller and agents was chosen for the following reasons.

Separation of concerns and failure domains:

- The controller is part of the core control plane for the lab and should be available even when RKE2 is degraded or being rebuilt.
- Running the controller on `ctrl-01` reduces coupling to any one cluster, which is important for DR drills where RKE2 may be recreated from scratch.
- Agents running on RKE2 can be scaled and scheduled close to the workloads and services they interact with, improving performance and reducing network hops.

Operational simplicity:

- Running the controller on Docker on `ctrl-01` keeps installation and backup straightforward.
- The same control node already hosts Packer, Terraform, Ansible and related tooling, so Jenkins integrates directly with those tools.
- Using Kubernetes agents on RKE2 lets Jenkins benefit from the cluster’s scheduling, scaling and isolation without placing the controller at risk.

DR and evidence story:

- In DR scenarios where on-prem RKE2 is unavailable, the controller remains reachable on `ctrl-01` (or can be reinstated from backups) and can trigger DR orchestration workflows.
- Evidence 4 relies on this separation to show that:
  - CI/CD orchestration persists when the runtime cluster fails.
  - Clusters can be recreated and repopulated from Git without manually reconstructing Jenkins state.

Trade-offs:

- The control node (`ctrl-01`) becomes a critical dependency and must be monitored and backed up.
- There is a small amount of complexity in configuring agents both for local Docker and for RKE2.

## 4. Consequences

### 4.1 Positive consequences

- **Resilient CI control plane**
  - The Jenkins controller is not tied to the availability of any single RKE2 cluster.
  - DR workflows can be initiated even when the primary cluster is offline.

- **Better locality for pipelines**
  - Agents running on RKE2 execute jobs close to the workloads and platform services they manage.
  - Network-bound tasks (for example, `kubectl`, Helm, NetBox API calls) benefit from running in-cluster.

- **Clear migration story**
  - Early bootstrap can rely on Docker-only agents.
  - Once RKE2 is ready, workloads naturally migrate to RKE2 agents without changing the core controller setup.

### 4.2 Negative consequences and risks

- **Increased importance of ctrl-01**
  - Outages on `ctrl-01` affect Jenkins, even if RKE2 is healthy.
  - The node requires appropriate monitoring, backup and change control.

- **Dual agent configuration**
  - Some pipelines may need both local and RKE2-based agents, which must be documented and maintained.
  - Misconfiguration of agent labels could route jobs to the wrong environment.

Mitigations:

- Treat `ctrl-01` as part of the core control plane with appropriate runbooks and backup schedules.
- Maintain Jenkins configuration as code (for example, JCasC or scripted pipeline definitions) so that controller and agent configurations are reproducible.
- Use clear labels and conventions for agent types (for example, `ctrl-docker`, `rke2-agent`) and enforce them in pipeline code.

## 5. Alternatives considered

Controller and agents on a single VM or LXC:

- Simpler to set up initially.
- Tightens the failure domain; if that VM fails, both controller and agents are lost.
- Does not leverage RKE2’s scheduling and isolation capabilities.

Controller and agents entirely on RKE2:

- Makes Jenkins depend directly on the availability of the cluster it is managing.
- Complicates DR scenarios where RKE2 itself is being rebuilt.
- Increases the risk that a cluster-level failure removes the ability to coordinate recovery.

Multiple independent Jenkins controllers:

- Adds significant operational overhead for little additional benefit in a lab of this size.
- Diffuses configuration and makes evidence and audit trails harder to follow.

## 6. Implementation notes

Controller placement:

- Jenkins controller runs as a Docker container on `ctrl-01`, managed via systemd or a small wrapper script.
- Persistent data (JENKINS_HOME) is stored on a Proxmox-backed filesystem with regular backups.

Agent setup:

- Bootstrap phase:
  - Docker-based agents run on `ctrl-01` with access to local tools (Packer, Terraform, Ansible).
- Post-RKE2 phase:
  - Kubernetes-based agents are configured in Jenkins using the Kubernetes plugin or equivalent.
  - Agents run in a dedicated RKE2 namespace with appropriate RBAC and network policies.

Configuration as code:

- Jenkins pipelines and job definitions (including which agents to use) are stored in Git.
- Any JCasC or scripted configuration is versioned alongside the rest of the control node configuration.

Evidence:

- Evidence 4 references:
  - Jenkins pipelines that invoke Packer, Terraform, Ansible and RKE2 operations.
  - Screenshots and logs showing agents running first on Docker and later as pods in RKE2.
- Additional proof can be captured under:
  - [`docs/proof/infra/jenkins/`](../../docs/proof/infra/jenkins/) — controller and agent configuration.
  - [`docs/proof/ci/`](../../docs/proof/ci/) — pipeline runs and screenshots.

## 7. Operational impact and validation

Operational impact:

- Platform and SRE teams must:
  - Monitor Jenkins controller health and job execution.
  - Ensure `ctrl-01` is treated as a critical node with backups and access controls.
  - Keep agent configurations consistent with platform evolution (for example, when RKE2 namespaces change).

Validation:

- Runbooks to be created:
  - Jenkins controller outage on `ctrl-01`.
  - Jenkins agent troubleshooting (Docker and RKE2-based).
- HOWTOs to be created:
  - Configure Jenkins agents on RKE2.
  - Run Packer and RKE2 pipelines via Jenkins.
- Evidence folders:
  - docs/proof/infra/jenkins/
  - docs/proof/ci/

Validation is considered successful when:

- Pipelines can be executed end-to-end using both Docker-based and RKE2-based agents where appropriate.
- DR drills demonstrate that Jenkins remains available when RKE2 is being rebuilt, and that agents can be recreated from configuration as code.

## 8. References

- [ADR-0001 – ADR Process and Conventions](../adr/ADR-0001-adr-process-and-conventions.md)
- [ADR-0202 – Adopt RKE2 as Primary Runtime for Platform and Applications](../adr/ADR-0202-rke2-primary-runtime-for-platform-and-apps.md)
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)
- [Jenkins documentation](https://www.jenkins.io)

---

**Maintainer:** HybridOps.Studio
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
