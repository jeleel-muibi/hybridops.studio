#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROOF_DIR="${ROOT_DIR}/docs/proof"

ENV="${ENV:-dev}"
CLOUD="${CLOUD:-onprem}"
STACK="${STACK:-20-workloads/ctrl01}"

mkdir -p "${PROOF_DIR}/${ENV}/${CLOUD}/${STACK}"
OUT_MD="${PROOF_DIR}/${ENV}/${CLOUD}/${STACK}/evidence.md"
OUT_JSON="${PROOF_DIR}/${ENV}/${CLOUD}/${STACK}/evidence.json"

redact() { sed -E 's/([A-Za-z0-9/+]{16,})/[REDACTED]/g'; }

section() { echo -e "\n## $1\n" >> "$OUT_MD"; }

write_tf_state_meta() {
  section "Terraform State (Metadata)"
  cat > "${PROOF_DIR}/${ENV}/${CLOUD}/${STACK}/state.md" <<EOF
- Backend: Terraform Cloud
- Workspace: ${WORKSPACE_NAME:-unknown}
- Commit: ${GIT_COMMIT:-unknown}
- Actor: ${BUILD_USER:-jenkins}
- Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
  cat "${PROOF_DIR}/${ENV}/${CLOUD}/${STACK}/state.md" >> "$OUT_MD"
}

write_plan_sha() {
  section "Plan Artifact"
  if [[ -f "plan.out" ]]; then
    sha256sum plan.out > "${PROOF_DIR}/${ENV}/${CLOUD}/${STACK}/plan.sha256"
    echo "- plan.out sha256:" >> "$OUT_MD"
    cat "${PROOF_DIR}/${ENV}/${CLOUD}/${STACK}/plan.sha256" >> "$OUT_MD"
  else
    echo "No plan.out found in CWD; run 'make plan' before evidence collection" >> "$OUT_MD"
  fi
}

write_kv_azure() {
  local sub="${SUBSCRIPTION_ID:-}"
  local rg="${RG:-}"
  local kv="${KV_NAME:-}"
  if ! command -v az >/dev/null 2>&1; then
    echo "az not found; skipping AKV section" >&2
    return 0
  fi
  section "Azure Key Vault"
  {
    echo "- Subscription: ${sub}"
    echo "- Resource Group: ${rg}"
    echo "- Key Vault: ${kv}"
    echo ""
    echo "### Vault Properties"
    az keyvault show -n "$kv" -g "$rg" -o json | jq '{name, location, properties: { enableSoftDelete: .properties.enableSoftDelete, enablePurgeProtection: .properties.enablePurgeProtection, enableRbacAuthorization: .properties.enableRbacAuthorization, sku: .properties.sku.name, privateEndpointConnections: (.properties.privateEndpointConnections|length) }}'
    echo ""
    echo "### RBAC Role Assignments (scope = vault)"
    az role assignment list --scope "$(az keyvault show -n "$kv" -g "$rg" --query id -o tsv)" -o table | redact
  } >> "$OUT_MD"
}

check_gcp_to_akv() {
  local url="${AKV_URL:-}"
  if [[ -z "$url" ]]; then
    echo "AKV_URL not set; skipping GCP→AKV connectivity checks" >> "$OUT_MD"
    return 0
  fi
  section "GCP → AKV Connectivity (non-invasive)"
  {
    echo "- Target: ${url}"
    # Resolve host
    host="$(echo "$url" | sed -E 's#https?://([^/]+)/?.*#\1#')"
    echo "### DNS Resolution"
    if command -v getent >/dev/null 2>&1; then
      getent ahosts "$host" || true
    else
      nslookup "$host" || true
    fi

    echo ""
    echo "### curl HTTPS probe (5s timeout)"
    if command -v curl >/dev/null 2>&1; then
      curl -sS -m 5 -o /dev/null -w "http_code=%{http_code}\nremote_ip=%{remote_ip}\nremote_port=%{remote_port}\nssl_verify=%{ssl_verify_result}\ntime_total=%{time_total}\n" "$url" || true
    else
      echo "curl not found"
    fi

    echo ""
    echo "### TLS handshake (openssl s_client)"
    if command -v openssl >/dev/null 2>&1; then
      echo | openssl s_client -connect "${host}:443" -servername "$host" -brief -tls1_2 2>/dev/null | sed -E 's/(issuer=.*|subject=.*)/[REDACTED]/g' || true
    else
      echo "openssl not found"
    fi
  } >> "$OUT_MD"
}

write_summary_json() {
  jq -n --arg env "$ENV" --arg cloud "$CLOUD" --arg stack "$STACK" \
    --arg workspace "${WORKSPACE_NAME:-unknown}" \
    --arg commit "${GIT_COMMIT:-unknown}" \
    --arg time "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    '{env:$env, cloud:$cloud, stack:$stack, workspace:$workspace, commit:$commit, collected_at:$time}' \
    > "$OUT_JSON"
}

main() {
  : > "$OUT_MD"
  echo "# Evidence: ${ENV}/${CLOUD}/${STACK}" >> "$OUT_MD"
  write_tf_state_meta
  write_plan_sha

  case "${CLOUD}" in
    azure) write_kv_azure ;;
    gcp)   check_gcp_to_akv ;;
    *)     : ;;
  esac

  write_summary_json
  echo "Wrote: $OUT_MD"
  echo "Wrote: $OUT_JSON"
}
main "$@"
