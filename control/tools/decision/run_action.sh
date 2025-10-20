#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

DECISION_JSON="${1:?usage: run_action.sh <decision.json> <out_dir>}"
OUT_DIR="${2:?usage: run_action.sh <decision.json> <out_dir>}"

chosen="$(jq -r '.chosen' "$DECISION_JSON")"
stamp="$(jq -r '.timestamp_utc' "$DECISION_JSON" | tr -d ':-')"

logdir="$OUT_DIR/logs"; mkdir -p "$logdir"
case "$chosen" in
  azure)  providers/azure/dr_cutover.sh  | tee "$logdir/azure_${stamp}.log"  ;;
  gcp)    providers/gcp/dr_cutover.sh    | tee "$logdir/gcp_${stamp}.log"    ;;
  onprem) providers/onprem/failback.sh   | tee "$logdir/onprem_${stamp}.log" ;;
  *)      echo "[run_action] Unknown target: $chosen" ; exit 2 ;;
esac

echo "[run_action] executed provider hook for $chosen"
