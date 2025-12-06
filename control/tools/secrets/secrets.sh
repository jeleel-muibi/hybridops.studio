#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# HybridOps Studio — Unified Secret Access Layer
# -----------------------------------------------------------------------------
# Maintainer: HybridOps.Studio
# Date: 2025-10-23 16:57:31
#
# Description:
#   Implements ADR-0015 secret management with AKV as primary source
#   and SOPS as fallback for offline operation.
#
# Usage:
#   ./secrets.sh get SECRET_NAME [--service SERVICE]
#   ./secrets.sh backup SERVICE
# -----------------------------------------------------------------------------

set -euo pipefail

# Repository structure detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
BACKUPS_DIR="${SCRIPT_DIR}/backups"
LOG_FILE="/var/log/hybridops-secrets.log"

# Function: Logging
log() {
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*" | tee -a "$LOG_FILE"
}

# Function: Load Azure auth credentials
load_auth() {
  # Check for .env file in secrets directory first (preferred)
  if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
  # Fall back to control/.env if it exists (for compatibility)
  elif [[ -f "${REPO_ROOT}/control/.env" ]]; then
    # shellcheck disable=SC1090
    source "${REPO_ROOT}/control/.env"
  else
    echo "Error: Auth file not found at $ENV_FILE" >&2
    echo "Create it by copying .env.example and providing valid Azure credentials" >&2
    return 1
  fi

  # Validate required variables
  local missing=()
  [[ -z "${AZURE_TENANT_ID:-}" ]] && missing+=("AZURE_TENANT_ID")
  [[ -z "${AZURE_CLIENT_ID:-}" ]] && missing+=("AZURE_CLIENT_ID")
  [[ -z "${AZURE_CLIENT_SECRET:-}" ]] && missing+=("AZURE_CLIENT_SECRET")

  # Check for either AZURE_KEYVAULT_URL or DEFAULT_VAULT_NAME
  if [[ -z "${AZURE_KEYVAULT_URL:-}" && -z "${DEFAULT_VAULT_NAME:-}" ]]; then
    missing+=("AZURE_KEYVAULT_URL or DEFAULT_VAULT_NAME")
  elif [[ -n "${DEFAULT_VAULT_NAME:-}" && -z "${AZURE_KEYVAULT_URL:-}" ]]; then
    # Set AZURE_KEYVAULT_URL from DEFAULT_VAULT_NAME
    AZURE_KEYVAULT_URL="https://${DEFAULT_VAULT_NAME}.vault.azure.net/"
    export AZURE_KEYVAULT_URL
  fi

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Error: Missing required variables in env file: ${missing[*]}" >&2
    return 1
  fi

  # Extract vault name from URL
  KV_NAME=$(echo "$AZURE_KEYVAULT_URL" | sed -e 's#https://##' -e 's#\.vault\.azure\.net/*##')

  # Set default backend if not specified
  SECRET_BACKEND="${SECRET_BACKEND:-akv}"
}

# Function: Get a secret based on current backend
get_secret() {
  local secret_name="$1"
  local service="${2:-}"

  case "${SECRET_BACKEND:-akv}" in
    akv)
      # Try AKV first, fallback to SOPS if AKV fails
      if secret_value=$(get_secret_from_akv "$secret_name" 2>/dev/null); then
        echo "$secret_value"
      else
        # Fallback to SOPS
        if secret_value=$(get_secret_from_sops "$secret_name" "$service" 2>/dev/null); then
          echo "$secret_value"
        else
          echo "Error: Secret '$secret_name' not found in AKV or SOPS backups" >&2
          return 1
        fi
      fi
      ;;
    sops)
      # Try SOPS first, no fallback
      if secret_value=$(get_secret_from_sops "$secret_name" "$service"); then
        echo "$secret_value"
      else
        return 1
      fi
      ;;
    *)
      echo "Error: Unknown backend '${SECRET_BACKEND}'" >&2
      echo "Supported backends: akv, sops" >&2
      return 1
      ;;
  esac
}

