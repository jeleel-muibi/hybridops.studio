---
id: ADR-0202
title: "Adopt RKE2 as Primary Runtime for Platform & Applications"
status: Accepted
date: 2025-12-01
category: "02-platform"

domains: ["platform", "sre", "infra"]
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
tags: ["platform", "kubernetes", "rke2"]
access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""

---

# Adopt RKE2 as Primary Runtime for Platform & Applications

## Status
Accepted — RKE2 is the primary runtime for platform and application workloads on HybridOps.Studio, with Kubernetes treated as stateless compute and PostgreSQL LXC as the main state layer.

## 1. Context

HybridOps.Studio needs a Kubernetes runtime to host:

- Core platform services (ingress, observability, GitOps, secrets, storage add-ons).
- Delivery tooling components that benefit from running close to workloads (for example, Jenkins agents).
- User-facing applications and demos, such as NetBox and future academy examples.

Constraints and goals:

- Reuse the existing Proxmox environment and Packer-built VM templates.
- Keep cluster operations understandable for a small team while still being realistic for enterprise environments.
- Support hybrid topologies where on-prem is the default and cloud clusters are used for DR and burst.
- Keep stateful databases outside the cluster so that Kubernetes can be treated as largely stateless compute.

Runtime options considered:

- Vanilla Kubernetes via kubeadm.
- K3s.
- RKE2 (Rancher Kubernetes Engine 2).
- Managed cloud Kubernetes only (AKS, GKE, EKS).

This ADR scopes the primary runtime for platform and application workloads. It does not prevent using other runtimes for experiments or short-lived test clusters.

## 2. Decision

HybridOps.Studio standardises on RKE2 as the primary Kubernetes runtime for:

- Core platform services (ingress, metrics, GitOps, ESO, Longhorn and related add-ons).
- Delivery tooling agents (Jenkins agents and similar worker pods).
- Application workloads that follow the pattern “stateless in-cluster, state in external services”.

Key aspects of the standard:

- RKE2 control-plane and worker nodes are provisioned as Proxmox VMs from Packer-built templates.
- RKE2 is organised into namespaces for platform, network and application workloads.
- Primary state (for example, the NetBox database) is not hosted in-cluster; it resides in PostgreSQL LXC (db-01) per ADR-0013.
- K3s and ad-hoc Docker/Kubernetes setups on individual nodes are considered non-standard and used only for local tests.

## 3. Rationale

RKE2 was selected for the following reasons.

Security and defaults:

- Hardened, opinionated distribution with sensible defaults.
- Clear separation between control-plane and data-plane components.
- Closer to “secure by default” than a bare kubeadm installation for a small team.

Operational simplicity:

- Single installer and configuration style that is easy to drive from Ansible and Terraform.
- Upgrade and node join/leave flows are straightforward to automate.
- Good ecosystem support for standard CNIs, storage providers and ingress controllers.

Hybrid suitability:

- Works well on on-prem and edge nodes while remaining compatible with cloud.
- Easy to reproduce an RKE2 cluster in cloud for DR or burst scenarios when required.

Alignment with HybridOps.Studio goals:

- Provides one main runtime for platform, delivery and application workloads.
- Matches the Evidence 4 story: Jenkins plus Packer plus Terraform and Ansible lead into RKE2 and applications, with PostgreSQL LXC as state.
- Gives realistic material for Academy content and DR drills.

Trade-offs:

- RKE2 is another control plane to manage, in addition to Proxmox and other infrastructure components.
- The opinionated nature of RKE2 means some cluster-level customisations follow its patterns rather than pure upstream kubeadm.

## 4. Consequences

### 4.1 Positive consequences

- Single primary Kubernetes story:
  - Platform add-ons, applications and Jenkins agents converge on RKE2.
  - Documentation and Academy material can assume RKE2 as the platform runtime.

- Clear separation of compute and state:
  - It is explicit that RKE2 is not the primary home for critical databases.
  - PostgreSQL LXC can be backed up, replicated and promoted independently of the cluster.

- Better DR modelling:
  - DR and burst scenarios can rebuild or recreate RKE2 clusters without embedded state recovery.
  - Evidence 4 can demonstrate failover patterns where RKE2 is replaced rather than repaired in place.

### 4.2 Negative consequences and risks

