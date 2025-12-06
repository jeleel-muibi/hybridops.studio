#!/usr/bin/env bash
# init-proxmox-env.sh - Initialize Packer environment for Proxmox builds
# Maintainer: HybridOps.Studio
# Date: 2025-11-28

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
export REPO_ROOT

PACKER_ROOT="${REPO_ROOT}/control/tools/provision/packer"

BIN_DIR="${PACKER_ROOT}/bin"
REMOTE_SCRIPT="${PACKER_ROOT}/remote/init-packer-remote.sh"
CONF_FILE="${SCRIPT_DIR}/.conf/proxmox.conf"
SECRETS_FILE="${REPO_ROOT}/control/secrets.env"
ENV_OUT="${REPO_ROOT}/infra/env/.env.proxmox"
LOG_ROOT="${REPO_ROOT}/output/logs/packer/init"
PROOF_ROOT="${REPO_ROOT}/docs/proof/platform/packer-builds"
EVIDENCE_SCRIPT="${BIN_DIR}/evidence_packer.sh"

command -v ssh >/dev/null 2>&1 || { echo "ERR : ssh not found in PATH" >&2; exit 1; }
command -v scp >/dev/null 2>&1 || { echo "ERR : scp not found in PATH" >&2; exit 1; }

# shellcheck source=/dev/null
source "${BIN_DIR}/chain-lib.sh"

mkdir -p "${LOG_ROOT}"

TIMESTAMP="$(timestamp_utc)"
RUN_DIR="${LOG_ROOT}/${TIMESTAMP}"
mkdir -p "${RUN_DIR}"

LOG_FILE="${RUN_DIR}/init-packer.log"
export LOG_FILE
touch "${LOG_FILE}"

CHAIN_ID="$(load_chain_id "init")"
export CHAIN_ID
write_chain_marker "${CHAIN_ID}" "${LOG_FILE}"
echo "${CHAIN_ID}" > "${RUN_DIR}/chain.id"

log_info "init-proxmox-env started at ${TIMESTAMP}"

[[ -f "${CONF_FILE}" ]] || { log_error "Missing configuration: ${CONF_FILE}"; exit 1; }

# Non-secret wiring
# shellcheck source=/dev/null
source "${CONF_FILE}"

# Optional central secrets
if [[ -f "${SECRETS_FILE}" ]]; then
  # shellcheck source=/dev/null
  source "${SECRETS_FILE}"
fi

: "${PROXMOX_IP:?PROXMOX_IP is required in proxmox.conf}"
: "${USER_FQ:?USER_FQ is required in proxmox.conf}"

TOKEN_NAME="${TOKEN_NAME:-infra-token}"
FALLBACK_STORAGE_VM="${FALLBACK_STORAGE_VM:-local-lvm}"
FALLBACK_STORAGE_ISO="${FALLBACK_STORAGE_ISO:-local}"
FALLBACK_BRIDGE="${FALLBACK_BRIDGE:-vmbr0}"
HTTP_PORT="${HTTP_PORT:-8802}"
TLS_SKIP="${TLS_SKIP:-true}"

log_info "Proxmox IP=${PROXMOX_IP} user=${USER_FQ} token=${TOKEN_NAME}"

[[ -f "${REMOTE_SCRIPT}" ]] || { log_error "Remote bootstrap script not found: ${REMOTE_SCRIPT}"; exit 1; }

upsert_proxmox_secret() {
  local value="$1"
  mkdir -p "$(dirname "${SECRETS_FILE}")"
  if [[ -f "${SECRETS_FILE}" ]] && grep -q '^PROXMOX_TOKEN_SECRET=' "${SECRETS_FILE}"; then
    sed -i.bak 's|^PROXMOX_TOKEN_SECRET=.*|PROXMOX_TOKEN_SECRET="'"${value//|/\\|}"'"|' "${SECRETS_FILE}"
    rm -f "${SECRETS_FILE}.bak"
  else
    printf 'PROXMOX_TOKEN_SECRET="%s"\n' "${value}" >> "${SECRETS_FILE}"
  fi
}

