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
Join THIS host as an RKE2 agent.

Usage:
  RKE2_SERVER_URL=https://<server>:9345 RKE2_TOKEN=<token> rke2-agent.sh [--channel stable|latest] [--version vX.Y.Z]

Notes:
- Requires sudo privileges.
- Delegates to deployment/linux/scripts/rke2_install.sh --role agent
USAGE
}

# ---- args ----
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

# ---- preflight ----
: "${RKE2_SERVER_URL:?Set RKE2_SERVER_URL}"
: "${RKE2_TOKEN:?Set RKE2_TOKEN}"
require_cmd sudo
[[ -x "${DELEGATE}" ]] || { err "Missing script: ${DELEGATE}"; exit 1; }

# ---- run ----
log "Joining as RKE2 agent → ${RKE2_SERVER_URL}"
sudo env CHANNEL="${CHANNEL}" RKE2_VERSION="${VERSION}" RKE2_TOKEN="${RKE2_TOKEN}" \
  "${DELEGATE}" --role agent --server-url "${RKE2_SERVER_URL}"

ok "RKE2 agent join finished."
