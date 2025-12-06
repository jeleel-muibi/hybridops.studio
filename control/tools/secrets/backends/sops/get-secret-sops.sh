#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# HybridOps Studio — SOPS Backend Helper
# -----------------------------------------------------------------------------
# Maintainer: HybridOps.Studio
# Date: 2025-10-23 14:11:17
#
# Description:
#   Backend-specific helper for retrieving secrets from SOPS-encrypted files.
#   Called by the main secrets.sh unified interface.
#
# Usage:
#   ./get-secret-sops.sh --name SECRET_NAME [--service SERVICE]
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../../.." && pwd)"
SECRETS_DIR="${REPO_ROOT}/control/tools/secrets"
BACKUPS_DIR="${SECRETS_DIR}/backups"

# Default values
SECRET_NAME=""
SERVICE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name|-n)
      SECRET_NAME="$2"
      shift 2
      ;;
    --service|-s)
      SERVICE="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 --name SECRET_NAME [--service SERVICE]"
      exit 0
      ;;
    *)
      echo "Error: Unknown option '$1'" >&2
      exit 1
      ;;
  esac
done

# Validate required arguments
if [[ -z "$SECRET_NAME" ]]; then
  echo "Error: --name is required" >&2
  echo "Usage: $0 --name SECRET_NAME [--service SERVICE]" >&2
  exit 1
fi

# Check if SOPS is installed
if ! command -v sops &>/dev/null; then
  echo "Error: SOPS is not installed" >&2
  echo "Please install SOPS: https://github.com/mozilla/sops#download" >&2
  exit 1
fi

# If service is provided, use that specific backup file
if [[ -n "$SERVICE" ]]; then
  SOPS_FILE="${BACKUPS_DIR}/${SERVICE}.sops.yaml"

  if [[ ! -f "$SOPS_FILE" ]]; then
    echo "Error: SOPS backup file not found for service '$SERVICE'" >&2
    exit 1
  fi

  # Extract the secret from the specific file
  if ! VALUE=$(sops -d "$SOPS_FILE" | grep -E "^${SECRET_NAME}:" | sed "s/^${SECRET_NAME}:[[:space:]]*//g"); then
    echo "Error: Secret '$SECRET_NAME' not found in $SOPS_FILE" >&2
    exit 1
  fi
else
  # If no service specified, search all backup files
  VALUE=""
  FOUND=0

  # Check if backups directory exists
  if [[ ! -d "$BACKUPS_DIR" ]]; then
    echo "Error: Backups directory not found: $BACKUPS_DIR" >&2
    exit 1
  fi

  # Search each backup file
  for file in "${BACKUPS_DIR}"/*.sops.yaml; do
    if [[ -f "$file" ]]; then
      if TMP_VALUE=$(sops -d "$file" | grep -E "^${SECRET_NAME}:" | sed "s/^${SECRET_NAME}:[[:space:]]*//g" 2>/dev/null); then
        VALUE="$TMP_VALUE"
        FOUND=1
        break
      fi
    fi
  done

  if [[ $FOUND -eq 0 ]]; then
    echo "Error: Secret '$SECRET_NAME' not found in any SOPS backup files" >&2
    exit 1
  fi
fi

# Output the secret value
echo "$VALUE"
