---
id: ADR-0801
title: "Treat Cost as a First-Class Signal for DR and Cloud Bursting"
status: Accepted
date: 2025-12-01
category: "08-cost-optimisation"

domains: ["platform", "cost", "dr", "sre"]
owners: ["HybridOps.Studio"]
supersedes: []
superseded_by: []

links:
  prs: []
  runbooks: []
  howtos: []
  evidence:
    - "../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md"
    - "../guides/cost-model.md"
  diagrams: []

draft: false
is_template_doc: false
tags: ["cost", "finops", "dr", "bursting"]
access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""

---

# Treat Cost as a First-Class Signal for DR and Cloud Bursting

## Status
Accepted — DR and burst workflows are gated by an explicit Cost Decision Service that evaluates standardised cost artefacts before allowing disruptive or expensive actions.

## 1. Context

HybridOps.Studio demonstrates a hybrid platform where:

- On-prem is the **default** location for workloads.
- Cloud capacity is used for **disaster recovery (DR)** and **bursting**.
- The platform is meant to be relevant for **startups and cost-sensitive teams** that cannot afford uncontrolled cloud spend.

To make this credible and verifiable, cost must be:

- **Visible** — with artefacts that can be inspected and reasoned about.
- **Standardised** — following a consistent schema and tagging model.
- **Actionable** — wired into automation so that cost is part of decision logic, not a separate report.

Key questions:

- How do pipelines and DR workflows know whether a planned DR/burst action is acceptable from a cost perspective?
- How do we avoid hard-coding ad-hoc numbers into each pipeline?
- How do we make cost evidence re-usable for docs, dashboards and portfolio material?

This ADR defines how cost becomes a **first-class signal** in DR and burst workflows.

## 2. Decision

HybridOps.Studio adopts a **Cost Decision Service** and standard cost artefacts as the way to bring cost into DR and bursting.

Core elements:

- Pipelines and DR workflows emit **cost artefacts** under `docs/proof/cost/`, for example:
  - `docs/proof/cost/<env>/<component>-<timestamp>.json`
  - containing projected monthly cost, bounds and assumptions.
- A **Cost Decision Service** (implemented as a small script or service, for example Python) reads:
  - Projected cost for the proposed action.
  - Current and planned budgets or thresholds.
  - Environment and component tags.
- DR and burst workflows (for example, GitHub Actions DR orchestrator) call the Cost Decision Service before scaling or failing over:
  - If the action is **within budget**, the workflow may proceed.
  - If the action would **breach guardrails**, the workflow:
    - Either stops and records a blocked decision.
    - Or requires an explicit override (for example, a manual approval step).
- Cost artefacts and decisions are stored under:
  - `docs/proof/cost/` for raw data.
  - `docs/proof/dr/` for DR and burst events that reference the cost decision.

Cost is therefore treated as an input signal to automation, not as an after-the-fact report.

## 3. Rationale

The rationale for making cost a first-class signal is:

- **Alignment with hybrid goals**
  - The platform exists partly to show that on-prem can be used intelligently to control cloud spend.
  - DR and burst operations are exactly where costs can spike; they must be tightly governed.

- **Clarity for assessors and stakeholders**
  - Assessors can see:
    - How much a DR or burst action is projected to cost.
    - Whether that action was allowed or blocked, and why.
  - This provides a more mature story than “we can burst to cloud”, without any guardrails.

- **Reusability across pipelines**
  - A single Cost Decision Service and common artefact schema avoid duplicating cost logic in each pipeline.
  - Dashboards, documentation and portfolio evidence can all read the same artefacts.

- **Support for future FinOps integration**
  - The same mechanism could later integrate with cloud billing exports or external cost tools.
  - The ADR does not mandate a specific vendor; it mandates the pattern.

Trade-offs:

- Cost estimation is inherently approximate.
- The Cost Decision Service introduces another component to maintain.

## 4. Consequences

### 4.1 Positive consequences

- **Cost-aware automation**
  - DR and burst workflows cannot accidentally scale beyond agreed thresholds without leaving evidence.
  - Overrides are explicit and discoverable.

