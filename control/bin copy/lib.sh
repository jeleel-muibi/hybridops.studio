\
#!/usr/bin/env bash
set -euo pipefail

# --- tiny helpers ---
log() { printf "[%s] %s\n" "$(date -Iseconds)" "$*"; }
err() { printf "\033[31mERROR:\033[0m %s\n" "$*" >&2; }
ok()  { printf "\033[32mOK:\033[0m %s\n" "$*"; }
require_cmd() { command -v "$1" >/dev/null 2>&1 || { err "Missing command: $1"; exit 1; }; }
here() { cd "$(dirname "${BASH_SOURCE[0]}")" && cd ..; pwd; }

load_env() {
  local base; base="$(here)"
  if [[ -f "${base}/.env" ]]; then
    # shellcheck disable=SC1090
    source "${base}/.env"
    ok "Loaded env from ${base}/.env"
  fi
}

confirm() {
  local prompt="${1:-Proceed?} [y/N]: "
  read -r -p "$prompt" ans || true
  [[ "${ans:-}" =~ ^[Yy]$ ]]
}