# Function: Get a secret from AKV
get_secret_from_akv() {
  local secret_name="$1"

  # Check if we have backend-specific script available
  if [[ -x "${SCRIPT_DIR}/backends/akv/get-secret.sh" ]]; then
    # Use the backend-specific script
    "${SCRIPT_DIR}/backends/akv/get-secret.sh" --name "$secret_name"
    return $?
  fi

  # Fallback to direct Azure CLI if backend script not available
  # Azure CLI login if needed
  if ! az account show &>/dev/null; then
    az login --service-principal \
      -u "$AZURE_CLIENT_ID" \
      -p "$AZURE_CLIENT_SECRET" \
      --tenant "$AZURE_TENANT_ID" >/dev/null || {
        echo "Error: Azure authentication failed" >&2
        return 1
      }
  fi

  # Try to get the secret value (try both original case and uppercase)
  local value
  if ! value=$(az keyvault secret show --vault-name "$KV_NAME" --name "$secret_name" --query value -o tsv 2>/dev/null); then
    if ! value=$(az keyvault secret show --vault-name "$KV_NAME" --name "${secret_name^^}" --query value -o tsv 2>/dev/null); then
      echo "Error: Secret '$secret_name' not found in vault" >&2
      return 1
    fi
  fi

  # Output the value (to be captured by caller)
  echo "$value"
}

# Function: Get a secret from SOPS backup
get_secret_from_sops() {
  local secret_name="$1"
  local service="${2:-}"

  # Override SOPS file location if specified in environment
  local sops_file="${SOPS_SECRETS_FILE:-}"

  # Check if we have backend-specific script available
  if [[ -x "${SCRIPT_DIR}/backends/sops/get-secret-sops.sh" ]]; then
    local args=("--name" "$secret_name")
    [[ -n "$service" ]] && args+=("--service" "$service")
    [[ -n "$sops_file" ]] && args+=("--file" "$sops_file")

    # Use the backend-specific script
    "${SCRIPT_DIR}/backends/sops/get-secret-sops.sh" "${args[@]}"
    return $?
  fi

  # Fallback to direct SOPS implementation

  # If SOPS_SECRETS_FILE is specified, use that
  if [[ -n "$sops_file" && -f "$sops_file" ]]; then
    # Use specified file
    :
  # If service provided, check that service's backup file
  elif [[ -n "$service" ]]; then
    sops_file="${BACKUPS_DIR}/${service}.sops.yaml"
    if [[ ! -f "$sops_file" ]]; then
      echo "Error: No SOPS backup found for service '$service'" >&2
      return 1
    fi
  else
    # Try to find the secret in any backup file
    for file in "${BACKUPS_DIR}"/*.sops.yaml; do
      if [[ -f "$file" ]]; then
        if sops -d "$file" 2>/dev/null | grep -q "^${secret_name}:"; then
          sops_file="$file"
          break
        fi
      fi
    done
  fi

  if [[ -z "${sops_file:-}" || ! -f "${sops_file:-}" ]]; then
    echo "Error: Secret '$secret_name' not found in any SOPS backup" >&2
    return 1
  fi

  # Extract the secret value
  local value
  value=$(sops -d "$sops_file" | grep -E "^${secret_name}:" | sed "s/^${secret_name}:[[:space:]]*//g")

  if [[ -z "$value" ]]; then
    echo "Error: Failed to extract value for '$secret_name' from SOPS backup" >&2
    return 1
  fi

  # Output the value
  echo "$value"
}

# Function: Backup service secrets from AKV to SOPS
backup_service() {
  local service="$1"

  # Check if we have backend-specific backup script available
  if [[ -x "${SCRIPT_DIR}/backends/akv/backup-akv-to-sops.sh" ]]; then
    # Use the backend-specific script
    "${SCRIPT_DIR}/backends/akv/backup-akv-to-sops.sh" --service "$service" --output-dir "${BACKUPS_DIR}"
    return $?
  fi

  # Fallback implementation
  # Service prefix mappings
  local prefix
  case "$service" in
    jenkins) prefix="jenkins-" ;;
    netbox)  prefix="netbox-" ;;
    k8s)     prefix="k8s-" ;;
    all)     prefix="" ;;
    *)
      echo "Error: Unknown service '$service'" >&2
      echo "Supported services: jenkins, netbox, k8s, all" >&2
      return 1
      ;;
  esac

  # Ensure backup directory exists
  mkdir -p "$BACKUPS_DIR"
  chmod 700 "$BACKUPS_DIR"

  # Azure CLI login
  az login --service-principal \
    -u "$AZURE_CLIENT_ID" \
    -p "$AZURE_CLIENT_SECRET" \
    --tenant "$AZURE_TENANT_ID" >/dev/null || {
      echo "Error: Azure authentication failed" >&2
      return 1
    }

  # Create temp file for unencrypted secrets
  local temp_file backup_file
  temp_file=$(mktemp)
  trap 'rm -f "$temp_file"' EXIT

  # Header for YAML file
  cat > "$temp_file" <<EOF
