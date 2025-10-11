#!/usr/bin/env bash
set -euo pipefail

# Resolve paths
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." &>/dev/null && pwd -P)"
DELEGATE="${REPO_ROOT}/deployment/kubernetes/scripts/gitops_bootstrap.sh"
FALLBACK_YAML="${REPO_ROOT}/deployment/kubernetes/gitops/bootstrap.yaml"

usage() {
  cat <<'USAGE'
Apply GitOps bootstrap (Argo/Flux) to the current kube-context.

Usage:
  gitops-bootstrap.sh [--dry-run] [-h|--help]
USAGE
}

# Bring in helper functions (log, err, ok, require_cmd, confirm, load_env, …)
# shellcheck source=lib.sh
. "${SCRIPT_DIR}/lib.sh"

# -------- args --------
dryrun=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) dryrun=true;;
    -h|--help) usage; exit 0;;
    *) err "Unknown arg: $1"; usage; exit 2;;
  esac
  shift
done

require_cmd kubectl
# Load env if helper exists
type -t load_env >/dev/null 2>&1 && load_env || true

ctx="$(kubectl config current-context 2>/dev/null || echo 'n/a')"
if [[ "${dryrun}" == "true" ]]; then
  log "[DRY-RUN] Would bootstrap GitOps (kube-context: ${ctx})"
  exit 0
fi

if [[ -x "${DELEGATE}" ]]; then
  log "Running bootstrap script → ${DELEGATE} (kube-context: ${ctx})"
  "${DELEGATE}"
elif [[ -f "${FALLBACK_YAML}" ]]; then
  log "Applying bootstrap manifest → ${FALLBACK_YAML} (kube-context: ${ctx})"
  kubectl apply -f "${FALLBACK_YAML}"
else
  err "No bootstrap entrypoint found:
  - missing script: ${DELEGATE}
  - missing manifest: ${FALLBACK_YAML}"
  exit 1
fi

ok "GitOps bootstrap completed."
