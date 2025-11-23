#!/usr/bin/env bash
set -euo pipefail

# Bootstrap Azure Key Vault + Service Principal and preload initial secrets.
# Usage:
#   AZ_SUBSCRIPTION_ID="<sub-id>" \
#   LOCATION="westeurope" \
#   RG="rg-hybridops" \
#   KV_NAME="kv-hybridops-$RANDOM" \
#   APP_NAME="sp-hybridops-ctrl01" \
#   JENKINS_ADMIN_PASS="${JENKINS_ADMIN_PASS:-}" \
#   bash bootstrap_akv_sp.sh
#
# Notes:
# - Requires: az CLI logged in with rights to create RG, KV, and an app registration.
# - Least-privilege: grants Key Vault Secrets User on the vault; Contributor on a future RG is optional.

: "${AZ_SUBSCRIPTION_ID:?Set AZ_SUBSCRIPTION_ID}"
: "${LOCATION:=westeurope}"
: "${RG:=rg-hybridops}"
: "${KV_NAME:?Set KV_NAME}"
: "${APP_NAME:=sp-hybridops-ctrl01}"

az account set --subscription "$AZ_SUBSCRIPTION_ID"

# Create resource group + Key Vault (RBAC-enabled recommended)
if ! az group show -n "$RG" >/dev/null 2>&1; then
  az group create -n "$RG" -l "$LOCATION" >/dev/null
fi

if ! az keyvault show -g "$RG" -n "$KV_NAME" >/dev/null 2>&1; then
  az keyvault create -g "$RG" -n "$KV_NAME" --location "$LOCATION" --enable-rbac-authorization true >/dev/null
fi

KV_ID=$(az keyvault show -g "$RG" -n "$KV_NAME" --query id -o tsv)
KV_URL=$(az keyvault show -g "$RG" -n "$KV_NAME" --query properties.vaultUri -o tsv)

# Create a Service Principal (App Registration) for pipelines (AKV access + future use)
SP_JSON=$(az ad sp create-for-rbac --name "$APP_NAME" --role "Reader" -o json)
APP_ID=$(echo "$SP_JSON" | jq -r .appId)
SP_SECRET=$(echo "$SP_JSON" | jq -r .password)
TENANT_ID=$(echo "$SP_JSON" | jq -r .tenant)

# Grant Key Vault Secrets User role at the vault scope (RBAC model)
az role assignment create --assignee "$APP_ID" --role "Key Vault Secrets User" --scope "$KV_ID" >/dev/null

# Prepare Jenkins admin pass (random if not provided)
if [[ -z "${JENKINS_ADMIN_PASS:-}" ]]; then
  JENKINS_ADMIN_PASS="$(tr -dc 'A-Za-z0-9!@#%^+=' </dev/urandom | head -c 24)"
fi

# Seed initial secrets
az keyvault secret set --vault-name "$KV_NAME" --name "JENKINS_ADMIN_PASSWORD" --value "$JENKINS_ADMIN_PASS" >/dev/null
az keyvault secret set --vault-name "$KV_NAME" --name "AZURE_CLIENT_ID"        --value "$APP_ID" >/dev/null
az keyvault secret set --vault-name "$KV_NAME" --name "AZURE_CLIENT_SECRET"    --value "$SP_SECRET" >/dev/null
az keyvault secret set --vault-name "$KV_NAME" --name "AZURE_TENANT_ID"        --value "$TENANT_ID" >/dev/null
az keyvault secret set --vault-name "$KV_NAME" --name "AZURE_SUBSCRIPTION_ID"  --value "$AZ_SUBSCRIPTION_ID" >/dev/null

# Emit a local .env (do not commit this file)
cat > bootstrap.env <<EOF
AZURE_KEYVAULT_URL=${KV_URL}
AZURE_SUBSCRIPTION_ID=${AZ_SUBSCRIPTION_ID}
AZURE_TENANT_ID=${TENANT_ID}
AZURE_CLIENT_ID=${APP_ID}
AZURE_CLIENT_SECRET=${SP_SECRET}
JENKINS_ADMIN_PASSWORD=${JENKINS_ADMIN_PASS}
EOF

echo "✅ AKV bootstrap complete."
echo "   Vault: ${KV_URL}"
echo "   SP:    ${APP_ID} (tenant ${TENANT_ID})"
echo "   Wrote: $(pwd)/bootstrap.env  (DO NOT COMMIT)"