- **Better conversations about trade-offs**
  - Stakeholders can see the projected cost of resilience levels and DR patterns.
  - The platform can demonstrate “what if” scenarios for different DR strategies.

- **Evidence for portfolio and teaching**
  - Evidence 4 can show real cost artefacts and decision logs, not just claims.
  - Academy content can teach DR patterns that are realistic about money.

### 4.2 Negative consequences and risks

- **Risk of false precision**
  - Cost estimates might be misinterpreted as exact rather than approximate.
  - Poorly calibrated inputs could lead to overly conservative or overly aggressive decisions.

- **Additional work to maintain the model**
  - The cost model and thresholds must be updated as pricing or architecture evolves.
  - Stale values could either block necessary DR or allow too much spend.

Mitigations:

- Document assumptions in the cost model guide.
- Treat cost thresholds as **guardrails**, not hard guarantees.
- Run regular DR drills that include reviewing cost artefacts and thresholds.

## 5. Alternatives considered

Hard-coded cost checks inside each pipeline:

- Would tightly couple cost logic to a specific pipeline.
- Makes it difficult to update thresholds or models globally.
- Scales poorly as the number of pipelines grows.

No automated cost checks (manual review only):

- Simple, but not realistic for automated DR or burst workflows.
- Increases risk of surprise bills, especially in emergency situations.

External FinOps tooling only:

- Useful, but not sufficient for automation.
- This ADR does not preclude external tools; it ensures automation can consume cost signals directly.

## 6. Implementation notes

Cost artefacts:

- At minimum, artefacts should include:
  - `env` (for example, `onprem`, `dr-test`, `dr-prod`).
  - `component` (for example, `rke2-dr-cluster`, `jenkins-dr`, `netbox-dr`).
  - `projected_monthly_cost` (numeric).
  - `currency` (for example, `GBP`).
  - `threshold` and/or `budget_window`.
  - `timestamp` and `version` of the cost model.

Cost Decision Service:

- Can be implemented as:
  - A Python script invoked by GitHub Actions.
  - A small API service reachable from CI.
- Responsibilities:
  - Read the relevant artefact(s).
  - Compare projected costs against thresholds.
  - Emit a clear allow/deny result and a reason.
- Output:
  - Structured result (for example, JSON) used by the workflow.
  - Log entries written to `docs/proof/cost/` and, for DR events, to `docs/proof/dr/`.

Workflow integration:

- DR workflows (see ADR-0701) call the Cost Decision Service early in the job sequence.
- Workflows must:
  - Fail fast on unauthorised actions.
  - Record the reason for any blocked DR/burst attempt.

Evidence:

- Cost-related evidence is stored primarily under:
  - [`docs/proof/cost/`](../../docs/proof/cost/)
- DR-related evidence referencing cost decisions is stored under:
  - [`docs/proof/dr/`](../../docs/proof/dr/)

## 7. Operational impact and validation

Operational impact:

- Platform and SRE teams must:
  - Maintain the cost model and thresholds.
  - Ensure artefact generation is part of relevant pipelines.
  - Monitor DR and burst runs for cost-related decisions.

Validation:

- HOWTOs to be created:
  - Instrument cost artefacts in Terraform and CI pipelines.
  - Run a cost-aware DR drill and interpret the results.
- Runbooks to be created:
  - Cost guardrail breach (DR/burst blocked) and override process.
- Evidence folders:
  - [`docs/proof/cost/`](../../docs/proof/cost/)
  - [`docs/proof/dr/`](../../docs/proof/dr/)

Validation is considered successful when:

- DR/burst workflows consistently call the Cost Decision Service.
- Cost artefacts exist and are updated for relevant components.
- At least one DR drill shows a blocked action due to cost, with clear evidence and reasoning.

## 8. References

- [ADR-0001 – ADR Process and Conventions](../adr/ADR-0001-adr-process-and-conventions.md)  
- [ADR-0701 – Use GitHub Actions as Stateless DR Orchestrator](../adr/ADR-0701-github-actions-stateless-dr-orchestrator.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  
- [HybridOps.Studio Cost Model Guide](../guides/cost-model.md)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
