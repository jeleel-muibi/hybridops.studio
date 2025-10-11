---
title: "<Short, action-oriented title>"
category: "bootstrap"   # one of: bootstrap | dr | burst | ops
summary: "1–2 sentences focused on the outcome this runbook delivers."
severity: "P2"          # P1=critical, P2=high, P3=normal
draft: false            # set true while authoring to hide from index
template: true          # keeps this file out of the generated lists
# last_updated: "auto"  # omit this key; generator will use file mtime
# tags: ["optional", "labels"]
---

# <Short, action-oriented title>

**Purpose**: <one sentence>
**Owner**: <team/role> · **Trigger**: <alert/signal> · **ETA**: <~minutes>
**Pre-reqs**: <accounts, kubecontext, NetBox token, VPN paths, approvals>
**Rollback**: <where to find failback steps or notes>

---

## Steps

1) **<Step title>**
   - Command:
     ```bash
     <command(s)>
     ```
   - Expected: <what success looks like>
   - Evidence: save to `output/artifacts/<area>/<YYYYMMDDThhmmssZ>_<name>.txt`

2) **<Step title>**
   - Command:
     ```bash
     <command(s)>
     ```
   - Expected: …
   - Evidence: …

---

## Verification
- KPIs satisfied: <e.g., RTO ≤ 15m, RPO ≤ 5m, SLI/alert resets>
- Dashboards to check: <Grafana panel names/URLs>
- Evidence export: screenshots/logs to `docs/proof/<topic>/images`

## Links
- Playbook/Module: `<path in deployment/core/...>`
- Related runbooks: see the [category index](./by-category/).
- Evidence Map: `../evidence_map.md`
