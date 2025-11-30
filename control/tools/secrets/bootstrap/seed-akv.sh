#!/usr/bin/env bash
set -Eeuo pipefail
: "${KV_NAME:?KV_NAME required}"
: "${SECRET_NAME:=jenkins-admin-password}"
: "${SECRET_VALUE:?SECRET_VALUE required}"
echo ">> Seeding secret '$SECRET_NAME' into Key Vault '$KV_NAME'"
az keyvault secret set --vault-name "$KV_NAME" --name "$SECRET_NAME" --value "$SECRET_VALUE" -o none
echo "OK"
