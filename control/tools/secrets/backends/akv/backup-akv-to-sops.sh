#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# HybridOps Studio — AKV to SOPS Backup
# -----------------------------------------------------------------------------
# Maintainer: HybridOps.Studio
# Date: 2025-10-23 16:57:31
#
# Description:
#   Backs up selected secrets from Azure Key Vault to SOPS using an allowlist.
#   Implements the principle of least privilege for secret backup.
#
# Usage:
#   ./backup-akv-to-sops.sh --service SERVICE_NAME [--output-dir DIR] [--env FILE] [--quiet]
#
# Services:
#   - jenkins: All secrets starting with "jenkins-" or in allowlist
#   - netbox: All secrets starting with "netbox-" or in allowlist
#   - k8s: All secrets starting with "k8s-" or in allowlist
#   - all: All secrets in allowlist (or all if no allowlist)
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../../.." && pwd)"
SECRETS_DIR="${REPO_ROOT}/control/tools/secrets"
QUIET=0
ENV_FILE=""
SERVICE=""
OUTPUT_DIR="${SECRETS_DIR}/backups"
LOG_FILE="/var/log/akv-backup.log"

log() {
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "[$timestamp] $*" | tee -a "$LOG_FILE"
}

if [[ $QUIET -eq 1 ]]; then
  log() { :; }
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --service|-s)
      SERVICE="$2"
      shift 2
      ;;
    --output-dir|-o)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --env|-e)
      ENV_FILE="$2"
      shift 2
      ;;
    --quiet|-q)
      QUIET=1
      shift
      ;;
    --help|-h)
      echo "Usage: $0 --service SERVICE_NAME [--output-dir DIR] [--env FILE] [--quiet]"
      echo "Services: jenkins, netbox, k8s, all"
      exit 0
      ;;
    *)
      echo "Error: Unknown option '$1'" >&2
      exit 1
      ;;
  esac
done

# Validate service
if [[ -z "$SERVICE" ]]; then
  echo "Error: --service is required" >&2
  echo "Available services: jenkins, netbox, k8s, all" >&2
  exit 1
fi

# Define service prefix mappings
declare -A SERVICE_PREFIXES
SERVICE_PREFIXES["jenkins"]="jenkins-"
SERVICE_PREFIXES["netbox"]="netbox-"
SERVICE_PREFIXES["k8s"]="k8s-"
SERVICE_PREFIXES["all"]=""  # Empty prefix means all secrets

if [[ -z "${SERVICE_PREFIXES[$SERVICE]:-}" ]]; then
  echo "Error: Unknown service '$SERVICE'" >&2
  echo "Available services: ${!SERVICE_PREFIXES[*]}" >&2
  exit 1
fi

# Load environment if needed
if [[ -n "$ENV_FILE" ]]; then
  log "Loading environment from $ENV_FILE"
  # shellcheck disable=SC1090
  source "$ENV_FILE"
# First try secrets dir
elif [[ -f "${SECRETS_DIR}/.env" ]]; then
  log "Loading environment from ${SECRETS_DIR}/.env"
  # shellcheck disable=SC1090
  source "${SECRETS_DIR}/.env"
# Next try control root
elif [[ -f "${REPO_ROOT}/control/.env" ]]; then
  log "Loading environment from ${REPO_ROOT}/control/.env"
  # shellcheck disable=SC1090
  source "${REPO_ROOT}/control/.env"
fi

# Determine allowlist file
ALLOWLIST_FILE="${ALLOWLIST_FILE:-${SECRETS_DIR}/backup-allowlist.txt}"

# Check if allowlist exists
if [[ -f "$ALLOWLIST_FILE" ]]; then
  log "Using allowlist from $ALLOWLIST_FILE"
  USING_ALLOWLIST=1
else
  log "No allowlist found at $ALLOWLIST_FILE, using prefix-based filtering"
  USING_ALLOWLIST=0
fi

# Validate Azure credentials
if [[ -z "${AZURE_TENANT_ID:-}" || -z "${AZURE_CLIENT_ID:-}" ||
      -z "${AZURE_CLIENT_SECRET:-}" ]]; then
  echo "Error: Missing required Azure environment variables" >&2
  exit 1
fi

# Determine Key Vault URL or name
if [[ -z "${AZURE_KEYVAULT_URL:-}" && -n "${DEFAULT_VAULT_NAME:-}" ]]; then
  AZURE_KEYVAULT_URL="https://${DEFAULT_VAULT_NAME}.vault.azure.net/"
