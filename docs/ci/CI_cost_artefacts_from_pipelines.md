---
title: "CI – Emit Cost Artefacts from Pipelines"
id: "CI-0801-cost-artefacts"   # Optional stable ID, aligned with ADR-0801.
owner: "HybridOps.Studio"
summary: "Standard pattern for emitting machine-readable cost artefacts from CI/CD pipelines to support cost-aware DR and optimisation."

scope: "platform"              # e.g. platform | images | docs | netbox | terraform | ansible | kubernetes.

draft: false
is_template_doc: false
tags: ["finops", "cost", "github-actions", "terraform"]

access: public                  # public | academy | internal

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""

---

# CI – Emit Cost Artefacts from Pipelines

## 1. Purpose

This document describes the **standard CI pattern** for emitting machine-readable **cost artefacts** from pipelines in HybridOps.Studio.

It supports:

- [ADR-0801 – Treat Cost as a First-Class Signal for DR and Cloud Bursting](../adr/ADR-0801-cost-first-class-signal-dr-bursting.md)  
- [HOWTO – Run a Cost-Aware DR Drill (Prometheus → GitHub Actions → DR Workflow)](../howtos/HOWTO_dr_cost_drill.md)  
- [Cost & Telemetry – Evidence-Backed FinOps](../guides/cost-model.md)  

The goal is that every significant pipeline run which may drive DR/burst decisions:

- Emits a **cost artefact file** (JSON or CSV).  
- Tags resources and actions with standard `cost:*` labels.  
- Leaves an audit trail in `docs/proof/cost/`.

This is intentionally short by design; details of the underlying cost model live in `cost-model.md`.

---

## 2. Standard tags

Pipelines that emit cost artefacts must populate the following keys in their environment or metadata:

- `cost:env` – environment (for example, `dev`, `staging`, `prod`, `dr-test`).  
- `cost:owner` – owning team or persona (for example, `hybridops`, `academy`).  
- `cost:component` – logical component (for example, `rke2`, `netbox`, `jenkins`, `dr-runner`).  
- `cost:run_id` – unique identifier for the pipeline run (for example, CI build number or timestamp).  
- `cost:purpose` – reason for the run (for example, `deploy`, `dr-test`, `burst`, `experiment`).  

These tags are:

- Passed into Terraform / tooling as variables where relevant.  
- Written into the cost artefact file so that later analysis can group and filter spend.

---

## 3. Cost artefact format

Pipelines emit a **per-run artefact** into:

```text
docs/proof/cost/<component>/cost-run-<run_id>.json
```

Recommended JSON structure:

```json
{
  "run_id": "<RUN_ID>",
  "timestamp": "<ISO8601>",
  "env": "<ENV>",
  "owner": "<OWNER>",
  "component": "<COMPONENT>",
  "purpose": "<PURPOSE>",
  "estimated_monthly_cost_usd": 12.34,
  "currency": "USD",
  "details": {
    "compute": 8.50,
    "storage": 3.20,
    "network": 0.64
  },
  "source": "terraform-plan",
  "notes": "Short free-text note if needed"
}
```

Key points:

- `estimated_monthly_cost_usd` is an **estimate** derived from Terraform plan data, cloud pricing APIs, or static tables.  
- `details` is optional but recommended for breaking down major cost categories.  
- `source` indicates how the estimate was generated.

CSV is also acceptable for ad-hoc cases, but JSON is preferred as the primary format.

---

## 4. GitHub Actions pattern (example)

A GitHub Actions workflow that runs a Terraform plan for RKE2/DR might include a final step:

```yaml
- name: Emit cost artefact
  run: |
    mkdir -p docs/proof/cost/rke2
    cat > "docs/proof/cost/rke2/cost-run-${{ env.COST_RUN_ID }}.json" <<EOF
    {
      "run_id": "${{ env.COST_RUN_ID }}",
      "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
      "env": "${{ env.COST_ENV }}",
      "owner": "${{ env.COST_OWNER }}",
      "component": "rke2",
      "purpose": "${{ env.COST_PURPOSE }}",
      "estimated_monthly_cost_usd": ${{ env.COST_ESTIMATE_USD }},
      "currency": "USD",
      "details": {
        "compute": ${{ env.COST_ESTIMATE_COMPUTE_USD }},
        "storage": ${{ env.COST_ESTIMATE_STORAGE_USD }},
        "network": ${{ env.COST_ESTIMATE_NETWORK_USD }}
      },
      "source": "terraform-plan",
      "notes": "Auto-generated cost artefact for DR-related plan."
    }
    EOF
  shell: bash
```

Environment variables such as `COST_ESTIMATE_*` can be populated by:

- A preceding step that parses `terraform plan` JSON output, or  
- A small helper script that computes estimates from known instance sizes.

The Cost Decision Service can later:

- Read these artefacts directly, or  
- Use the same JSON schema for real-time decisions.

---

## 5. Terraform integration (outline)

This document does not prescribe a single implementation, but common options include:

- Use `terraform show -json` on the plan, pipe into a helper script that:
  - Sums projected resource costs using static or API-based price tables.  
  - Writes the JSON artefact into `docs/proof/cost/<component>/`.  

- Tag Terraform resources with the same `cost:*` labels, so that:
  - Cloud-native cost tools can group by those tags.  
  - The CI artefact and cloud billing views use the same vocabulary.

The important part is **consistency of tags and output location**, not the exact calculation method.

---

## 6. Validation and evidence

Pipelines that claim to be **cost-aware** should demonstrate:

- Presence of at least one JSON artefact in `docs/proof/cost/<component>/`.  
- Matching `cost:*` tags in both:
  - The artefact, and  
  - Terraform or cloud resource tags.  

For Evidence 4 and ADR-0801, you can point assessors to:

- One or two representative artefacts for key components (for example, DR cluster, RKE2 burst nodes).  
- Screenshots or CLI output showing the artefact content alongside the corresponding GitHub Actions run.

---

## 7. References

- [ADR-0801 – Treat Cost as a First-Class Signal for DR and Cloud Bursting](../adr/ADR-0801-cost-first-class-signal-dr-bursting.md)  
- [HOWTO – Run a Cost-Aware DR Drill (Prometheus → GitHub Actions → DR Workflow)](../howtos/HOWTO_dr_cost_drill.md)  
- [Cost & Telemetry – Evidence-Backed FinOps](../guides/cost-model.md)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation
