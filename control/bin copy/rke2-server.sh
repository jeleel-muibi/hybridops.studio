#!/usr/bin/env bash
set -Eeuo pipefail

\
#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/../bin/lib.sh"

usage() { cat <<'USAGE'
Install/start RKE2 server (control-plane) on THIS host.
Usage:
  rke2-server.sh [--channel stable|latest] [--version <vX.Y.Z>]

Notes:
- Requires sudo privileges.
- Delegates to deployment/linux/scripts/rke2_install.sh --role server
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

require_cmd sudo
script="deployment/linux/scripts/rke2_install.sh"
[[ -x "$script" ]] || { err "Missing script: $script"; exit 1; }

log "Installing RKE2 server (channel=${channel} version=${version:-auto})"
sudo CHANNEL="$channel" RKE2_VERSION="${version:-}" "$script" --role server
ok "RKE2 server install finished."
