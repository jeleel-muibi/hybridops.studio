#!/usr/bin/env bash
# render_unattended.sh - Render unattended installation templates by injecting SSH public key
# Author: Jeleel Muibi | HybridOps.Studio
# Created: 2025-11-17

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
ROOT="${ROOT:-${REPO_ROOT}/infra/packer-multi-os}"
SSH_KEY_FILE="${SSH_KEY_FILE:-${HOME}/.ssh/id_ed25519.pub}"
TARGET=""
VERBOSE=0

log()  { printf "INFO: %s\n" "$*"; }
warn() { printf "WARN: %s\n" "$*"; }
die()  { printf "ERR : %s\n" "$1" >&2; exit "${2:-1}"; }

usage() {
  cat <<EOF
Usage: $(basename "$0") --root DIR [--target PATH] [--ssh-key FILE] [--verbose]

Options:
  --root DIR           Template root directory (default: infra/packer-multi-os)
  --target PATH        Only render templates under this path (e.g., linux/rocky)
  --ssh-key FILE       SSH public key file (default: ~/.ssh/id_ed25519.pub)
  --verbose, -v        Show each rendered file
  -h, --help           Show this help

Examples:
  $(basename "$0") --root infra/packer-multi-os --target linux/rocky
  $(basename "$0") --ssh-key ~/.ssh/id_rsa.pub --verbose
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)       ROOT="${2:-}"; shift 2;;
    --target)     TARGET="${2:-}"; shift 2;;
    --ssh-key)    SSH_KEY_FILE="${2:-}"; shift 2;;
    --verbose|-v) VERBOSE=1; shift;;
    -h|--help)    usage; exit 0;;
    *)            die "Unknown arg: $1" 2;;
  esac
done

[[ -n "$ROOT" && -n "$SSH_KEY_FILE" ]] || { usage; exit 2; }
[[ -d "$ROOT" ]] || die "--root not found: $ROOT" 1
[[ -f "$SSH_KEY_FILE" ]] || die "--ssh-key not found: $SSH_KEY_FILE" 1

pubkey="$(cat "$SSH_KEY_FILE" | sed 's/[[:space:]]*$//')"

pubkey_esc="${pubkey//&/\\&}"
pubkey_esc="${pubkey_esc//\//\\/}"

[[ $VERBOSE -eq 1 ]] && log "Using SSH key: ${pubkey:0:50}..."

SEARCH_PATH="${ROOT}"
if [[ -n "$TARGET" ]]; then
  SEARCH_PATH="${ROOT}/${TARGET}"
  [[ -d "$SEARCH_PATH" ]] || die "--target path not found: $SEARCH_PATH" 1
  [[ $VERBOSE -eq 1 ]] && log "Limiting to target: $TARGET"
fi

mapfile -d '' TPLS < <(find "$SEARCH_PATH" -type f \( -name 'user-data.tpl' -o -name 'ks.cfg.tpl' \) -print0)

if [[ ${#TPLS[@]} -eq 0 ]]; then
  if [[ "$SEARCH_PATH" =~ /windows/ ]]; then
    [[ $VERBOSE -eq 1 ]] && log "Skipping Windows templates (uses static Autounattend.xml)"
    exit 0
  else
    warn "No unattended templates found under $SEARCH_PATH"
    exit 0
  fi
fi

declare -a RENDERED
for tpl in "${TPLS[@]}"; do
  out="${tpl%.tpl}"

  sed "s|__VAR_SSH_PUBLIC_KEY__|${pubkey_esc}|g" "$tpl" > "$out"

  base="$(basename "$out")"
  dir="$(dirname "$out")"

  if [[ "$base" == "user-data" ]]; then
    : > "${dir}/meta-data"
  fi

  if [[ "$out" == "$ROOT"* ]]; then
    RENDERED+=("${out#$ROOT/}")
  else
    RENDERED+=("$out")
  fi

  [[ $VERBOSE -eq 1 ]] && log "Rendered: $out"
done

log "Rendered ${#RENDERED[@]} file(s):"
for f in "${RENDERED[@]}"; do
  printf " - %s\n" "$f"
done
