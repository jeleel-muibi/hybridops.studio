#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p signals

# Populate example signals. Replace with Prometheus/Azure/GCP collectors.
cat > signals/metrics.json <<'JSON'
{
  "onprem": { "rto_s": 420, "rpo_s": 120, "latency_ms": 2 },
  "azure":  { "rto_s": 480, "rpo_s": 240, "latency_ms": 45 },
  "gcp":    { "rto_s": 540, "rpo_s": 260, "latency_ms": 55 }
}
JSON

cat > signals/credits.env <<'ENV'
AZURE_CREDITS=120
GCP_CREDITS=40
ONPREM_CREDITS=99999
ENV

echo "[fetch_signals] wrote signals/metrics.json and signals/credits.env"
