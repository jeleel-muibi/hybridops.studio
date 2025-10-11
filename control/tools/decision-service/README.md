# Decision Service — Credit‑ & SLO‑aware Cloud Selector

Selects a target cloud (**azure** or **gcp**) for DR or burst based on
available **credits** and **service objectives** (RPO/RTO/latency).
Designed as an early step in the DR/burst pipeline; the selected provider
is exported as `CLOUD_PROVIDER` for subsequent steps.

## Purpose
- Prefer the provider with sufficient credits while honoring maximum RPO/RTO.
- Fall back to the lowest‑latency provider on ties (strategy can be changed).
- Emit a small, auditable artifact set under `output/decision/`.

## Inputs
- **Credits** — remaining budget/credits (per provider). Provided via CI secrets
  or a small env file. Example env keys: `AZURE_CREDITS_REMAINING`, `GCP_CREDITS_REMAINING`.
- **SLO metrics** — JSON object keyed by provider with `rpo`, `rto`, `latency_ms`.
  (Populated by monitoring adapters such as Prometheus Federation, Azure Monitor, or GCP Cloud Monitoring.)

## Outputs
- **stdout**: one word — `azure` or `gcp`.
- **Artifacts**: `output/decision/metrics.json` and optional `output/decision/credits.env`.
- **Environment (CI)**: `CLOUD_PROVIDER` exported for downstream stages.

## Pipeline usage (illustrative)
```bash
# 1) Collect signals (credits + SLO metrics → output/decision/*)
bash control/tools/decision/fetch_signals.sh

# 2) Decide target (prints provider to stdout)
provider="$(control/tools/decision/choose_target.py --metrics output/decision/metrics.json)"
export CLOUD_PROVIDER="$provider"

# 3) Execute DR/burst with the chosen provider
CLOUD_PROVIDER="$CLOUD_PROVIDER" make dr.db.promote dr.cluster.attach dr.gitops.sync dr.dns.cutover
```

## CLI
`control/tools/decision/choose_target.py` (POSIX, Python 3):
- Flags: `--metrics <file>`, `--credits "azure=NN,gcp=NN"`, `--max-rpo <s>`, `--max-rto <s>`, `--strategy balanced|cost|latency`, `--verbose`.
- Env fallbacks: `DECISION_CREDITS="azure=NN,gcp=NN"`, `DECISION_STRATEGY`.
- Exit code: `0` (success). Output is always a single token: `azure` or `gcp`.

## Library
The decision logic is implemented in a reusable library:
`core/python/libhybridops/decision/__init__.py` → `choose_target(...)`.
- Enables re‑use from Ansible or other Python callers without shelling out.
- Keeps the CLI thin and the policy easy to unit‑test.

## Files
- `choose_target.py` — CLI wrapper that imports the library and prints the provider.
- `fetch_signals.sh` — stub that prepares `metrics.json` and sets `DECISION_CREDITS`.
- `examples/` — tiny sample `credits.env` and `metrics.json` to demonstrate the flow.
- Library: `core/python/libhybridops/decision/__init__.py`.

## Security & audit
- Credits are sourced from CI secrets or a controlled env file; secrets are **not** written to logs.
- Decision inputs and the final choice are stored under `output/decision/` for reproducibility and
  inclusion in Evidence/Proof artifacts.

## Strategy notes
- **balanced** (default): prefer higher credits; latency as tie‑breaker.
- **cost**: strictly credits first; latency tie‑breaker.
- **latency**: strictly latency first; credits tie‑breaker.