log_info "Uploading remote bootstrap to ${PROXMOX_IP}"
if ! scp -q "${REMOTE_SCRIPT}" "root@${PROXMOX_IP}:/tmp/init-packer-remote.sh" 2>>"${LOG_FILE}"; then
  log_error "Failed to upload remote script via scp"
  exit 1
fi

SSH_ENV="USER_FQ='${USER_FQ}' TOKEN_NAME='${TOKEN_NAME}' FALLBACK_STORAGE_VM='${FALLBACK_STORAGE_VM}' FALLBACK_STORAGE_ISO='${FALLBACK_STORAGE_ISO}' FALLBACK_BRIDGE='${FALLBACK_BRIDGE}' TLS_SKIP='${TLS_SKIP}' HTTP_PORT='${HTTP_PORT}'"
if [[ -n "${PROXMOX_TOKEN_SECRET:-}" ]]; then
  log_info "PROXMOX_TOKEN_SECRET found in control/secrets.env; remote token generation will be skipped"
  SSH_ENV="SKIP_TOKEN_GEN=1 ${SSH_ENV}"
else
  log_info "PROXMOX_TOKEN_SECRET not set; remote will generate and return a token secret"
fi

log_info "Executing remote bootstrap"

ssh_output="$(
  ssh -o BatchMode=yes -o StrictHostKeyChecking=no \
    "root@${PROXMOX_IP}" \
    "${SSH_ENV} bash /tmp/init-packer-remote.sh" \
    2>&1
)"
SSH_EXIT=$?
if [[ ${SSH_EXIT} -ne 0 ]]; then
  printf '%s\n' "${ssh_output}" >> "${LOG_FILE}"
  log_error "Remote bootstrap execution failed with exit code ${SSH_EXIT}"
  exit 1
fi

REMOTE_EXPORTS=""
while IFS= read -r line; do
  if [[ "$line" == EXPORT:* ]]; then
    REMOTE_EXPORTS+="${line#EXPORT:}"$'\n'
  else
    echo "$line" >> "${LOG_FILE}"
  fi
done <<< "${ssh_output}"

TOKEN_SECRET=""
NODE_NAME=""
API_IP=""
STORAGE_VM=""
STORAGE_ISO=""
BRIDGE=""

while IFS='=' read -r k v; do
  case "${k}" in
    TOKEN_SECRET) TOKEN_SECRET="${v}" ;;
    NODE)         NODE_NAME="${v}" ;;
    IP)           API_IP="${v}" ;;
    STORAGE_VM)   STORAGE_VM="${v}" ;;
    STORAGE_ISO)  STORAGE_ISO="${v}" ;;
    BRIDGE)       BRIDGE="${v}" ;;
  esac
done <<< "${REMOTE_EXPORTS}"

if [[ -n "${PROXMOX_TOKEN_SECRET:-}" ]]; then
  TOKEN_SECRET="${PROXMOX_TOKEN_SECRET}"
elif [[ -n "${TOKEN_SECRET}" ]]; then
  log_info "Persisting newly generated PROXMOX_TOKEN_SECRET to control/secrets.env"
  upsert_proxmox_secret "${TOKEN_SECRET}"
  PROXMOX_TOKEN_SECRET="${TOKEN_SECRET}"
fi

if [[ -z "${NODE_NAME}" || -z "${API_IP}" ]]; then
  log_error "Remote bootstrap did not return required values (NODE/IP)"
  exit 1
fi

if [[ -z "${TOKEN_SECRET}" ]]; then
  log_error "No Proxmox token secret available (remote export and PROXMOX_TOKEN_SECRET are both empty)"
  exit 1
fi

