---
title: "Cost Guardrail Breach During DR/Burst (Decision: DENY)"
category: "dr"               # bootstrap | dr | burst | ops | platform | networking | tooling.
summary: "Handle situations where the Cost Decision Service denies a DR or burst action, decide on overrides or degraded operation, and capture evidence for financial and technical governance."
severity: "P2"               # P1 = critical, P2 = high, P3 = normal.

topic: "cost-guardrail"

draft: false
is_template_doc: false
tags: ["cost", "dr", "burst", "github-actions", "finops"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""

---

# Cost Guardrail Breach During DR/Burst (Decision: DENY)

**Purpose:** Provide a clear procedure for responding when the **Cost Decision Service** returns a **DENY** (or equivalent) decision for a DR or cloud burst action, including how to interpret the decision, choose between override vs degraded mode, and capture evidence.

**Owner:** Platform / SRE team (HybridOps.Studio)  
**Trigger:** A DR or burst-related workflow (typically GitHub Actions) calls the Cost Decision Service and receives a **DENY** decision.  
**Impact:** The requested DR/burst action is blocked on cost grounds. Service availability or performance may remain degraded until an alternative path is chosen.  
**Severity:** P2 – high impact, but by design it is a governed decision, not uncontrolled failure.

This runbook aligns with:

- [ADR-0701 – Use GitHub Actions as Stateless DR Orchestrator](../adr/ADR-0701-github-actions-stateless-dr-orchestrator.md)  
- [ADR-0801 – Treat Cost as a First-Class Signal for DR and Cloud Bursting](../adr/ADR-0801-cost-first-class-signal-dr-bursting.md)  
- [HOWTO – Run a Cost-Aware DR Drill (Prometheus → GitHub Actions → DR Workflow)](../howtos/HOWTO_dr_cost_drill.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  

Evidence for this runbook should be stored under:

- [`docs/proof/cost/`](../../docs/proof/cost/)  
- [`docs/proof/dr/`](../../docs/proof/dr/)  

---

## 1. Scenario overview

The platform uses a **Cost Decision Service** as part of the DR/burst control loop:

1. A technical signal (for example, `jenkins_critical_down`, `platform_unavailable`) is detected by Prometheus/Alertmanager.  
2. Alertmanager triggers a **GitHub Actions DR or burst workflow**.  
3. The workflow calls the Cost Decision Service with context:
   - Environment and target (on-prem, cloud-dr, extra burst capacity).  
   - Estimated cost for the action (for example, per hour/day).  
   - Budget guardrail configuration for the current period.  
4. The Cost Decision Service returns **ALLOW**, **DENY**, or **SIMULATE_ONLY**.

This runbook covers the path where the decision is:

- `DENY` – the requested DR/burst action is not allowed within current cost guardrails.  

The objective is to:

- Understand why it was denied.  
- Decide whether to:
  - Respect the denial and operate in a **degraded but safe** mode, or  
  - Seek **explicit override approval** and re-run with override.  
- Capture all decisions as evidence for governance and FinOps.

---

## 2. Preconditions and safety checks

Before taking action:

1. **Confirm this is a Cost Decision Service DENY, not a technical failure**

   - Check the GitHub Actions workflow logs for the Cost Decision Service step.
   - Confirm the service responded successfully with a `decision: "DENY"` (or equivalent), not an HTTP/network error.

2. **Confirm the nature of the underlying technical incident**

   - Is this a **DR event** (for example, on-prem cluster impaired) or a **burst request** (for example, scale out for load)?
   - Check relevant platform runbooks:
     - DR cutover and failback runbooks.  
     - Jenkins controller outage runbook.  
     - db-01 failover runbook (if a database issue is involved).

3. **Locate and create evidence folders**

   - Establish an event-specific folder:

     ```bash
     mkdir -p docs/proof/cost/cost-guardrail-<date>/
     mkdir -p docs/proof/dr/cost-guardrail-<date>/
     ```

   - Replace `<date>` with a timestamp (for example, `2025-12-02T210000Z`).

4. **Check if this is a drill or a real incident**

   - Inspect the workflow inputs and Cost Decision Service payload:
     - `mode: "dr-drill"` or `"production"` (or similar).  
   - This affects:
     - Communication style.  
     - Whether override is even considered.

5. **Confirm current business priority**

   - For a portfolio/demo environment:
     - Availability vs cost tolerance may be different than for a paid environment.
   - For a hypothetical real environment:
     - Clarify whether contractual SLOs or critical obligations would justify override.

Record these initial observations in the incident ticket and in a text file under `docs/proof/cost/cost-guardrail-<date>/context.txt`.

---

## 3. Phase 1 – Inspect the Cost Decision Service response

> Goal: Understand why the decision is DENY.

1. **Extract the Cost Decision Service payload**

   - From the GitHub Actions logs, copy the JSON response into a file:

     ```bash
     # Example: captured from workflow logs or artifact
     cat > docs/proof/cost/cost-guardrail-<date>/cost-decision.json <<'EOF'
     {...}
     EOF
     ```

2. **Identify key fields**

   Look for at least:

   - `decision` – must be `DENY` for this runbook.  
   - `reason` or `rationale` – textual reason (for example, "monthly budget exceeded").  
   - `estimated_cost` – projected cost of the requested action.  
   - `budget_remaining` – remaining budget for the relevant period.  
   - `policy_id` – which policy triggered the denial.

3. **Summarise the decision**

   - In a short file (`summary.txt`) under the same folder, summarise:

     - Why the decision is DENY.  
     - Which policy and thresholds were involved.  
     - Whether this is a per-environment policy (for example, `env: lab` vs `env: production`).

This summary becomes part of the governance evidence.

---

## 4. Phase 2 – Decide between degraded mode and override

> Goal: Make a deliberate, documented decision on whether to respect the DENY or seek override.

1. **Assess technical impact**

   - For DR:
     - How impaired is the on-prem environment?  
     - Are there alternate paths (for example, partial service, read-only mode, minimal capacity)?  
   - For burst:
     - Is the current capacity saturated?  
     - Will not bursting cause a clear user impact?

2. **Assess financial and governance impact**

   - Compare:
     - Estimated DR/burst cost vs budget remaining.  
     - Nature of current environment (portfolio, lab, production).  
   - Consider whether approving override:
     - Is justified by critical user or business impact.  
     - Would create unacceptable financial risk.

3. **Default stance**

   - For **drills** and lab/portfolio environments:
     - Default is to **respect DENY** and treat it as a successful demonstration of guardrails.
   - For hypothetical production:
     - Default is to respect DENY unless:
       - A clear, documented business owner explicitly approves override.

4. **Decision options**

   - Option A – **Respect DENY and operate in degraded mode**  
   - Option B – **Request and document override, then re-run**  
   - Option C – **Postpone DR/burst and schedule a later window** (for example, after budget reset or policy change).

Document the chosen option and rationale in:

- Incident ticket, and  
- `docs/proof/cost/cost-guardrail-<date>/decision.txt`

---

## 5. Phase 3 – Path A: Respect DENY and operate in degraded mode

If you choose to respect the Cost Decision Service decision:

1. **Select a degraded operating mode**

   Examples:

   - Keep a **minimal on-prem footprint** running (essential services only).  
   - Serve some workloads in **read-only** mode (for example, NetBox read-only).  
   - Temporarily accept higher latency or lower throughput.

2. **Apply technical safeguards**

   - Ensure automation is not continuously retrying DR/burst attempts:
     - Disable or pause the triggering workflow temporarily.  
     - Put DR/burst jobs in a safe status (for example, disabled in Jenkins or GitHub Actions).

3. **Communicate status**

   - If this is a multi-user environment, clearly communicate:
     - That DR/burst was **intentionally** blocked on cost grounds.  
     - What degraded behaviour users should expect.

4. **Record operational state**

   - Briefly describe the degraded mode in:

     - `docs/proof/dr/cost-guardrail-<date>/degraded-mode.txt`

5. **Plan follow-up**

   - Decide whether you will:
     - Adjust budgets or policies for the future.  
     - Improve capacity planning to reduce need for emergency burst.  

---

## 6. Phase 4 – Path B: Request override and re-run

If you choose to request override (primarily a conceptual path in this portfolio):

1. **Document override request**

   - Capture:
     - Who is requesting override.  
     - Who would approve it (for example, product or business owner).  
     - Why override is justified vs cost risk.

   - Save this as:

     - `docs/proof/cost/cost-guardrail-<date>/override-request.txt`

2. **Record hypothetical approval**

   - For a real environment:
     - Capture actual approval (for example, written confirmation).  
   - For a portfolio demo:
     - Explain that override is being simulated for demonstration and that no real funds are at risk.

3. **Re-run workflow with override flag**

   - Re-trigger the DR/burst workflow with a flag (for example, `override: true` or a dedicated event type).
   - Ensure the Cost Decision Service:
     - Records that this is an override.  
     - Returns `ALLOW` with an `override` field set.

4. **Monitor DR/burst actions**

   - If this is a **non-destructive lab scenario**, allow the workflow to:
     - Provision DR or burst resources.  
     - Validate workloads.  
     - Tear down resources after validation.

5. **Capture override evidence**

   - Save updated Cost Decision Service responses to:
     - `docs/proof/cost/cost-guardrail-<date>/cost-decision-override.json`
   - Capture any additional DR/burst artefacts under:
     - `docs/proof/dr/cost-guardrail-<date>/`

---

## 7. Phase 5 – Path C: Postpone and reschedule

If you decide to neither override nor stay in prolonged degraded mode:

1. **Postpone action**

   - Treat this as a decision to defer DR/burst until:
     - Budget is refreshed, or  
     - Policies are re-tuned.

2. **Document the deferral**

   - In `decision.txt` and the incident ticket, state:
     - That action was deferred due to cost.  
     - Any temporary mitigations applied.

3. **Update cost or DR plans**

   - Consider changes to:
     - Budgeting for DR/burst.  
     - Environment sizing to avoid repeated near-misses.

---

## 8. Phase 6 – Evidence and close-out

Before closing the runbook:

1. Ensure the following folders contain artefacts for this event:

   - `docs/proof/cost/cost-guardrail-<date>/`  
   - `docs/proof/dr/cost-guardrail-<date>/`  

2. Check that you have:

   - Original Cost Decision Service response (`DENY`).  
   - Summary of the decision and rationale.  
   - Chosen path (A/B/C) and justification.  
   - Any override notes (if applicable).  
   - Description of degraded mode or follow-up actions.

3. Update Evidence 4 (if this was a deliberate drill) to:

   - Mention the event as a proof point that cost guardrails are not just theoretical.  

4. Close the incident or drill with:

   - Clear final state.  
   - Lessons learned and any backlog items.

---

## 9. Validation checklist

- [ ] Confirmed that the Cost Decision Service returned a genuine `DENY` (not a technical error).  
- [ ] Underlying technical incident (DR or burst need) was understood and recorded.  
- [ ] Cost decision payload and rationale stored under [`docs/proof/cost/`](../../docs/proof/cost/).  
- [ ] A deliberate choice was made between degraded mode, override, or postponement.  
- [ ] If degraded mode was chosen, technical safeguards and communication steps were applied.  
- [ ] If override was chosen, approvals and re-run behaviour were recorded.  
- [ ] DR/burst workflows were left in a safe state, with no uncontrolled retries.  
- [ ] Evidence was captured and, if appropriate, referenced from Evidence 4.  

---

## References

- [ADR-0701 – Use GitHub Actions as Stateless DR Orchestrator](../adr/ADR-0701-github-actions-stateless-dr-orchestrator.md)  
- [ADR-0801 – Treat Cost as a First-Class Signal for DR and Cloud Bursting](../adr/ADR-0801-cost-first-class-signal-dr-bursting.md)  
- [HOWTO – Run a Cost-Aware DR Drill (Prometheus → GitHub Actions → DR Workflow)](../howtos/HOWTO_dr_cost_drill.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  
- [`docs/proof/cost/`](../../docs/proof/cost/)  
- [`docs/proof/dr/`](../../docs/proof/dr/)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation
