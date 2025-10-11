#!/usr/bin/env bash
# Collect credits + metrics and emit:
#   - output/decision/metrics.json
#   - export DECISION_CREDITS="azure=NN,gcp=NN" (in this shell)
set -euo pipefail

OUT_DIR="${OUT_DIR:-output/decision}"
mkdir -p "$OUT_DIR"

# --- Credits -------------------------------------------------------
AZ_CREDITS="${AZURE_CREDITS_REMAINING:-}"
GCP_CREDITS="${GCP_CREDITS_REMAINING:-}"

# Optional local fallback (developer machine)
if [[ -z "${AZ_CREDITS}" || -z "${GCP_CREDITS}" ]]; then
  if [[ -f "${OUT_DIR}/credits.env" ]]; then
    # shellcheck disable=SC1090
    source "${OUT_DIR}/credits.env"
    AZ_CREDITS="${AZURE_CREDITS_REMAINING:-${AZ_CREDITS:-0}}"
    GCP_CREDITS="${GCP_CREDITS_REMAINING:-${GCP_CREDITS:-0}}"
  fi
fi

AZ_CREDITS="${AZ_CREDITS:-0}"
GCP_CREDITS="${GCP_CREDITS:-0}"
export DECISION_CREDITS="azure=${AZ_CREDITS},gcp=${GCP_CREDITS}"

# --- Metrics -------------------------------------------------------
# Stub: replace with Azure/GCP/Prometheus queries in your pipeline.
cat > "${OUT_DIR}/metrics.json" <<'JSON'
{
  "azure": { "rpo": 280, "rto": 600, "latency_ms": 45 },
  "gcp":   { "rpo": 260, "rto": 480, "latency_ms": 55 }
}
JSON

echo "[signals] Wrote: ${OUT_DIR}/metrics.json"
echo "[signals] DECISION_CREDITS=${DECISION_CREDITS}"
