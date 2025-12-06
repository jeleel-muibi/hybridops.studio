#!/usr/bin/env bash
# chain-lib.sh - Chain ID tracking and logging utilities for Packer automation
# Maintainer: HybridOps.Studio
# Created: 2025-11-17

set -euo pipefail

timestamp_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Retrieves or generates a chain ID for correlating related build operations.
# Chain IDs persist across init/build/test cycles for audit traceability.
load_chain_id() {
  local os_name="${1:-generic}"
  local root="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")}"
  local chain_dir="${root}/output/logs/packer/${os_name}/latest"
  local chain_file="${chain_dir}/chain.id"

  if [[ -f "${chain_file}" ]]; then
    cat "${chain_file}"
    return 0
  fi

  local chain="CHAIN-$(date -u +%Y%m%dT%H%M%SZ)-${os_name}"
  mkdir -p "${chain_dir}"

  # Atomic write to prevent race conditions in parallel builds
  if command -v mktemp >/dev/null 2>&1; then
    local tmp
    tmp="$(mktemp "${chain_dir}/.chain.tmp.XXXX")"
    printf '%s\n' "${chain}" > "${tmp}"
    mv -f "${tmp}" "${chain_file}"
  else
    printf '%s\n' "${chain}" > "${chain_file}"
  fi

  printf '%s\n' "${chain}"
}

write_chain_marker() {
  local chain_id="$1"
  local log_file="${2:-/dev/stdout}"
  echo "[CHAIN] CHAIN_ID=${chain_id}" | tee -a "${log_file}" >/dev/null
}

_log() {
  local level="$1"
  shift
  local msg="[$(printf '%s' "${level}" | tr '[:lower:]' '[:upper:]')] $*"
  if [[ -n "${LOG_FILE:-}" ]]; then
    echo "${msg}" | tee -a "${LOG_FILE}"
  else
    echo "${msg}"
  fi
}

log_info()  { _log info "$@"; }
log_warn()  { _log warn "$@"; }
log_error() { _log error "$@"; }
