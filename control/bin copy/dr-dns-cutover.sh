#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." &>/dev/null && pwd -P)"
DELEGATE="${REPO_ROOT}/deployment/common/scripts/dns_cutover.sh"

usage() {
  cat <<'USAGE'
Perform DNS cutover to Azure or GCP.

Usage:
  dr-dns-cutover.sh <azure|gcp> [--yes]
USAGE
}

# --- args ---
prov="${1:-}"; shift || true
auto="false"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes) auto="true";;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2;;
  esac
  shift
done

[[ "${prov}" == "azure" || "${prov}" == "gcp" ]] || { echo "Provider must be azure|gcp" >&2; usage; exit 2; }
[[ -x "${DELEGATE}" ]] || { echo "Missing delegate: ${DELEGATE}" >&2; exit 1; }

if [[ "${auto}" != "true" ]]; then
  read -r -p "Proceed with DNS cutover to ${prov^^}? [y/N] " ans
  [[ "${ans}" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
fi

echo "Executing DNS cutover → ${prov}"
exec "${DELEGATE}" "${prov}"
