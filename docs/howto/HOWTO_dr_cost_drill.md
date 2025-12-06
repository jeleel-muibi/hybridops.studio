---
title: "Run a Cost-Aware DR Drill (Prometheus → GitHub Actions → DR Workflow)"
category: "dr"                # bootstrap | dr | burst | ops | platform | networking | tooling.
summary: "Execute a safe DR drill where Prometheus and Alertmanager trigger a GitHub Actions DR workflow, with all actions gated by the Cost Decision Service and captured as evidence."
difficulty: "Intermediate"

topic: "dr-cost-drill"

video: "https://www.youtube.com/watch?v=VIDEO_ID"   # Replace with final demo URL.
source: "https://github.com/hybridops-studio/hybridops-studio"

draft: false
is_template_doc: false
tags: ["dr", "cost", "github-actions", "prometheus", "alertmanager", "webhook"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""

---

# Run a Cost-Aware DR Drill (Prometheus → GitHub Actions → DR Workflow)

This HOWTO shows how to run a **cost-aware DR drill** for HybridOps.Studio:

- You simulate an on-prem platform failure signal in **Prometheus/Alertmanager**.  
- Alertmanager sends a webhook to **GitHub Actions**, which starts a DR workflow.  
- The workflow calls the **Cost Decision Service** to decide whether DR actions are allowed under budget.  
- All activity is tagged and stored as **evidence** for the DR and cost story in Evidence 4.

The drill is **non-destructive**: you test the control loop and decisioning without performing a full real cutover unless explicitly allowed.

It aligns with:

- [ADR-0701 – Use GitHub Actions as Stateless DR Orchestrator](../adr/ADR-0701-github-actions-stateless-dr-orchestrator.md)  
- [ADR-0801 – Treat Cost as a First-Class Signal for DR and Cloud Bursting](../adr/ADR-0801-cost-first-class-signal-dr-bursting.md)  
- [ADR-0402 – Use Prometheus Federation as Central DR Signal Plane](../adr/ADR-0402-prometheus-federation-dr-signal-plane.md)  
- [Cost & Telemetry – Evidence-Backed FinOps](../guides/cost-model.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  

---

## 1. Objectives

By the end of this HOWTO you will be able to:

- Trigger a **test DR alert** from Prometheus/Alertmanager.  
- Observe a **GitHub Actions DR workflow** starting from the webhook.  
- See the **Cost Decision Service** authorise or deny the action in drill mode.  
- Capture DR drill artefacts under [`docs/proof/dr/`](../../docs/proof/dr/) and [`docs/proof/cost/`](../../docs/proof/cost/).

---

## 2. Prerequisites

### 2.1 Platform and observability

You should have:

- Prometheus and Alertmanager configured and reachable.  
- A DR-related alert rule and route (for example, `jenkins_critical_down` or `platform_unavailable`) aligned with Evidence 4.  
- Alertmanager configured with:
  - Normal human notification channels (Slack/Teams/email).  
  - A **webhook receiver** pointing at a GitHub Actions endpoint (for example, a small webhook service or an API gateway that translates to `repository_dispatch`).

### 2.2 GitHub and DR workflow

- A GitHub repository that contains:

  - A DR workflow file (for example, `.github/workflows/dr-cutover.yml`) that can be triggered via:
    - `repository_dispatch` event with a `dr_drill` type, or
    - A custom webhook relay that ends up starting the workflow.

- The workflow should:

  - Parse the incoming alert payload.  
  - Call the Cost Decision Service (for example, via HTTP) with context like:
    - Environment (on-prem / cloud-dr).  
    - Estimated cost of the DR action.  
    - Budget guardrail information.  
  - Decide whether to:
    - **Simulate** DR (drill mode) or  
    - Perform a **real cutover** (only in controlled scenarios).

### 2.3 Cost Decision Service

- A Cost Decision Service endpoint (mock or real) that responds with:

  - A decision: `ALLOW`, `DENY`, or `SIMULATE_ONLY`.  
  - Rationale and cost estimates.

Its responses should be written to files under:

- [`docs/proof/cost/`](../../docs/proof/cost/)

### 2.4 Evidence folders

Create DR drill-specific folders:

```bash
mkdir -p docs/proof/dr/dr-drill-<date>/
mkdir -p docs/proof/cost/dr-drill-<date>/
```

Replace `<date>` with a timestamp (for example, `2025-12-02T203000Z`).

---

## 3. Phase 1 – Configure (or confirm) a DR drill alert

If you already have a DR alert (such as `jenkins_critical_down`) configured, you may use it in **drill mode**. Otherwise:

1. **Create a synthetic alert rule in Prometheus**

   Example (illustrative; adapt to your labels):

   ```yaml
   groups:
     - name: dr-drill.rules
       rules:
         - alert: DRDrill_Test_Alert
           expr: vector(1)
           labels:
             severity: critical
             drill: "true"
           annotations:
             summary: "DR drill test alert"
             description: "Synthetic alert to test Prometheus → Alertmanager → GitHub Actions DR control loop."
   ```

2. **Point Alertmanager route to the DR webhook**

   In Alertmanager config, ensure there is a route like:

   ```yaml
   route:
     receiver: "default"

     routes:
       - match:
           alertname: "DRDrill_Test_Alert"
         receiver: "dr-webhook"
         continue: false

   receivers:
     - name: "dr-webhook"
       webhook_configs:
         - url: "https://<your-dr-webhook-endpoint>/alert"
           send_resolved: true
   ```

3. **Reload Prometheus and Alertmanager**

   - Reload configuration so the new rule and route take effect.

---

## 4. Phase 2 – Trigger the DR drill alert

1. **Ensure drill metadata is present**

   - Confirm that the alert includes labels/annotations indicating it is a **drill** (for example, `drill="true"`).  
   - This allows GitHub Actions and the Cost Decision Service to treat it as a non-production drill by default.

2. **Trigger the alert**

   For a synthetic rule like `expr: vector(1)`:

   - It will fire almost immediately after being loaded.  
   - To make the change controlled, you can:
     - Create the rule in a separate file and include it only when you want to drill.  
     - Or toggle a `drill_enabled` variable used in the expression.

3. **Verify in Prometheus UI**

   - Check that `DRDrill_Test_Alert` is **firing**.

4. **Verify in Alertmanager UI**

   - Confirm that the alert is visible under Alerts and is being routed to the `dr-webhook` receiver.

Capture screenshots and store them under:

- `docs/proof/dr/dr-drill-<date>/prometheus-alert.png`  
- `docs/proof/dr/dr-drill-<date>/alertmanager-alert.png`  

---

## 5. Phase 3 – Observe GitHub Actions DR workflow

1. **Confirm webhook delivery**

   - Check logs for your webhook gateway or integration that receives Alertmanager’s request and forwards to GitHub (for example, via `repository_dispatch`).
   - Save any logs (with secrets redacted) to:

     - `docs/proof/dr/dr-drill-<date>/webhook-received.txt`

2. **Observe GitHub Actions run**

   - In the GitHub repository, open the **Actions** tab.
   - Confirm that a **DR drill workflow** run has started, with:
     - Event type = `repository_dispatch` or your chosen event.  
     - Payload referencing the DR drill alert and `drill="true"` metadata.

3. **Download workflow logs**

   - After the run completes, download logs and store them under:

     - `docs/proof/dr/dr-drill-<date>/actions-logs.zip`

   - Alternatively, copy the relevant steps to a text file if you prefer plain text.

---

## 6. Phase 4 – Cost Decision Service integration

1. **Inspect Cost Decision Service call**

   - In the workflow logs, locate the step that calls the Cost Decision Service.
   - Confirm the request includes context such as:
     - `environment: "onprem"`  
     - `mode: "dr-drill"`  
     - Estimated cost impact.

2. **Capture the decision output**

   - Record the Cost Decision Service response (redact secrets) to:

     - `docs/proof/cost/dr-drill-<date>/cost-decision.json`

   - The response should include:
     - Decision: `SIMULATE_ONLY` or `ALLOW` (for drills, typically `SIMULATE_ONLY`).  
     - Budget impact and rationale.

3. **Ensure drill mode behaviour**

   - Confirm the workflow behaves as expected for drills:
     - No destructive infrastructure changes.  
     - At most, **simulated** or **no-op** steps with clear logging.

---

## 7. Phase 5 – Optional: simulate a full DR path (in lab)

If you have a dedicated **lab environment** (not production, not your main homelab), you may also:

1. Configure the Cost Decision Service to return `ALLOW` for a specific drill.

2. Let the workflow:

   - Spin up or scale out DR resources in the cloud.
   - Run validation checks on those resources.
   - Tear them down after the drill.

3. Treat this as a **full DR exercise** with evidence separate from real production.

In this case, ensure you clearly label artefacts as **lab-only** and track cost carefully.

---

## 8. Phase 6 – Evidence consolidation and review

1. **DR artefacts**

   Make sure `docs/proof/dr/dr-drill-<date>/` contains:

   - Screenshots from Prometheus and Alertmanager.  
   - Webhook/gateway logs.  
   - GitHub Actions workflow logs.  
   - Any additional notes on timing and behaviour.

2. **Cost artefacts**

   Ensure `docs/proof/cost/dr-drill-<date>/` contains:

   - Cost Decision Service responses.  
   - Any supplementary cost calculations or notes.

3. **Cross-reference in Evidence 4**

   - Optionally update Evidence 4 to:
     - Mention this specific DR drill as a proof point.  
     - Link to the dr-drill proof folders.

4. **Review and refine**

   - After the drill, hold a short review:
     - Did alerts trigger as expected?  
     - Was the Cost Decision Service called correctly?  
     - Were guardrails applied as designed?  
   - File follow-up issues for improvement.

---

## 9. Validation checklist

- [ ] A DR drill alert fired in Prometheus and was visible in Alertmanager.  
- [ ] Alertmanager routed the drill alert to the DR webhook receiver.  
- [ ] A GitHub Actions DR workflow run was started from the alert.  
- [ ] The workflow called the Cost Decision Service with drill-specific context.  
- [ ] The Cost Decision Service returned a decision (`SIMULATE_ONLY` / `ALLOW` / `DENY`) with rationale.  
- [ ] No unintended destructive actions occurred in the drill.  
- [ ] Evidence was stored under [`docs/proof/dr/`](../../docs/proof/dr/) and [`docs/proof/cost/`](../../docs/proof/cost/).  
- [ ] Follow-up actions were recorded for any improvements.  

---

## References

- [ADR-0701 – Use GitHub Actions as Stateless DR Orchestrator](../adr/ADR-0701-github-actions-stateless-dr-orchestrator.md)  
- [ADR-0801 – Treat Cost as a First-Class Signal for DR and Cloud Bursting](../adr/ADR-0801-cost-first-class-signal-dr-bursting.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  
- [`docs/proof/dr/`](../../docs/proof/dr/)  
- [`docs/proof/cost/`](../../docs/proof/cost/)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation
