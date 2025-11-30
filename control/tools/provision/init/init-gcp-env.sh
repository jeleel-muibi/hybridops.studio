#!/usr/bin/env bash
set -euo pipefail

# init-gcp-env.sh - Generate GCP Terraform tfvars
# Purpose: Combine gcp.conf and control/secrets.env into gcp.auto.tfvars.json
# Author: Jeleel Muibi | HybridOps.Studio
# Date: 2025-11-28

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || cd "${SCRIPT_DIR}/../../.." && pwd)"

CONF_DIR="${SCRIPT_DIR}/.conf"
GCP_CONF="${CONF_DIR}/gcp.conf"
SECRETS_FILE="${REPO_ROOT}/control/secrets.env"

ENV_DIR="${REPO_ROOT}/infra/env"
OUT_FILE="${ENV_DIR}/gcp.auto.tfvars.json"

if [[ ! -f "${GCP_CONF}" ]]; then
  echo "Missing GCP config: ${GCP_CONF}" >&2
  exit 2
fi

# shellcheck source=/dev/null
source "${GCP_CONF}"

if [[ -f "${SECRETS_FILE}" ]]; then
  # shellcheck source=/dev/null
  source "${SECRETS_FILE}"
fi

for var in GCP_PROJECT_ID GCP_REGION GCP_CREDENTIALS_JSON; do
  if [[ -z "${!var:-}" ]]; then
    echo "Missing required GCP variable: ${var} (gcp.conf or control/secrets.env)" >&2
    exit 2
  fi
fi

mkdir -p "${ENV_DIR}"

cat > "${OUT_FILE}" <<EOF
{
  "project_id": "${GCP_PROJECT_ID}",
  "region": "${GCP_REGION}",
  "credentials_file": "${GCP_CREDENTIALS_JSON}"
}
EOF

echo "GCP Terraform env written to: ${OUT_FILE}"
