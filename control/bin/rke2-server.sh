#!/usr/bin/env bash
set -euo pipefail

# Resolve paths
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." &>/dev/null && pwd -P)"
DELEGATE="${REPO_ROOT}/deployment/linux/scripts/rke2_install.sh"

# shellcheck source=lib.sh
. "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'USAGE'
Install/start RKE2 server (control-plane) on THIS host.

Usage:
  rke2-server.sh [--channel <stable|latest>] [--version vX.Y.Z]

Notes:
- Requires sudo privileges.
- Delegates to deployment/linux/scripts/rke2_install.sh --role server
USAGE
}

# -------- args --------
CHANNEL="stable"
VERSION=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --channel) CHANNEL="${2:-}"; shift 2;;
    --version) VERSION="${2:-}"; shift 2;;
    -h|--help) usage; exit 0;;
    *) err "Unknown arg: $1"; usage; exit 2;;
  esac
done

# -------- preflight --------
require_cmd sudo
[[ -x "${DELEGATE}" ]] || { err "Missing delegate script: ${DELEGATE}"; exit 1; }

# -------- run --------
log "Installing RKE2 server (channel=${CHANNEL} version=${VERSION:-auto})"
sudo CHANNEL="${CHANNEL}" RKE2_VERSION="${VERSION:-}" \
  "${DELEGATE}" --role server
ok "RKE2 server install finished."
