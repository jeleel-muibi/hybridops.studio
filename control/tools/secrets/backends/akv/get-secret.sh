#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# HybridOps Studio — Azure Key Vault Secret Retrieval
# -----------------------------------------------------------------------------
# Maintainer: HybridOps.Studio
# Date: 2025-10-23 14:11:17
#
# Description:
#   Retrieves secrets from Azure Key Vault.
#   Supports both direct retrieval and service account-based authentication.
#
# Usage:
#   ./get-secret.sh --name SECRET_NAME [--vault VAULT_NAME]
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../../.." && pwd)"
SECRETS_DIR="${REPO_ROOT}/control/tools/secrets"

# Default values
SECRET_NAME=""
VAULT_NAME=""
ENV_FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name|-n)
      SECRET_NAME="$2"
      shift 2
      ;;
    --vault|-v)
      VAULT_NAME="$2"
      shift 2
      ;;
    --env|-e)
      ENV_FILE="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 --name SECRET_NAME [--vault VAULT_NAME] [--env ENV_FILE]"
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
  echo "Usage: $0 --name SECRET_NAME [--vault VAULT_NAME] [--env ENV_FILE]" >&2
  exit 1
fi

# Look for environment files in various locations
if [[ -n "$ENV_FILE" && -f "$ENV_FILE" ]]; then
  # Use specified env file
  # shellcheck disable=SC1090
  source "$ENV_FILE"
elif [[ -f "${SECRETS_DIR}/.env" ]]; then
  # Try secrets-specific env
  # shellcheck disable=SC1090
  source "${SECRETS_DIR}/.env"
elif [[ -f "${REPO_ROOT}/control/.env" ]]; then
  # Try global env
  # shellcheck disable=SC1090
  source "${REPO_ROOT}/control/.env"
fi

# If vault not specified, get from environment or extract from URL
if [[ -z "$VAULT_NAME" ]]; then
  if [[ -n "${KV_NAME:-}" ]]; then
    VAULT_NAME="$KV_NAME"
  elif [[ -n "${AZURE_KEYVAULT_URL:-}" ]]; then
    VAULT_NAME=$(echo "$AZURE_KEYVAULT_URL" | sed -e 's#https://##' -e 's#\.vault\.azure\.net/*##')
  else
    echo "Error: Vault name not specified and not found in environment" >&2
    exit 1
  fi
fi

# Check if we need to authenticate to Azure
if ! az account show &>/dev/null; then
  # Check if we have service principal credentials
  if [[ -n "${AZURE_TENANT_ID:-}" && -n "${AZURE_CLIENT_ID:-}" && -n "${AZURE_CLIENT_SECRET:-}" ]]; then
    # Authenticate with service principal
    az login --service-principal \
      -u "$AZURE_CLIENT_ID" \
      -p "$AZURE_CLIENT_SECRET" \
      --tenant "$AZURE_TENANT_ID" >/dev/null || {
        echo "Error: Azure authentication failed" >&2
        exit 1
      }
  else
    echo "Error: Not authenticated to Azure and no credentials provided" >&2
    exit 1
  fi
fi

# Try to get the secret value (try both original case and uppercase)
if ! value=$(az keyvault secret show --vault-name "$VAULT_NAME" --name "$SECRET_NAME" --query value -o tsv 2>/dev/null); then
  if ! value=$(az keyvault secret show --vault-name "$VAULT_NAME" --name "${SECRET_NAME^^}" --query value -o tsv 2>/dev/null); then
    echo "Error: Secret '$SECRET_NAME' not found in vault '$VAULT_NAME'" >&2
    exit 1
  fi
fi

# Output the value
echo "$value"
