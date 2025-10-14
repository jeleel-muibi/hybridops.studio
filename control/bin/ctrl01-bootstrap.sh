#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." &>/dev/null && pwd -P)"
DELEGATE="${REPO_ROOT}/control/tools/provision/bootstrap/ctrl01-bootstrap"

usage() {
  cat <<'USAGE'
ctrl01 Day-1 bootstrap (delegates to control/tools/provision/bootstrap/ctrl01-bootstrap)

Usage:
  ctrl01-bootstrap [--dry-run]
USAGE
}

dry_run="false"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) dry_run="true"; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2;;
  esac
done

[[ -x "${DELEGATE}" ]] || { echo "Missing delegate: ${DELEGATE}" >&2; exit 1; }

exec "${DELEGATE}" ${dry_run:+--dry-run}
