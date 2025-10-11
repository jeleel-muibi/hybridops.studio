#!/usr/bin/env bash
# ----------------------------------------------------------------------
# HybridOps.Studio | common.sh
# ----------------------------------------------------------------------
# License: MIT-0
# Purpose: Zero side-effects helper to locate the repo root and prime
#          standard environment variables for operator scripts.
#
# Contract:
#   - Exports REPO_ROOT (once discovered).
#   - Leaves shell options untouched (no set -euo pipefail here).
#   - Exports ANSIBLE_CONFIG to <repo>/deployment/ansible.cfg if unset.
# ----------------------------------------------------------------------

# Resolve the repository root and export REPO_ROOT.
resolve_root() {
  # 1) Respect a preset REPO_ROOT if it points to a directory
  if [[ -n "${REPO_ROOT:-}" && -d "${REPO_ROOT}" ]]; then
    return 0
  fi

  # 2) Try git (works anywhere inside the repo)
  if command -v git >/dev/null 2>&1; then
    local gr
    if gr="$(git rev-parse --show-toplevel 2>/dev/null)"; then
      export REPO_ROOT="$gr"
      return 0
    fi
  fi

  # 3) Walk upward from this file to find a repo marker
  local here d
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  d="$here"
  while [[ "$d" != "/" ]]; do
    if [[ -d "$d/.git" || -f "$d/Makefile" || -f "$d/README.md" ]]; then
      export REPO_ROOT="$d"
      return 0
    fi
    d="$(dirname "$d")"
  done

  # 4) Fallback for expected layout: control/tools/bash/lib → repo root (../../../../)
  REPO_ROOT="$(cd "$here/../../../../" >/dev/null 2>&1 && pwd -P)"
  if [[ -z "${REPO_ROOT}" || ! -d "${REPO_ROOT}" ]]; then
    echo "common.sh: unable to resolve REPO_ROOT" >&2
    return 1
  fi
  export REPO_ROOT
  return 0
}

# Prime ANSIBLE_CONFIG if not already set.
prime_ansible_config() {
  resolve_root || return 1
  export ANSIBLE_CONFIG="${ANSIBLE_CONFIG:-$REPO_ROOT/deployment/ansible.cfg}"
}

# Convenience one-liner for callers that just want both.
hybridops_env() {
  resolve_root || return 1
  prime_ansible_config || return 1
}
