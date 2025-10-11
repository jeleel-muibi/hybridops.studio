#!/usr/bin/env bash
set -euo pipefail

# Resolve paths
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." &>/dev/null && pwd -P)"
PY_HELPER="${REPO_ROOT}/core/scripts/tf_outputs_to_csv.py"
DEFAULT_IN="${REPO_ROOT}/terraform-infra/output/terraform_outputs.json"
DEFAULT_OUT="${REPO_ROOT}/artifacts/inventories/tf_outputs.csv"

# shellcheck source=lib.sh
. "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'USAGE'
Convert Terraform JSON outputs to CSV for inventory/NetBox.

Usage:
  tf-outputs-to-csv.sh [-i <terraform_outputs.json>] [-o <tf_outputs.csv>] [-h|--help]

Behavior:
- If core/scripts/tf_outputs_to_csv.py exists, it is used.
- Otherwise a generic jq-based flattener is applied (expects {"name":{"value":...}}).
USAGE
}

IN="${DEFAULT_IN}"
OUT="${DEFAULT_OUT}"

# -------- args --------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--input) IN="${2:-}"; shift 2;;
    -o|--output) OUT="${2:-}"; shift 2;;
    -h|--help) usage; exit 0;;
    *) err "Unknown argument: $1"; usage; exit 2;;
  esac
done

mkdir -p -- "$(dirname -- "${OUT}")"

# -------- python helper path --------
if [[ -f "${PY_HELPER}" ]]; then
  require_cmd python3
  [[ -f "${IN}" ]] || { err "Input not found: ${IN}"; exit 1; }
  log "Using Python helper → ${PY_HELPER}"
  python3 "${PY_HELPER}" --input "${IN}" --output "${OUT}"
  ok "Wrote ${OUT}"
  exit 0
fi

# -------- jq fallback --------
require_cmd jq
[[ -f "${IN}" ]] || { err "Input not found: ${IN}"; exit 1; }

log "Using jq fallback to flatten Terraform outputs → CSV"
{
  echo "name,value"
  jq -r 'to_entries[] | [.key, (.value.value|tostring)] | @csv' "${IN}"
} > "${OUT}"

ok "Wrote ${OUT}"