fi

if [[ -z "${AZURE_KEYVAULT_URL:-}" ]]; then
  echo "Error: Neither AZURE_KEYVAULT_URL nor DEFAULT_VAULT_NAME is set" >&2
  exit 1
fi

# Extract vault name from URL
KV_NAME=$(echo "$AZURE_KEYVAULT_URL" | sed -e 's#https://##' -e 's#\.vault\.azure\.net/*##')

# Authenticate to Azure
log "Authenticating to Azure..."
az login --service-principal \
  -u "$AZURE_CLIENT_ID" \
  -p "$AZURE_CLIENT_SECRET" \
  --tenant "$AZURE_TENANT_ID" >/dev/null || {
    echo "Error: Azure authentication failed" >&2
    exit 1
  }

# Create output directory
mkdir -p "$OUTPUT_DIR"
chmod 700 "$OUTPUT_DIR"

# Create temp file
TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"' EXIT

# Header for the YAML file
cat > "$TEMP_FILE" <<EOF
# Azure Key Vault backup - $SERVICE service
# Created: $(date -u +"%Y-%m-%d %H:%M:%S") UTC
# Source: $AZURE_KEYVAULT_URL
# DO NOT EDIT - AUTO-GENERATED
EOF

# Get the prefix for the requested service
PREFIX="${SERVICE_PREFIXES[$SERVICE]}"

# Load allowlist if it exists
if [[ $USING_ALLOWLIST -eq 1 ]]; then
  # Load allowlist into array, ignoring comments and empty lines
  readarray -t ALLOWED_SECRETS < <(grep -v '^#' "$ALLOWLIST_FILE" | grep -v '^[[:space:]]*$')
  log "Loaded ${#ALLOWED_SECRETS[@]} secrets from allowlist"
fi

# List all secrets in the vault
log "Listing secrets in vault $KV_NAME..."
SECRET_NAMES=$(az keyvault secret list --vault-name "$KV_NAME" --query "[].name" -o tsv)

# Count for reporting
SECRET_COUNT=0

# Process each secret
for secret_name in $SECRET_NAMES; do
  # If using allowlist, only backup secrets in the list
  if [[ $USING_ALLOWLIST -eq 1 ]]; then
    # Check if secret is in the allowlist
    if ! printf '%s\n' "${ALLOWED_SECRETS[@]}" | grep -q -x "$secret_name"; then
      continue
    fi
  else
    # Otherwise use prefix-based filtering
    # Skip if it doesn't match our prefix (except for 'all' service)
    if [[ "$SERVICE" != "all" && ! "$secret_name" == "$PREFIX"* ]]; then
      continue
    fi
  fi

  log "Exporting: $secret_name"

  # Get secret value
  if ! value=$(az keyvault secret show --vault-name "$KV_NAME" --name "$secret_name" --query "value" -o tsv 2>/dev/null); then
    log "Warning: Failed to retrieve $secret_name"
    continue
  fi

  # Add to YAML
  echo "$secret_name: $value" >> "$TEMP_FILE"
  SECRET_COUNT=$((SECRET_COUNT + 1))
done

# Only proceed if we found secrets
if [[ $SECRET_COUNT -eq 0 ]]; then
  if [[ $USING_ALLOWLIST -eq 1 ]]; then
    log "No secrets from allowlist found in vault"
  else
    log "No secrets found for service $SERVICE with prefix '$PREFIX'"
  fi
  exit 0
fi

# Encrypt with SOPS
SOPS_FILE="${OUTPUT_DIR}/${SERVICE}.sops.yaml"
log "Found $SECRET_COUNT secrets, encrypting to $SOPS_FILE..."

if ! sops -e "$TEMP_FILE" > "$SOPS_FILE"; then
  echo "Error: SOPS encryption failed" >&2
  exit 1
fi

# Set secure permissions
chmod 600 "$SOPS_FILE"

log "Backup complete: $SOPS_FILE ($SECRET_COUNT secrets)"

# Create machine-readable status for monitoring
cat > "${OUTPUT_DIR}/${SERVICE}-status.json" <<EOF
{
  "service": "$SERVICE",
  "backup_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "source": "$AZURE_KEYVAULT_URL",
  "secrets_count": $SECRET_COUNT,
  "status": "success",
  "file": "$SOPS_FILE",
  "using_allowlist": $USING_ALLOWLIST
}
EOF

# Logout from Azure
az account clear >/dev/null 2>&1 || true
