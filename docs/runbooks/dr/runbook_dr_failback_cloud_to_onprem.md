---
title: "Failback – Cloud Cluster to On-Prem RKE2"
category: "dr"               # bootstrap | dr | burst | ops | platform | networking | tooling.
summary: "Return production traffic and workloads from the cloud DR cluster back to the on-prem RKE2 cluster in a controlled, evidence-backed way."
severity: "P2"               # P1 = critical, P2 = high, P3 = normal.

topic: "dr-failback-cloud-onprem"

draft: false
is_template_doc: false
tags: ["dr", "failback", "rke2", "cloud", "dns", "postgresql"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""

---

# Failback – Cloud Cluster to On-Prem RKE2

**Purpose:** Safely return primary workloads and traffic from the **cloud DR/cluster** back to the **on-prem RKE2 cluster** after an incident has been resolved or a DR drill has completed.  
**Owner:** Platform / SRE team (HybridOps.Studio)  
**Trigger:** On-prem RKE2 and supporting services are healthy again, and incident command approves failback.  
**Impact:** Production control-plane and workloads move from cloud to on-prem; DNS / Front Door endpoints revert to on-prem.  
**Severity:** P2 – high-impact change but usually performed during stabilised conditions.  
**Pre-reqs:** On-prem environment restored and validated; DR cutover runbook has previously been executed.

---

## 1. Scenario overview

This runbook assumes:

- You previously executed **DR cutover** from on-prem to cloud using the DR runbook:
  - [Runbook – DR Cutover: On-Prem RKE2 to Cloud Cluster](../runbooks/dr/runbook_dr_cutover_onprem_to_cloud.md)
- On-prem RKE2, PostgreSQL LXC and related services have been repaired or rebuilt and are now healthy.
- Cloud DR resources are still running and serving production traffic.

The goal is to:

1. Confirm on-prem is ready to resume as primary.
2. Re-sync or promote data back to on-prem if needed.
3. Swap traffic (DNS / Front Door) back to on-prem.
4. De-scale cloud DR resources within cost and risk tolerances.
5. Capture full evidence for the failback operation.

---

## 2. Preconditions and checks

Before starting failback:

1. **Verify on-prem RKE2 health**

   - From the control node, ensure:

     ```bash
     export KUBECONFIG=~/.kube/rke2-hybridops-onprem.yaml
     kubectl get nodes -o wide
     kubectl get pods -A
     ```

   - All control-plane and worker nodes must be `Ready`.
   - Core system components (CNI, DNS, ingress, metrics) must be healthy.

2. **Verify PostgreSQL LXC state**

   - Confirm the primary PostgreSQL LXC on-prem (for example, `db-01`) is:
     - Running on the correct Proxmox node.
     - Passing basic health checks (for example, `psql` connectivity, replication status if used).
   - Ensure its data is up to date or that you have a plan to refresh from the cloud DB.

3. **Confirm cloud cluster state**

   - Validate the cloud cluster is currently serving production traffic and is healthy:

     ```bash
     export KUBECONFIG=~/.kube/rke2-cloud-dr.yaml
     kubectl get nodes -o wide
     kubectl get pods -A
     ```

4. **Stakeholder approval**

   - Incident commander / product owner confirms:
     - It is acceptable to schedule a failback window.
     - Any user-facing impact is documented and communicated.

5. **Evidence location**

   - Decide a folder for this failback event under:

     - [`docs/proof/dr/`](../../docs/proof/dr/)

   - For example: `docs/proof/dr/failback-<date>-cloud-to-onprem/`.

---

## 3. Phase 1 – Prepare on-prem environment for primary role

> Goal: Ensure on-prem RKE2 and PostgreSQL are ready to become authoritative again.

1. **Synchronise application configuration**

   - Ensure GitOps manifests or Helm values for on-prem RKE2 are:
     - Up to date with any changes made during DR.
     - Reviewed to avoid drift between cloud and on-prem environments.

2. **Database/data sync strategy**

   - If the cloud DB is currently primary:
     - Either perform a controlled replication back to on-prem, or
     - Export/import data in a planned maintenance window aligned with application expectations.
   - Ensure any decisions here are documented and appropriate for the system’s data consistency model.

3. **Dry-run application deployments**

   - For key workloads (for example, NetBox, supporting platform services), run:
     - A dry-run apply via GitOps/Helm where supported.
   - Check that there are no obvious configuration errors (missing secrets, bad endpoints).

4. **Record pre-failback state**

   - Capture basic evidence of on-prem readiness:

     ```bash
     kubectl get nodes -o wide > docs/proof/dr/failback-<date>-cloud-to-onprem/kubectl-nodes-onprem-before.txt
     kubectl get pods -A > docs/proof/dr/failback-<date>-cloud-to-onprem/kubectl-pods-all-onprem-before.txt
     ```

   - Replace `<date>` with your actual event stamp.

---

## 4. Phase 2 – Coordinate data and application cutover

> Goal: Minimise data inconsistency during the switch from cloud to on-prem.

1. **Quiesce writes if required**

   - For workloads that require strong consistency:
     - Coordinate a short freeze of write operations (for example, maintenance mode, brief downtime).
   - For read-heavy / eventually consistent workloads:
     - Document the acceptable level of risk and behaviour.

2. **Final data sync**

   - Run the final sync or promotion of the on-prem database:
     - Ensure on-prem PostgreSQL is now the primary.
     - Confirm replication and/or application configuration reflects this.

3. **Update application connections**

   - Confirm RKE2 workloads on-prem point to the on-prem PostgreSQL instance.
   - In cloud DR cluster, ensure applications either:
     - Are drained/disabled, or
     - Clearly flagged as secondary/non-serving instances.

4. **Sanity checks**

   - Run application-level health checks on on-prem (for example, NetBox `/health` endpoint).
   - Verify that the on-prem environment can serve test traffic before DNS/Front Door changes.

Record these steps and outputs in the failback proof folder.

---

## 5. Phase 3 – Switch traffic back to on-prem

> Goal: Move user-facing traffic from cloud cluster to on-prem RKE2.

1. **Prepare DNS / Front Door changes**

   - Identify current configuration:
     - DNS records pointing to cloud, or
     - Azure Front Door / load balancer using the cloud cluster as backend.

2. **Update configuration**

   - Update DNS records to point back to the on-prem ingress/entry point, or
   - Update Front Door / load balancer to:
     - Restore on-prem backend as primary.
     - Optionally keep cloud as warm standby with reduced weight.

3. **Monitor propagation and behaviour**

   - As DNS/Front Door changes propagate:
     - Monitor application logs and metrics on on-prem:
       - Traffic increasing.
       - Error rates and latency within SLO.
     - Monitor cloud cluster to ensure traffic is decreasing as expected.

4. **Record cutover details**

   - Note the exact time of failback.
   - Archive configuration changes (for example, before/after snippets of DNS or Front Door config) into the proof folder.

---

## 6. Phase 4 – De-scale or decommission DR resources

> Goal: Reduce cloud DR footprint while staying within cost and resilience targets.

1. **Run DR teardown/de-scale workflow**

   - Use a dedicated GitHub Actions workflow (for example, `dr-scale-down-cloud.yml`) that:
     - Scales down DR node pools.
     - Optionally decommissions non-essential DR resources.
     - Leaves minimal capacity for monitoring and future drills.

2. **Cost check**

   - Confirm that post-failback cost artefacts under:

     - [`docs/proof/cost/`](../../docs/proof/cost/)

     reflect the updated, reduced DR spend.

3. **Validate residual DR posture**

   - Ensure any remaining cloud resources are:
     - Clearly labelled as DR.
     - Documented in DR inventory.
   - Confirm that next DR drill can still spin up capacity quickly from this baseline.

---

## 7. Phase 5 – Post-failback monitoring and close-out

1. **Monitor on-prem platform**

   - Continue to watch:
     - RKE2 node and pod health.
     - Application SLOs and error budgets.
     - PostgreSQL LXC health and backups.

2. **Confirm with stakeholders**

   - Communicate that:
     - Primary operations are now fully back on on-prem RKE2.
     - DR/cloud resources have been de-scaled as per plan.

3. **Update documentation**

   - Update incident/drill records with:
     - Start/end times for DR and failback.
     - Any manual interventions or issues encountered.
   - File follow-up tasks for:
     - Runbook improvements.
     - Automation adjustments.
     - Cost model tweaks.

---

## 8. Validation checklist

- [ ] On-prem RKE2 cluster is healthy and running core platform workloads.  
- [ ] On-prem PostgreSQL LXC is primary and serving expected applications.  
- [ ] Cloud DR cluster is no longer the primary entry point for user traffic.  
- [ ] DNS / Front Door configuration now points to on-prem.  
- [ ] Cloud DR resources are scaled down to agreed baseline levels.  
- [ ] Evidence for failback is stored under [`docs/proof/dr/`](../../docs/proof/dr/) and, where relevant, [`docs/proof/infra/rke2/`](../../docs/proof/infra/rke2/) and [`docs/proof/cost/`](../../docs/proof/cost/).  
- [ ] Stakeholders have confirmed that failback is complete and stable.  

---

## References

- [Runbook – DR Cutover: On-Prem RKE2 to Cloud Cluster](../runbooks/dr/runbook_dr_cutover_onprem_to_cloud.md)  
- [ADR-0202 – Adopt RKE2 as Primary Runtime for Platform and Applications](../adr/ADR-0202-rke2-primary-runtime-for-platform-and-apps.md)  
- [ADR-0701 – Use GitHub Actions as Stateless DR Orchestrator](../adr/ADR-0701-github-actions-stateless-dr-orchestrator.md)  
- [ADR-0801 – Treat Cost as a First-Class Signal for DR and Cloud Bursting](../adr/ADR-0801-cost-first-class-signal-dr-bursting.md)  
- [ADR-0013 – PostgreSQL Runs in LXC (State on Host-Mounted Storage; Backups First-Class)](../adr/ADR-0013_postgresql-as-lxc.md)  
- [Evidence 3 – Source of Truth and Network Automation](../evidence/evidence-03-source-of-truth-netbox-automation.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  
- [`docs/proof/dr/`](../../docs/proof/dr/)  
- [`docs/proof/infra/rke2/`](../../docs/proof/infra/rke2/)  
- [`docs/proof/cost/`](../../docs/proof/cost/)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation
