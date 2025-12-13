# Decision Service — Two‑Phase Model (Budget Gate → Provider Select)

This component makes bursting/DR **auditable and predictable** by separating the decision into two explicit steps:

1. **Budget Gate** — checks **cost & credits** against a policy and either *allows*, *warns*, or *denies* the action.
2. **Provider Selection** — chooses **azure**, **gcp**, or **onprem** using live metrics (latency, error rate, cost/hour, SLO).

It is deliberately **file‑based** so CLI and Jenkins runs are reproducible. Every run produces small JSON artifacts suitable for inclusion under `output/artifacts/decision/` and for cross‑reference in documentation and evidence packs.

---

## Repository layout

```
control/decision/
  policy.json                 # budgets, selection weights, action map
  scripts/
    gate_budget.py            # phase 1 — cost/credits gate (writes signals/gate.json)
    select_provider.py        # phase 2 — provider decision (writes signals/decision.json)
    run_action.sh             # orchestrates gate+select, then launches mapped provider script
  providers/
    azure/dr_cutover.sh
    gcp/dr_cutover.sh
    onprem/failback.sh
  signals/
    metrics.json              # produced by collectors (shape/example ok for repo)
    credits.env               # produced by collectors (shape/example ok for repo)
    gate.json                 # written by phase 1 (commit to evidence as needed)
    decision.json             # written by phase 2 (commit to evidence as needed)
```

> **Keep real `signals/*` out of Git** (use `.gitignore`). Check in only example shapes for reviewers.

---

## Quick start (local CLI)

```bash
cd control/decision

# 0) Populate example signals (or wire your own collectors)
./fetch_signals.sh || true

# 1) Gate: enforce budgets/credits before any action
python3 scripts/gate_budget.py --policy policy.json --signals signals --out signals/gate.json

# 2) Select: choose target (prints TARGET=...)
python3 scripts/select_provider.py --policy policy.json --signals signals --out signals/decision.json

# 3) Execute mapped action (runs gate+select if not present)
scripts/run_action.sh cutover --dry-run
scripts/run_action.sh cutover
```

- **Manual override:** set `TARGET=azure` (or `gcp`) to bypass selection. The gate still runs unless `policy.gate.mode="off"`.
- **Exit codes:** gate deny → `2`; selection failure → `3`; provider script missing → `4`.

---

## Jenkins integration (example)

```groovy
stage('Decide + Execute') { steps { dir('control/decision') {
  sh '''
    set -euo pipefail
    ./fetch_signals.sh || true
    scripts/run_action.sh cutover --dry-run
    scripts/run_action.sh cutover

    # publish decision artifacts into the proof archive
    RUN_ID="${BUILD_TAG// /_}"
    mkdir -p "../../output/artifacts/decision/${RUN_ID}"
    cp -a signals/gate.json signals/decision.json "../../output/artifacts/decision/${RUN_ID}/"
    ln -sfn "${RUN_ID}" "../../output/artifacts/decision/latest"
  '''
}}}
```

Artifacts then appear at `output/artifacts/decision/<run_id>/` and are linked from the Evidence Map.

---

## Policy model (summary)

`policy.json` contains:

- `gate`: `{ mode: "enforce"|"warn"|"off", min_credits, max_hourly_cost }`
- `selection`: `{ prefer: ["azure","gcp","onprem"], weights: { latency_ms:-1, error_rate:-5, cost_per_hour:-1, slo_score:2 }, fallback:"onprem" }`
- `actions`: map of action → provider → script (e.g., `"cutover" → "azure" → providers/azure/dr_cutover.sh`).

Start strict (mode=`"enforce"`) for demos that must not exceed budget; switch to `"warn"` for exploratory runs.

---

## Evidence links & cost alignment

This directory is designed to integrate with the platform's cost documentation and collectors:

- **Guide:** [Cost & telemetry overview](https://docs.hybridops.studio/cost/overview/) – how costs are tagged, queried, and summarised.
- **Evidence:** `output/artifacts/cost/` – normalised JSON and Markdown summaries derived from decision and billing signals.
- **Policy hooks:** `control/decision/` – this directory; the gate step consumes credits/budgets, and the selection step uses live metrics.

In other READMEs, this component should be referenced as `control/decision/` rather than duplicating implementation details.

## Security notes

- No secrets live here. Inject cloud auth at runtime (Vault/Key Vault/IAM) via Jenkins credentials or workload identity.
- Keep `signals/` out of Git (except sanitised examples). Gate/decision JSON intended as evidence should be copied into `output/artifacts/decision/` or `output/artifacts/cost/` as appropriate.
- Provider scripts should be **idempotent** and log to `out/` with timestamps for audit.

---

## Next steps

1) Wire collectors to write `signals/metrics.json` and `signals/credits.env`.  
2) Tune `policy.json` to reflect agreed budgets and SLOs.  
3) Point provider scripts to the real cutover/failback entry points.  
4) Add a copy‑to‑evidence step in CI so each run leaves an auditable trail under `output/artifacts/`.
