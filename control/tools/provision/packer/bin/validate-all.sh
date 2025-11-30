#!/usr/bin/env bash
# validate-all.sh - Run packer validate for all templates
# Author: Jeleel Muibi | HybridOps.Studio
# Date: 2025-11-16

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
PACKER_ROOT="${REPO_ROOT}/infra/packer-multi-os"
ENV_FILE="${REPO_ROOT}/infra/env/.env.proxmox"

usage() {
  cat <<EOF
Usage:
  $(basename "$0") [--filter SUBSTRING]

Arguments:
  --filter SUBSTRING   Only validate var-files whose name contains SUBSTRING

Examples:
  $(basename "$0")
  $(basename "$0") --filter ubuntu
  $(basename "$0") --filter windows-server
EOF
}

FILTER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --filter)
      FILTER="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[ERROR] Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

command -v packer >/dev/null 2>&1 || { echo "[ERROR] Packer not found in PATH" >&2; exit 1; }

[[ -f "${ENV_FILE}" ]] || { echo "[ERROR] Environment file not found: ${ENV_FILE}" >&2; exit 1; }

cd "${PACKER_ROOT}"

set -a
# shellcheck source=/dev/null
source "${ENV_FILE}"
set +a

mapfile -t VAR_FILES < <(find . -type f -name '*.pkrvars.hcl' | sort)

if [[ "${#VAR_FILES[@]}" -eq 0 ]]; then
  echo "[INFO] No *.pkrvars.hcl files found under ${PACKER_ROOT}"
  exit 0
fi

TOTAL=0
OK=0
FAIL=0

for vf in "${VAR_FILES[@]}"; do
  NAME="$(basename "${vf}")"
  KEY="${NAME%.pkrvars.hcl}"

  if [[ -n "${FILTER}" && "${NAME}" != *"${FILTER}"* && "${KEY}" != *"${FILTER}"* ]]; then
    continue
  fi

  TOTAL=$((TOTAL + 1))
  echo
  echo "Validating ${KEY}"
  echo "  Var-file: ${vf}"

  if packer validate -var-file="${vf}" . >/dev/null 2>&1; then
    echo "  Result: OK"
    OK=$((OK + 1))
  else
    echo "  Result: FAILED"
    FAIL=$((FAIL + 1))
  fi
done

echo
echo "Summary:"
echo "  Checked : ${TOTAL}"
echo "  OK      : ${OK}"
echo "  Failed  : ${FAIL}"

[[ "${FAIL}" -gt 0 ]] && exit 3

exit 0
