#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# HybridOps Studio — SOPS Encryption Setup
# -----------------------------------------------------------------------------
# Maintainer: HybridOps.Studio
# Date: 2025-10-23 14:11:17
#
# Description:
#   Sets up SOPS encryption for local secrets management (ADR-0015 fallback).
#   Generates Age key for encryption/decryption and creates SOPS config.
#
# Usage:
#   ./setup-sops.sh
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../../.." && pwd)"
SECRETS_DIR="${REPO_ROOT}/control/tools/secrets"
AGE_KEY_DIR="${REPO_ROOT}/.sops/keys"
SOPS_CONFIG="${REPO_ROOT}/.sops.yaml"
AGE_KEY_FILE="${AGE_KEY_DIR}/sops-key.txt"
BACKUPS_DIR="${SECRETS_DIR}/backups"

# Check if age is installed
if ! command -v age &>/dev/null; then
  echo "Error: 'age' encryption tool is not installed."
  echo "Please install age: https://github.com/FiloSottile/age#installation"
  exit 1
fi

# Check if sops is installed
if ! command -v sops &>/dev/null; then
  echo "Error: 'sops' is not installed."
  echo "Please install sops: https://github.com/mozilla/sops#download"
  exit 1
fi

# Create Age key directory
mkdir -p "${AGE_KEY_DIR}"
chmod 700 "${AGE_KEY_DIR}"

# Generate Age key if it doesn't exist
if [[ ! -f "${AGE_KEY_FILE}" ]]; then
  echo "Generating new Age key..."
  age-keygen > "${AGE_KEY_FILE}"
  chmod 600 "${AGE_KEY_FILE}"
fi

# Extract public key
AGE_PUBLIC_KEY=$(grep "public key:" "${AGE_KEY_FILE}" | cut -d ' ' -f 4)

# Create SOPS config file
cat > "${SOPS_CONFIG}" <<EOF
# SOPS configuration file
# Created: $(date -u +"%Y-%m-%d %H:%M:%S") UTC
# Maintainer: HybridOps.Studio
creation_rules:
  - path_regex: .*\.sops\.ya?ml
    age: "${AGE_PUBLIC_KEY}"
  - path_regex: control/tools/secrets/backups/.*\.ya?ml
    age: "${AGE_PUBLIC_KEY}"
EOF

# Create backups directory if it doesn't exist
mkdir -p "${BACKUPS_DIR}"
chmod 700 "${BACKUPS_DIR}"

echo "SOPS setup complete!"
echo
echo "To encrypt a file:"
echo "  sops -e -i file.yaml"
echo
echo "To decrypt a file:"
echo "  sops -d file.sops.yaml"
echo
echo "To use SOPS fallback, export these environment variables:"
echo "  export SOPS_AGE_KEY_FILE=${AGE_KEY_FILE}"
echo "  export SECRET_BACKEND=sops"
echo
echo "Add these to your .gitignore:"
echo "  ${AGE_KEY_FILE}"
echo "  # But allow encrypted backups"
echo "  !${BACKUPS_DIR}/*.sops.yaml"

# Add entries to .gitignore if it exists
if [[ -f "${REPO_ROOT}/.gitignore" ]]; then
  echo "Updating .gitignore..."
  if ! grep -q "sops-key.txt" "${REPO_ROOT}/.gitignore"; then
    echo "# SOPS keys and unencrypted secrets (ADR-0015)" >> "${REPO_ROOT}/.gitignore"
    echo ".sops/keys/" >> "${REPO_ROOT}/.gitignore"
    echo "# Allow encrypted backups" >> "${REPO_ROOT}/.gitignore"
    echo "!control/tools/secrets/backups/*.sops.yaml" >> "${REPO_ROOT}/.gitignore"
  fi
fi
