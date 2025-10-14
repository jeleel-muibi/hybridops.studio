#!/usr/bin/env bash
# Utility library for control/bin wrappers.
# NOTE: This file is intended to be *sourced*. Do not enable set -euo here;
#       each wrapper should set its own shell options.

# -------- path helpers --------
# Path to this file's directory, control/, and repo root.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)"
CONTROL_DIR="$(cd -- "${SCRIPT_DIR}/.." &>/dev/null && pwd -P)"
REPO_ROOT="$(cd -- "${CONTROL_DIR}/.." &>/dev/null && pwd -P)"

# -------- tiny helpers --------
log() { printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }
err() { printf '\033[31mERROR:\033[0m %s\n' "$*" >&2; }
ok()  { printf '\033[32mOK:\033[0m %s\n' "$*"; }
die() { err "$*"; exit 1; }
require_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"; }

# Load env from control/.env or repo .env if present
# shellcheck disable=SC1090
load_env() {
  local f
  for f in "${CONTROL_DIR}/.env" "${REPO_ROOT}/.env"; do
    if [[ -f "$f" ]]; then
      . "$f"
      log "Loaded env from $f"
      return 0
    fi
  done
  return 0
}

confirm() {
  local prompt="${1:-Proceed?} [y/N]: "
  local ans
  read -r -p "$prompt" ans || true
  [[ "${ans:-}" =~ ^[Yy]$ ]]
}
