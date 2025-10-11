#!/usr/bin/env bash
# ----------------------------------------------------------------------
# HybridOps.Studio | orchestrate.sh
# ----------------------------------------------------------------------
# Summary: Operator entrypoint for common flows (on-prem build, DR, burst).
# Contract: Resolves repo root via common.sh, then delegates to Make targets.
# Usage:
#   ./orchestrate.sh onprem
#   ./orchestrate.sh dr azure
#   CLOUD_PROVIDER=gcp ./orchestrate.sh dr
#   ./orchestrate.sh burst azure
#   ./orchestrate.sh help
# ----------------------------------------------------------------------

set -euo pipefail

# Source the minimal helper (resolve_root only)
COMMON="$(cd "$(dirname "${BASH_SOURCE[0]}")/../tools/bash/lib" && pwd -P)/common.sh"
# shellcheck source=/dev/null
source "${COMMON}"
resolve_root || { echo "Failed to resolve repo root"; exit 1; }

cd "${REPO_ROOT}"

usage() {
  cat <<'USAGE'
Usage:
  orchestrate.sh onprem
      Bootstrap core on-prem services (env.setup, sanity, RKE2, NetBox seed).

  orchestrate.sh dr <azure|gcp>
      Run the DR cutover flow against the selected cloud provider.
      You can also export CLOUD_PROVIDER=azure|gcp instead of passing the arg.

  orchestrate.sh burst <azure|gcp>
      Scale/burst in the selected provider and run a quick validation.

  orchestrate.sh help
      Show this help.

Notes:
  - This script is a thin wrapper over the root Makefile.
  - It expects the Make targets defined there to exist.
USAGE
}

ensure_provider() {
  local arg="${1:-}"
  local env="${CLOUD_PROVIDER:-}"
  if [[ -n "${arg}" ]]; then
    export CLOUD_PROVIDER="${arg}"
  elif [[ -n "${env}" ]]; then
    : # already set
  else
    echo "CLOUD_PROVIDER not set. Use: orchestrate.sh <dr|burst> <azure|gcp> or export CLOUD_PROVIDER first."
    exit 2
  fi
  case "${CLOUD_PROVIDER}" in
    azure|gcp) ;;
    *) echo "Invalid CLOUD_PROVIDER: ${CLOUD_PROVIDER} (expected 'azure' or 'gcp')"; exit 2;;
  esac
}

cmd="${1:-help}"
case "${cmd}" in
  help|-h|--help)
    usage
    ;;

  onprem)
    echo "[orchestrate] on-prem bootstrap (repo: ${REPO_ROOT})"
    make env.setup sanity
    make linux.bootstrap
    make kubernetes.rke2_install
    make netbox.seed
    ;;

  dr)
    ensure_provider "${2:-}"
    echo "[orchestrate] DR to ${CLOUD_PROVIDER}"
    CLOUD_PROVIDER="${CLOUD_PROVIDER}" make dr.db.promote
    CLOUD_PROVIDER="${CLOUD_PROVIDER}" make dr.cluster.attach
    CLOUD_PROVIDER="${CLOUD_PROVIDER}" make dr.gitops.sync
    CLOUD_PROVIDER="${CLOUD_PROVIDER}" make dr.dns.cutover
    ;;

  burst)
    ensure_provider "${2:-}"
    echo "[orchestrate] Burst scale on ${CLOUD_PROVIDER}"
    CLOUD_PROVIDER="${CLOUD_PROVIDER}" make burst.scale.up
    make burst.validate || true
    echo "[orchestrate] To scale down: CLOUD_PROVIDER=${CLOUD_PROVIDER} make burst.scale.down"
    ;;

  *)
    echo "Unknown command: ${cmd}"
    usage
    exit 1
    ;;
esac
