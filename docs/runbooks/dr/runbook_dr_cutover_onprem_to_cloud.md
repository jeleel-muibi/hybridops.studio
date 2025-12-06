---
title: "DR Cutover – On-Prem RKE2 to Cloud Cluster"
category: "dr"               # bootstrap | dr | burst | ops | platform | networking | tooling.
summary: "Execute a controlled DR cutover from the on-prem RKE2 cluster to a cloud-based cluster using GitHub Actions, with cost guardrails and evidence capture."
severity: "P1"               # P1 = critical, P2 = high, P3 = normal.

topic: "dr-cutover-onprem-cloud"

draft: false
is_template_doc: false
tags: ["dr", "rke2", "cloud", "github-actions", "prometheus", "dns"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""

---

# DR Cutover – On-Prem RKE2 to Cloud Cluster

**Purpose:** Perform a controlled DR cutover from the on-prem RKE2 cluster to a cloud-based RKE2/managed cluster when the on-prem platform is unavailable or outside SLO.  
**Owner:** Platform / SRE team (HybridOps.Studio)  
**Trigger:** Prometheus/Alertmanager `jenkins_critical_down` or `rke2_cluster_unhealthy` alert, or a scheduled DR drill.  
**Impact:** Changes the active production control-plane and workloads from on-prem RKE2 to a cloud cluster; DNS / Front Door endpoints will point to cloud.  
**Severity:** P1 – platform-level outage or DR drill simulating such an outage.  
**Pre-reqs:** On-prem and cloud environments configured; DR workflows defined in GitHub Actions; Cost Decision Service configured and tested.

---

## 1. Scenario overview

This runbook covers the **active cutover** from:

- Primary: on-prem RKE2 cluster.
- Secondary: DR/cloud RKE2 or managed Kubernetes cluster.

Automation is driven by:

- **Prometheus federation + Alertmanager** for detection and alerts.  
- **GitHub Actions** as the stateless DR orchestrator (see ADR-0701).  
- A **Cost Decision Service** that checks cost artefacts before scaling or promoting the cloud environment (see ADR-0801).

You can use this runbook for:

- Live incidents (on-prem RKE2 or Jenkins unavailable beyond SLO).  
- Scheduled DR drills to validate procedures and artefacts.

---

## 2. Preconditions and checks

Before proceeding:

1. Confirm the alert:

   - Check Alertmanager for:
     - `jenkins_critical_down`
     - `rke2_cluster_unhealthy`
     - Any relevant SLO breach alerts for critical workloads (e.g. NetBox).
   - Ensure alerts are not caused by a short-lived blip (for example, a brief maintenance window).

2. Confirm on-prem status:

   - Attempt `kubectl get nodes` against the on-prem RKE2 cluster.
   - Check Jenkins controller status on `ctrl-01` if accessible.
   - If access is possible and the issue is minor, consider standard remediation before DR.

3. Confirm cloud DR readiness:

   - Verify the last successful DR drill or DR prep run:
     - Check GitHub Actions history for DR-related workflows.
     - Confirm the last known-good run did not report errors during cloud cluster bootstrap.

4. Confirm stakeholder approvals:

   - For real incidents (not drills), ensure incident lead / product owner has approved initiating DR cutover.
   - For scheduled drills, ensure announcement/communications are in place if this is visible to users.

---

## 3. Phase 1 – Initiate DR workflow and cost check

> Goal: Start the DR pipeline and ensure cost guardrails are respected before scaling the cloud environment.

1. From GitHub, navigate to the repository containing DR workflows (for example, `hybridops-studio/infra-dr` or the main repo if workflows live there).
2. Open the DR cutover workflow (for example: `dr-cutover-onprem-to-cloud.yml`).
3. Manually dispatch the workflow if it has a **`workflow_dispatch`** trigger, or confirm it was triggered automatically by `repository_dispatch` from the alert webhook.
4. When prompted for parameters (if applicable), supply:
   - `environment`: `dr-test` or `dr-prod` (as appropriate).
   - `reason`: short description referencing the incident or drill ID.
5. Monitor the early stages of the workflow logs:
   - Confirm it runs the **Cost Decision Service** step.
   - Verify that it loads cost artefacts (for example, from [`docs/proof/cost/`](../../docs/proof/cost/)) and reports:
     - Projected cost.
     - Threshold / budget.
     - Decision: **ALLOW** or **DENY**.

### If cost decision is DENY

- For drills:
  - Record the result; do **not** override unless the drill explicitly tests override flow.
  - File a follow-up to adjust cost model or thresholds if appropriate.
- For real incidents:
  - Escalate to the incident commander / product owner:
    - Present projected cost vs threshold.
    - If override is agreed, follow the manual override process (for example, re-run workflow with an `override=true` flag or a separate override workflow).
  - Document the override in the incident notes.

Do not proceed with full cutover steps until the cost decision is **ALLOW** or an override has been explicitly approved.

---

## 4. Phase 2 – Bring up or scale the cloud cluster

> Goal: Ensure the cloud cluster is running at the desired capacity and can host the workloads.

The DR workflow should:

1. Apply Terraform/Ansible (or equivalent) steps to:
   - Create or scale the cloud RKE2/managed cluster.
   - Ensure node pools and system components are ready.
2. Capture logs and plan/apply outputs into:
   - [`docs/proof/infra/rke2/`](../../docs/proof/infra/rke2/)
   - [`docs/proof/dr/`](../../docs/proof/dr/)

While the workflow runs:

1. From a shell with access to the cloud cluster, verify:

   ```bash
   export KUBECONFIG=~/.kube/rke2-cloud-dr.yaml
   kubectl get nodes -o wide
   kubectl get pods -A
   ```

2. Confirm:
   - All core system pods are `Running` or `Completed`.
   - No critical components are crashlooping (for example, ingress controller, DNS, CNI).

If the cloud cluster does not stabilise:

- Pause DR cutover.
- Investigate and remediate (node capacity, network, control-plane issues).
- Only proceed once the cluster is healthy.

---

## 5. Phase 3 – Deploy workloads and data dependencies

> Goal: Ensure Jenkins, NetBox and other critical workloads are deployed and wired to the right data stores.

1. Confirm that the DR workflow (or a follow-on pipeline) has:

   - Deployed platform components (ingress, ESO, Longhorn, observability stack).
   - Deployed application workloads (for example, NetBox) using GitOps manifests.

2. Validate data dependencies:

   - Confirm the DR PostgreSQL replica has been promoted to primary (if applicable).
   - Check that workloads such as NetBox are pointing to the **cloud** PostgreSQL instance, not the on-prem LXC.

3. Basic application checks:

   - `kubectl get svc -A` to confirm services and ingress resources exist.
   - Application-level health checks (for example, HTTP 200 from NetBox `/health` endpoint) via port-forward or the cluster ingress.

Record key `kubectl` outputs and any application health screenshots/logs under:

- [`docs/proof/dr/`](../../docs/proof/dr/)
- [`docs/proof/apps/netbox/`](../../docs/proof/apps/netbox/) if NetBox is in scope.

---

## 6. Phase 4 – Cut over DNS / Front Door

> Goal: Switch user-facing traffic from on-prem to the cloud cluster in a controlled manner.

1. Identify the current ingress path:

   - DNS record(s) pointing to on-prem ingress or
   - Azure Front Door or equivalent configuration used as the main entry point.

2. Prepare the new endpoints:

   - Confirm the cloud ingress / Front Door backend for the DR cluster is:
     - Healthy in the load balancer view.
     - Returning expected responses.

3. Apply the cutover:

   - Update DNS records to point to the cloud entry point, **or**
   - Update Azure Front Door (or equivalent) to route traffic to the cloud backend instead of on-prem.

4. Monitor:

   - Application logs for increased traffic on the cloud cluster.
   - Error rates and latency via Prometheus/Grafana or cloud-native monitoring.

Document:

- Exact time of cutover.
- Records or Front Door configuration changes.
- Screenshots / CLI outputs as needed.

Store these under:

- [`docs/proof/dr/`](../../docs/proof/dr/)
- Any scenario-specific subfolder (for example, `dr-<date>-onprem-to-cloud/`).

---

## 7. Phase 5 – Post-cutover monitoring and stabilisation

For at least the first 30–60 minutes after cutover:

1. Monitor:

   - Application SLOs (availability, latency).
   - Error budgets for critical paths.
   - Infrastructure health (node utilisation, pod restarts).

2. Address any urgent issues:

   - Scale node pools or replicas as needed, within cost guardrails.
   - Roll out configuration changes or hotfixes via GitOps/CI where necessary.

3. Confirm with stakeholders:

   - Business/product owners are aware the service is now running in DR/cloud.
   - Any temporary limitations (for example, reduced capacity or disabled non-critical features) are known.

---

## 8. Phase 6 – Evidence and documentation

Before closing the runbook:

1. Ensure the DR workflow run in GitHub Actions has:

   - Completed successfully.
   - Logs and artefacts archived as needed.

2. Verify the following proof locations contain up-to-date artefacts for this DR event:

   - [`docs/proof/dr/`](../../docs/proof/dr/)
   - [`docs/proof/infra/rke2/`](../../docs/proof/infra/rke2/)
   - [`docs/proof/cost/`](../../docs/proof/cost/)

3. Update:

   - Incident or drill ticket with links to:
     - The GitHub Actions run.
     - Relevant proof folders.
     - Any dashboards used during the event.

4. If this was a drill:

   - Capture lessons learned.
   - File follow-up tasks for:
     - Runbook clarifications.
     - Automation improvements.
     - Cost model adjustments.

---

## 9. Rollback / failback (summary)

A full failback procedure should be covered in a dedicated runbook, but at a high level:

1. Restore on-prem RKE2 and platform to a healthy state.
2. Re-sync data from the cloud primary back to on-prem (or promote a new primary).
3. Reverse DNS / Front Door changes once on-prem is ready and validated.
4. De-scale or tear down DR resources as appropriate, following cost guardrails.

Link this runbook to the failback runbook once that document is created.

---

## 10. Validation checklist

- [ ] Alerts indicate a sustained on-prem platform problem (not a brief blip).  
- [ ] Cost Decision Service authorised the DR action or a documented override was approved.  
- [ ] Cloud cluster is healthy and running core platform components.  
- [ ] Critical workloads (for example, NetBox, Jenkins agents) are running and wired to the correct data stores.  
- [ ] DNS / Front Door cutover completed and traffic now flows to the cloud cluster.  
- [ ] Application SLOs are within acceptable ranges post-cutover.  
- [ ] Evidence folders under [`docs/proof/dr/`](../../docs/proof/dr/), [`docs/proof/infra/rke2/`](../../docs/proof/infra/rke2/), and [`docs/proof/cost/`](../../docs/proof/cost/) have been updated and linked to the incident or drill ticket.  

---

## References

- [ADR-0202 – Adopt RKE2 as Primary Runtime for Platform and Applications](../adr/ADR-0202-rke2-primary-runtime-for-platform-and-apps.md)  
- [ADR-0701 – Use GitHub Actions as Stateless DR Orchestrator](../adr/ADR-0701-github-actions-stateless-dr-orchestrator.md)  
- [ADR-0801 – Treat Cost as a First-Class Signal for DR and Cloud Bursting](../adr/ADR-0801-cost-first-class-signal-dr-bursting.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  
- [`docs/proof/dr/`](../../docs/proof/dr/)  
- [`docs/proof/infra/rke2/`](../../docs/proof/infra/rke2/)  
- [`docs/proof/cost/`](../../docs/proof/cost/)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation
