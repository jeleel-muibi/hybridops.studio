#!/usr/bin/env bash
# DNS cutover scaffold: switch to Azure or GCP endpoint
set -o errexit -o pipefail -o nounset
# shellcheck source=core/scripts/lib/logging.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../core/scripts/lib/logging.sh"

PROVIDER="${1:-}"
if [[ -z "${PROVIDER}" ]]; then
  echo "Usage: $0 <azure|gcp>"
  exit 2
fi

log_info "[DR] Performing DNS cutover to ${PROVIDER} (scaffold)"
# TODO: implement: az network dns record-set ... OR gcloud dns record-sets ...
log_info "No-op: integrate with your DNS provider CLI/API here."
