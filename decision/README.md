# Decision Service — Policy-Driven DR/Burst

This component decides *where* to run (on-prem, Azure, GCP) by evaluating metrics, RTO/RPO, and available credits, then triggers the right provider script. It is fully CLI/Git-driven (no click-ops) and writes a durable decision record as evidence.

Flow
1. `fetch_signals.sh` → gathers/normalizes inputs into `signals/metrics.json` and `signals/credits.env`.
2. `choose_target.py` → loads `policy.json` + signals, computes scores, produces `decision.json`.
3. `run_action.sh` → dispatches to `providers/*` based on the chosen target.

Outputs live under `out/decision/<timestamp>/` with a `latest` symlink.

Secrets
- Use a real secrets backend for provider credentials (e.g., Azure Managed Identity or Vault AppRole).
- The scripts read only short-lived tokens from env. Nothing is hardcoded.

Make targets
- `make decision.fetch`  → collect signals
- `make decision.decide` → produce decision artifact
- `make decision.execute`→ run provider hook
- `make decision.all`    → fetch + decide + execute
