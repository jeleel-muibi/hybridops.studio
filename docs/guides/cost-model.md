# Cost & Telemetry — Evidence-Backed FinOps

This guide defines how HybridOps.Studio collects, attributes, and gates **cost** signals so that DR/burst actions remain auditable and budget-aware.

## Goals
- Attribute spend to **run, environment, component** using standard tags/labels.
- Produce **machine-readable evidence** per run (JSON/CSV/MD) under `docs/proof/cost/`.
- Enforce **budget guardrails** before burst/DR; surface results in dashboards.

## Standard Attribution
Use these keys consistently across Terraform, Packer, and pipelines:

- `cost:env` (dev|staging|prod)
- `cost:owner` (jeleel)
- `cost:component` (ctrl01|rke2|netbox|edge)
- `cost:run_id` (CI build number or UUID)
- `cost:purpose` (dr-test|burst|baseline)

### Terraform example
```hcl
locals {
  cost_tags = {
    "cost:env"       = var.env
    "cost:owner"     = "jeleel"
    "cost:component" = var.component
    "cost:run_id"    = var.run_id
    "cost:purpose"   = var.purpose
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.env}-rg"
  location = var.location
  tags     = local.cost_tags
}