# Azure Key Vault backup - $service service
# Created: $(date -u +"%Y-%m-%d %H:%M:%S") UTC
# Source: $AZURE_KEYVAULT_URL
# DO NOT EDIT - AUTO-GENERATED
EOF

  # List secrets in vault
  log "Listing secrets in vault $KV_NAME..."
  local secret_names secret_count=0
  secret_names=$(az keyvault secret list --vault-name "$KV_NAME" --query "[].name" -o tsv)

  # Export matching secrets
  for secret_name in $secret_names; do
    # Skip if doesn't match prefix (except for 'all')
    if [[ "$service" != "all" && ! "$secret_name" == "$prefix"* ]]; then
      continue
    fi

    log "Exporting: $secret_name"

    # Get secret value
    local value
    if ! value=$(az keyvault secret show --vault-name "$KV_NAME" --name "$secret_name" --query "value" -o tsv 2>/dev/null); then
      log "Warning: Failed to retrieve $secret_name"
      continue
    fi

    # Add to YAML file
    echo "$secret_name: $value" >> "$temp_file"
    secret_count=$((secret_count + 1))
  done

  # Only proceed if we found secrets
  if [[ $secret_count -eq 0 ]]; then
    log "No secrets found for service $service with prefix '$prefix'"
    return 0
  fi

  # Encrypt with SOPS
  backup_file="${BACKUPS_DIR}/${service}.sops.yaml"
  log "Found $secret_count secrets, encrypting to $backup_file..."

  if ! sops -e "$temp_file" > "$backup_file"; then
    echo "Error: SOPS encryption failed" >&2
    return 1
  fi

  # Set secure permissions
  chmod 600 "$backup_file"

  log "Backup complete: $backup_file ($secret_count secrets)"

  # Create status file for monitoring
  cat > "${BACKUPS_DIR}/${service}-status.json" <<EOF
{
  "service": "$service",
  "backup_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "source": "$AZURE_KEYVAULT_URL",
  "secrets_count": $secret_count,
  "status": "success",
  "file": "$backup_file"
}
EOF

  # Logout from Azure
  az account clear >/dev/null 2>&1 || true

  return 0
}

# Main command handling
case "${1:-}" in
  get)
    # Secret retrieval command
    if [[ -z "${2:-}" ]]; then
      echo "Usage: $0 get SECRET_NAME [--service SERVICE]" >&2
      exit 1
    fi

    secret_name="$2"
    service=""

    # Check for service option
    if [[ "${3:-}" == "--service" && -n "${4:-}" ]]; then
      service="$4"
    fi

    # Load auth
    load_auth || exit 1

    # Get secret using appropriate backend
    get_secret "$secret_name" "$service"
    ;;

  backup)
    # Backup command
    if [[ -z "${2:-}" ]]; then
      echo "Usage: $0 backup SERVICE" >&2
      echo "Services: jenkins, netbox, k8s, all" >&2
      exit 1
    fi

    # Load auth
    load_auth || exit 1

    # Backup the specified service
    backup_service "$2"
    ;;

  help|--help|-h)
    echo "Usage:"
    echo "  $0 get SECRET_NAME [--service SERVICE]   Get a secret from AKV or SOPS backup"
    echo "  $0 backup SERVICE                       Backup service secrets from AKV to SOPS"
    echo
    echo "Services: jenkins, netbox, k8s, all"
    echo
    echo "Environment variables (from .env file):"
    echo "  SECRET_BACKEND        Backend to use (akv or sops, default: akv)"
    echo "  ALLOWLIST_FILE        Path to backup allowlist (default: backup-allowlist.txt)"
    echo "  SOPS_SECRETS_FILE     Path to SOPS secrets file (for sops backend)"
    echo
    echo "Examples:"
    echo "  $0 get jenkins-admin-password"
    echo "  $0 backup jenkins"
    echo
    echo "To use SOPS offline mode:"
    echo "  SECRET_BACKEND=sops $0 get jenkins-admin-password"
    ;;

  *)
    echo "Unknown command: ${1:-}" >&2
    echo "Usage: $0 {get|backup|help}" >&2
    exit 1
    ;;
esac