- Additional operational surface area:
  - RKE2 must be monitored, patched and upgraded similar to any other critical component.
  - Misconfiguration can impact many workloads at once.

- Temptation to host state in-cluster:
  - Longhorn makes it easy to run stateful workloads on RKE2.
  - Without discipline, critical services might be moved into the cluster, undermining the external-state design.

- Vendor-specific knowledge:
  - Although CNCF aligned, RKE2 has its own packaging and conventions, which require learning and maintenance.

Mitigations:

- Define clear eligibility rules for which workloads may use in-cluster persistent volumes versus PostgreSQL LXC.
- Maintain runbooks for RKE2 upgrades and failure scenarios.
- Use Prometheus and Alertmanager to track control-plane health and capture evidence of upgrades and DR drills.

## 5. Alternatives considered

Vanilla Kubernetes via kubeadm:

- Rejected for now due to higher operational overhead and boilerplate.
- Suitable when a larger team needs finer control over all components; less compelling for a small platform team.

K3s as primary runtime:

- Attractive for small-footprint clusters, but:
  - RKE2 offers stronger defaults for separation and security.
  - RKE2 aligns better with a “production-like” narrative for Evidence 4.
- K3s may still be used for disposable test clusters or edge labs, but not as the primary runtime.

Managed cloud Kubernetes only (AKS, GKE, EKS):

- Would undermine the hybrid and cost-aware positioning of HybridOps.Studio.
- On-prem is intentionally the default, with cloud reserved for DR and burst; making cloud the only runtime conflicts with that design.

## 6. Implementation notes

Node provisioning:

- RKE2 nodes are created as Proxmox VMs from Packer templates in infra/packer-multi-os/.
- Terraform and Ansible are used to:
  - Allocate VMs (CPU, RAM, storage, networks).
  - Install and configure RKE2 control-plane and worker nodes.

Cluster layout:

- Minimum of three control-plane nodes for resilience, plus one or more worker pools.
- Namespaces:
  - platform-* for core services and add-ons.
  - network-* for NetBox and related tooling.
  - apps-* for user and demo applications.

Add-ons:

- Longhorn, External Secrets Operator, GitOps controller and observability stack are deployed onto RKE2.
- Jenkins agents run as pods in a dedicated namespace, with the Jenkins controller remaining on the Proxmox control node.

Evidence:

- Evidence of this decision appears in:
  - [`docs/proof/infra/rke2/`](../../docs/proof/infra/rke2/) — cluster bootstrap logs and kubectl outputs.
  - [`docs/proof/apps/netbox/`](../../docs/proof/apps/netbox/) — NetBox migration from Docker to RKE2.
  - [`docs/proof/dr/`](../../docs/proof/dr/) — DR drills involving on-prem and cloud RKE2 clusters.

## 7. Operational impact and validation

Operational impact:

- Platform and SRE teams must:
  - Monitor RKE2 control-plane and node health.
  - Plan and execute upgrades using documented runbooks.
  - Ensure that new workloads comply with the principle “stateless in-cluster, state outside”, unless explicitly justified.

Validation:

- Runbooks to be created:
  - RKE2 upgrade runbook.
  - RKE2 control-plane outage response.
- HOWTOs to be created:
  - Bootstrap an RKE2 cluster from Proxmox templates.
  - Deploy and migrate NetBox from Docker to RKE2.
- Evidence folders:
  - docs/proof/infra/rke2/ for cluster bring-up and upgrade logs.
  - docs/proof/apps/netbox/ for application deployment and migration.
  - docs/proof/dr/ for DR drills involving RKE2.

Successful execution of these runbooks and HOWTOs, along with metrics from Prometheus and Grafana, will validate that RKE2 is operating as the primary runtime in line with this ADR.

## 8. References

- [ADR-0001 – ADR Process and Conventions](../adr/ADR-0001-adr-process-and-conventions.md)
- [ADR-0013 – PostgreSQL Runs in LXC (State on Host-Mounted Storage; Backups First-Class)](../adr/ADR-0013_postgresql-as-lxc.md)
- [Evidence 3 – Source of Truth and Network Automation](../evidence/evidence-03-source-of-truth-netbox-automation.md)
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)
- [RKE2 documentation](https://docs.rke2.io)

---

**Maintainer:** HybridOps.Studio
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
