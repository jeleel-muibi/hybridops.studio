---
id: ADR-0402
title: "Use Prometheus Federation as Central DR Signal Plane"
status: Accepted
date: 2025-12-02
category: "04-observability"   # One of:
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

domains: ["observability", "sre"]
owners: ["HybridOps.Studio"]
supersedes: []
superseded_by: []

links:
  prs: []
  runbooks:
    - "../runbooks/dr/runbook_dr_cutover_onprem_to_cloud.md"
    - "../runbooks/dr/runbook_dr_failback_cloud_to_onprem.md"
    - "../runbooks/dr/runbook_cost_guardrail_breach.md"
  howtos:
    - "../howtos/HOWTO_dr_cost_drill.md"
  evidence:
    - "../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md"
  diagrams: []
  related_docs:
    - "./ADR-0401-unified-observability-with-prometheus.md"
    - "./ADR-0701-github-actions-stateless-dr-orchestrator.md"
    - "./ADR-0801-cost-first-class-signal-dr-bursting.md"
---

_Status: Accepted (2025-12-02)_

---

# Use Prometheus Federation as Central DR Signal Plane

## 1. Context

HybridOps.Studio runs:

- On-prem RKE2 clusters on Proxmox.  
- (Optionally) cloud-based clusters or services used for DR and bursting.  

Per ADR-0401 (**Unified Observability with Prometheus**), each environment exposes metrics to a common Prometheus and Grafana stack. Local Prometheus instances (where present) scrape:

- Node and workload metrics.  
- Application SLOs such as NetBox availability or Jenkins controller health.

For DR and cost-aware automation, we need a **single, aggregated signal plane** that:

- Sees the health of key components across environments.  
- Drives alerts into Alertmanager, which in turn triggers GitHub Actions workflows (ADR-0701).  
- Feeds into the Cost Decision Service for DR/burst decisions (ADR-0801).

Relying on ad-hoc alerts in individual Prometheus instances makes it harder to:

- Encode cross-environment conditions (for example, on-prem down while cloud is up).  
- Maintain a stable interface for DR automation over time.

## 2. Decision

HybridOps.Studio uses **Prometheus federation** to build a **central DR signal plane**:

- Local Prometheus instances scrape metrics in their own environment (on-prem, cloud).  
- A central Prometheus instance federates selected metrics from those locals, focusing on:
  - Platform health (RKE2, nodes, Longhorn, PostgreSQL proxies).  
  - CI/CD health (Jenkins controller, job success).  
  - Application SLOs (for example, NetBox availability).  

Alerting rules for DR-related events (for example, `jenkins_critical_down`, `platform_unavailable`) are defined on the **federated** Prometheus instance and routed via Alertmanager into:

- Human channels (Slack/Teams/email).  
- A DR webhook that drives GitHub Actions DR and cost-aware workflows.

This ADR builds on ADR-0401 by specialising a subset of metrics and alerts into a **DR-focused signal plane**.

## 3. Rationale

### 3.1 Why federation instead of one huge Prometheus?

- Each environment retains **local ownership** of its metrics and scrape configs.  
- The central Prometheus focuses on:
  - Aggregated views, and  
  - DR-related signals, not every metric.  
- It reduces risk:
  - A failure of the central instance does not stop local monitoring.  
  - DR detection can still be enhanced or migrated without rewriting all local scrape configs.

### 3.2 Why use the federated plane for DR signals?

DR actions depend on **cross-environment context**:

- Is on-prem down or just slow?  
- Are cloud DR resources already active?  
- Are key applications (for example, NetBox, Jenkins) meeting SLOs?

Federation lets us encode alerts that consider:

- Multiple clusters, and  
- Multiple components (for example, Jenkins + RKE2 API + application SLOs).

This supports Evidence 4’s story:

- DR and burst workflows are triggered off **federated health**, not isolated local signals.

## 4. Consequences

### 4.1 Positive

- **Centralised DR alerting logic**  
  - DR alert rules live in one place with a global view.

- **Local autonomy preserved**  
  - Each environment maintains its own scraping, retention and dashboards.  

- **Clear integration point for GitHub Actions and Cost Decision Service**  
  - Alertmanager attached to the federated Prometheus becomes the bridge into automation.

### 4.2 Negative / trade-offs

- **Additional Prometheus to operate**  
  - Federation adds another Prometheus instance to maintain.

- **Careful metric selection required**  
  - Pulling too many metrics via federation can increase load and complexity.  
  - The central plane should only federate DR-relevant series.

## 5. Implementation

### 5.1 Federation targets

The central Prometheus is configured with federation jobs that:

- Scrape `/federate` endpoints of local Prometheus instances.  
- Select metrics that matter for:
  - Platform health,
  - CI/CD health,
  - Application SLOs,
  - Cost-related usage signals (for example, node counts).

Metric selection is kept deliberately narrow to avoid turning the federated instance into a second full observability stack.

### 5.2 Alerting

- DR alerts (for example, `jenkins_critical_down`, `platform_unavailable`, `dr_drill_test`) are defined on the federated Prometheus instance.  
- Alertmanager routes are configured to:

  - Notify humans, and  
  - Call the DR webhook that drives GitHub Actions workflows.

Alert naming and labels are aligned with:

- ADR-0701 (GitHub Actions DR orchestrator).  
- ADR-0801 (Cost Decision Service signals).

### 5.3 DR drill integration

DR drill HOWTOs (for example, cost-aware DR drill) assume:

- The federated Prometheus and Alertmanager plane is the origin of DR alerts.  

This keeps the DR runbooks and HOWTOs stable even if local Prometheus instances or exporters change, as long as the federated plane continues to expose a consistent set of DR-oriented metrics and alerts.

## 6. Operational considerations

- Federated Prometheus must be:

  - Monitored and backed up.  
  - Included in DR plans itself (for example, either easily rebuilt from config or run in a resilient environment).

- Documentation and Academy material should:

  - Show how a local metric flows into the federated plane.  
  - Show how that metric contributes to a DR alert and GitHub Actions workflow.

- Changes to DR alert rules should follow the same review discipline as:

  - CI/CD pipeline changes.  
  - Cost guardrail and DR policy changes.

## 7. References

- [ADR-0401 – Unified Observability with Prometheus](./ADR-0401-unified-observability-with-prometheus.md)  
- [ADR-0701 – Use GitHub Actions as Stateless DR Orchestrator](./ADR-0701-github-actions-stateless-dr-orchestrator.md)  
- [ADR-0801 – Treat Cost as a First-Class Signal for DR and Cloud Bursting](./ADR-0801-cost-first-class-signal-dr-bursting.md)  
- [HOWTO – Run a Cost-Aware DR Drill (Prometheus → GitHub Actions → DR Workflow)](../howtos/HOWTO_dr_cost_drill.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation
