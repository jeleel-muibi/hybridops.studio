#!/usr/bin/env bash
set -Eeuo pipefail

\
#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/../bin/lib.sh"

usage() { cat <<'USAGE'
Join THIS host as an RKE2 agent.
Usage:
  RKE2_SERVER_URL=https://<server>:9345 RKE2_TOKEN=<token> rke2-agent.sh

Optional:
  --channel stable|latest
  --version vX.Y.Z

Notes:
- Requires sudo privileges.
- Delegates to deployment/linux/scripts/rke2_install.sh --role agent
USAGE
}

channel="stable"
version=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --channel) channel="${2:-}"; shift 2;;
    --version) version="${2:-}"; shift 2;;
    -h|--help) usage; exit 0;;
    *) err "Unknown arg: $1"; usage; exit 2;;
  esac
done

: "${RKE2_SERVER_URL:?Set RKE2_SERVER_URL}"
: "${RKE2_TOKEN:?Set RKE2_TOKEN}"

require_cmd sudo
script="deployment/linux/scripts/rke2_install.sh"
[[ -x "$script" ]] || { err "Missing script: $script"; exit 1; }

log "Joining as RKE2 agent → ${RKE2_SERVER_URL}"
sudo CHANNEL="$channel" RKE2_VERSION="${version:-}" RKE2_TOKEN="$RKE2_TOKEN" \
  "$script" --role agent --server-url "$RKE2_SERVER_URL"
ok "RKE2 agent join finished."
