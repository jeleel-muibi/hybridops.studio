#!/usr/bin/env bash
set -Eeuo pipefail

\
#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/../bin/lib.sh"

usage() { cat <<'USAGE'
Convert Terraform JSON outputs → CSV for inventory/NetBox.
Usage:
  tf-outputs-to-csv.sh [-i <terraform_outputs.json>] [-o artifacts/inventories/tf_outputs.csv]

If Python helper exists (core/scripts/tf_outputs_to_csv.py) it is used.
Otherwise falls back to a jq-based generic flattener.
USAGE
}

in="terraform-infra/output/terraform_outputs.json"
out="artifacts/inventories/tf_outputs.csv"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--input) in="${2:-}"; shift 2;;
    -o|--output) out="${2:-}"; shift 2;;
    -h|--help) usage; exit 0;;
    *) err "Unknown arg: $1"; usage; exit 2;;
  esac
done

mkdir -p "$(dirname "$out")"

if [[ -f "core/scripts/tf_outputs_to_csv.py" ]]; then
  require_cmd python3
  log "Using Python helper → core/scripts/tf_outputs_to_csv.py"
  python3 core/scripts/tf_outputs_to_csv.py --input "$in" --output "$out"
  ok "Wrote $out"
  exit 0
fi

require_cmd jq

if [[ ! -f "$in" ]]; then
  err "Input not found: $in"
  exit 1
fi

log "Using jq fallback to flatten Terraform outputs → CSV"
# Generic flattener: assumes outputs is an object of { name: { value: ... } }
# Produces rows: name,value (stringified)
{
  echo "name,value"
  jq -r 'to_entries[] | [.key, (.value.value|tostring)] | @csv' "$in"
} > "$out"

ok "Wrote $out"
