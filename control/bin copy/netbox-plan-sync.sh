#!/usr/bin/env bash
set -Eeuo pipefail

\
#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/../bin/lib.sh"

usage() { cat <<'USAGE'
Plan (or apply) a NetBox sync from CSV inventory.
Usage:
  NETBOX_URL=https://... NETBOX_TOKEN=... netbox-plan-sync.sh [--csv artifacts/inventories/tf_outputs.csv] [--apply]

Default is a no-write plan. Use --apply to perform changes if the helper supports it.
USAGE
}

csv="artifacts/inventories/tf_outputs.csv"
apply=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --csv) csv="${2:-}"; shift 2;;
    --apply) apply=true; shift;;
    -h|--help) usage; exit 0;;
    *) err "Unknown arg: $1"; usage; exit 2;;
  esac
done

load_env
: "${NETBOX_URL:?Set NETBOX_URL}"
: "${NETBOX_TOKEN:?Set NETBOX_TOKEN}"

helper="core/scripts/netbox_sync.py"
if [[ ! -f "$helper" ]]; then
  err "Missing helper: $helper"
  exit 1
fi

require_cmd python3

if [[ "$apply" == "true" ]]; then
  log "APPLY: syncing NetBox from $csv → $NETBOX_URL"
  python3 "$helper" --csv "$csv" --kind devices --apply
else
  log "PLAN: showing proposed NetBox changes from $csv (no writes)"
  python3 "$helper" --csv "$csv" --kind devices --dry-run
fi
ok "NetBox sync finished."
