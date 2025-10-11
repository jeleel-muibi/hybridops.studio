#!/usr/bin/env bash
set -Eeuo pipefail

\
#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/../bin/lib.sh"

usage() { cat <<'USAGE'
Apply GitOps bootstrap (Argo/Flux) to the current kube-context.
Usage:
  gitops-bootstrap.sh [--dry-run]

Looks for:
- deployment/kubernetes/scripts/gitops_bootstrap.sh (preferred)
- fallback: kubectl apply -f deployment/kubernetes/gitops/bootstrap.yaml
USAGE
}

dryrun=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) dryrun=true; shift;;
    -h|--help) usage; exit 0;;
    *) err "Unknown arg: $1"; usage; exit 2;;
  esac
done

require_cmd kubectl
load_env

script="deployment/kubernetes/scripts/gitops_bootstrap.sh"
yaml="deployment/kubernetes/gitops/bootstrap.yaml"

if [[ "$dryrun" == "true" ]]; then
  log "[DRY-RUN] Would bootstrap GitOps (current context: $(kubectl config current-context || echo n/a))"
  exit 0
fi

if [[ -x "$script" ]]; then
  log "Running bootstrap script → $script"
  "$script"
elif [[ -f "$yaml" ]]; then
  log "Applying bootstrap yaml → $yaml"
  kubectl apply -f "$yaml"
else
  err "No bootstrap entrypoint found."
  exit 1
fi
ok "GitOps bootstrap completed."
