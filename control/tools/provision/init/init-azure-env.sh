#!/usr/bin/env bash
set -euo pipefail

# init-azure-env.sh - Generate Azure Terraform tfvars
# Purpose: Combine azure.conf and control/secrets.env into azure.auto.tfvars.json
# Author: Jeleel Muibi | HybridOps.Studio
# Date: 2025-11-28

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || cd "${SCRIPT_DIR}/../../.." && pwd)"

CONF_DIR="${SCRIPT_DIR}/.conf"
AZURE_CONF="${CONF_DIR}/azure.conf"
SECRETS_FILE="${REPO_ROOT}/control/secrets.env"

ENV_DIR="${REPO_ROOT}/infra/env"
OUT_FILE="${ENV_DIR}/azure.auto.tfvars.json"

if [[ ! -f "${AZURE_CONF}" ]]; then
  echo "Missing Azure config: ${AZURE_CONF}" >&2
  exit 2
fi

# shellcheck source=/dev/null
source "${AZURE_CONF}"

if [[ -f "${SECRETS_FILE}" ]]; then
  # shellcheck source=/dev/null
  source "${SECRETS_FILE}"
fi

for var in AZ_SUBSCRIPTION_ID AZ_TENANT_ID AZ_LOCATION AZ_CLIENT_ID AZ_CLIENT_SECRET; do
  if [[ -z "${!var:-}" ]]; then
    echo "Missing required Azure variable: ${var} (azure.conf or control/secrets.env)" >&2
    exit 2
  fi
fi

mkdir -p "${ENV_DIR}"

cat > "${OUT_FILE}" <<EOF
{
  "subscription_id": "${AZ_SUBSCRIPTION_ID}",
  "tenant_id": "${AZ_TENANT_ID}",
  "client_id": "${AZ_CLIENT_ID}",
  "client_secret": "${AZ_CLIENT_SECRET}",
  "location": "${AZ_LOCATION}"
}
EOF

echo "Azure Terraform env written to: ${OUT_FILE}"
