#!/usr/bin/env bash
set -euo pipefail

# Resolve paths
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." &>/dev/null && pwd -P)"
HELPER="${REPO_ROOT}/core/scripts/netbox_sync.py"

# shellcheck source=lib.sh
. "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'USAGE'
Plan (or apply) a NetBox sync from CSV inventory.

Usage:
  NETBOX_URL=https://... NETBOX_TOKEN=... netbox-plan-sync.sh [--csv <file.csv>] [--apply] [-h|--help]

Notes:
- Default is a no-write plan (dry-run). Use --apply to perform changes if supported.
- Requires python3 and the helper: core/scripts/netbox_sync.py
USAGE
}

# -------- args --------
CSV="${REPO_ROOT}/artifacts/inventories/tf_outputs.csv"
APPLY=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --csv) CSV="${2:-}"; shift 2;;
    --apply) APPLY=true; shift;;
    -h|--help) usage; exit 0;;
    *) err "Unknown arg: $1"; usage; exit 2;;
  esac
done

# -------- preflight --------
require_cmd python3
type -t load_env >/dev/null 2>&1 && load_env || true

: "${NETBOX_URL:?Set NETBOX_URL}"
: "${NETBOX_TOKEN:?Set NETBOX_TOKEN}"

[[ -f "${CSV}" ]] || { err "CSV not found: ${CSV}"; exit 1; }
[[ -f "${HELPER}" ]] || { err "Missing helper: ${HELPER}"; exit 1; }

# -------- run --------
if [[ "${APPLY}" == "true" ]]; then
  log "APPLY: syncing NetBox from ${CSV} → ${NETBOX_URL}"
  python3 "${HELPER}" --csv "${CSV}" --kind devices --apply
else
  log "PLAN: showing proposed NetBox changes from ${CSV} (no writes)"
  python3 "${HELPER}" --csv "${CSV}" --kind devices --dry-run
fi

ok "NetBox sync finished."