[[ -z "${STORAGE_VM}" ]]  && STORAGE_VM="${FALLBACK_STORAGE_VM}"
[[ -z "${STORAGE_ISO}" ]] && STORAGE_ISO="${FALLBACK_STORAGE_ISO}"
[[ -z "${BRIDGE}" ]]      && BRIDGE="${FALLBACK_BRIDGE}"

log_info "Detecting workstation IP reachable from Proxmox"
WORKSTATION_IP="$(ip route get "${PROXMOX_IP}" 2>/dev/null | grep -oP 'src \K[\d.]+' || echo "")"

if [[ -z "${WORKSTATION_IP}" ]]; then
  log_warn "Could not detect workstation IP; using hostname resolution"
  WORKSTATION_IP="$(hostname -I | awk '{print $1}')"
fi

log_info "Workstation IP: ${WORKSTATION_IP}"

HTTP_BIND_ADDRESS="${WORKSTATION_IP}"

log_info "Configuration summary"
log_info "  NODE=${NODE_NAME}, API_IP=${API_IP}"
log_info "  STORAGE_VM=${STORAGE_VM}, STORAGE_ISO=${STORAGE_ISO}"
log_info "  BRIDGE=${BRIDGE}"
log_info "  HTTP_BIND=${HTTP_BIND_ADDRESS}:${HTTP_PORT}"

mkdir -p "$(dirname "${ENV_OUT}")"

cat > "${ENV_OUT}" <<EOF
# <sensitive> Do not commit.
# Generated by init-proxmox-env.sh at ${TIMESTAMP}

# Proxmox API
PROXMOX_URL="https://${API_IP}:8006/api2/json"
PROXMOX_TOKEN_ID="${USER_FQ}!${TOKEN_NAME}"
PROXMOX_TOKEN_SECRET="${TOKEN_SECRET}"
PROXMOX_NODE="${NODE_NAME}"
PROXMOX_SKIP_TLS_VERIFY="${TLS_SKIP}"

# Proxmox storage
PROXMOX_STORAGE_VM="${STORAGE_VM}"
PROXMOX_STORAGE_ISO="${STORAGE_ISO}"
PROXMOX_CLOUDINIT_STORAGE="${STORAGE_VM}"

# Network / build HTTP server
PROXMOX_BRIDGE="${BRIDGE}"
PACKER_HTTP_BIND_ADDRESS="${HTTP_BIND_ADDRESS}"
PACKER_HTTP_PORT="${HTTP_PORT}"

# To regenerate, run control/tools/provision/init/init-proxmox-env.sh
# or make init in infra/packer-multi-os
# </sensitive>
EOF

log_info "Validating rendered configuration"
missing=0
for key in \
  PROXMOX_URL \
  PROXMOX_TOKEN_ID \
  PROXMOX_TOKEN_SECRET \
  PROXMOX_NODE \
  PROXMOX_STORAGE_VM \
  PROXMOX_STORAGE_ISO \
  PROXMOX_BRIDGE \
  PACKER_HTTP_BIND_ADDRESS \
  PACKER_HTTP_PORT; do
  if ! grep -q "^${key}=" "${ENV_OUT}"; then
    log_warn "Missing expected variable: ${key}"
    missing=1
  fi
done

if [[ "${missing}" -ne 0 ]]; then
  log_warn "One or more expected variables were not rendered"
else
  log_info "Configuration validated successfully"
fi

rm -rf "${LOG_ROOT}/latest"
ln -s "$(basename "${RUN_DIR}")" "${LOG_ROOT}/latest"

if [[ -x "${EVIDENCE_SCRIPT}" ]]; then
  "${EVIDENCE_SCRIPT}" \
    --mode init \
    --log-file "${LOG_FILE}" \
    --env "${ENV_OUT}" \
    --out-root "${PROOF_ROOT}" >/dev/null 2>&1 || log_warn "Evidence generation failed"
fi

log_info "init-proxmox-env completed successfully"
echo
echo "Configuration: ${ENV_OUT}"
echo "Log:          ${LOG_FILE}"
exit 0
