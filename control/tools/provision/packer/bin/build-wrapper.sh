#!/usr/bin/env bash
# build-wrapper.sh - Orchestrate Packer template builds with logging and evidence
# Maintainer: HybridOps.Studio
# Created: 2025-11-17

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  build-wrapper.sh --dir DIR --key KEY --hint-target TARGET --default-vmid N [--env FILE]
USAGE
}

info() { printf "INFO: %s\n" "$*"; }
warn() { printf "WARN: %s\n" "$*" >&2; }
fail() { printf "ERR : %s\n" "$1" >&2; exit "${2:-1}"; }

DIR=""
KEY=""
HINT_TARGET=""
DEFAULT_VMID=""
ENV_FILE_OVERRIDE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)           DIR="${2:-}"; shift 2;;
    --key)           KEY="${2:-}"; shift 2;;
    --hint-target)   HINT_TARGET="${2:-}"; shift 2;;
    --default-vmid)  DEFAULT_VMID="${2:-}"; shift 2;;
    --env)           ENV_FILE_OVERRIDE="${2:-}"; shift 2;;
    --auto-vmid)     shift;;
    -h|--help)       usage; exit 0;;
    *) fail "unknown arg: $1" 2;;
  esac
done

[[ -n "${DIR}" && -n "${KEY}" && -n "${HINT_TARGET}" && -n "${DEFAULT_VMID}" ]] || fail "missing required arguments" 2

command -v packer >/dev/null 2>&1 || fail "packer binary not found in PATH" 1

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if git -C "${SCRIPT_DIR}" rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git -C "${SCRIPT_DIR}" rev-parse --show-toplevel)"
else
  REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
fi
export REPO_ROOT

CHAIN_LIB="${SCRIPT_DIR}/chain-lib.sh"
if [[ -f "${CHAIN_LIB}" ]]; then
  # shellcheck source=/dev/null
  source "${CHAIN_LIB}"
fi

INFRA_DIR="${REPO_ROOT}/infra/packer-multi-os"
OUTPUT_ROOT="${REPO_ROOT}/output/logs/packer/builds/${KEY}"
PROOF_ROOT="${REPO_ROOT}/docs/proof/platform/packer-builds"
EVIDENCE_SCRIPT="${SCRIPT_DIR}/evidence_packer.sh"
TEST_SCRIPT="${SCRIPT_DIR}/test-template.sh"

cd "${INFRA_DIR}"

ENV_FILE="${ENV_FILE_OVERRIDE:-${REPO_ROOT}/infra/env/.env.proxmox}"
[[ -f "${ENV_FILE}" ]] || fail ".env not found: ${ENV_FILE}. Run init first." 2

[[ -d "${DIR}" ]] || fail "template dir not found: ${DIR}" 2

shopt -s nullglob
HCL_MATCH=( "${DIR}"/*.pkr.hcl )
shopt -u nullglob
[[ ${#HCL_MATCH[@]} -gt 0 ]] || fail "no *.pkr.hcl in ${DIR}" 2

VARFILE="${DIR}/${KEY}.pkrvars.hcl"
[[ -f "${VARFILE}" ]] || fail "var-file not found: ${VARFILE}" 2

TS="$(date -u +'%Y-%m-%dT%H%M%SZ')"
LOG_DIR="${OUTPUT_ROOT}/${TS}"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/packer.log"
( cd "${OUTPUT_ROOT}" && ln -sfn "${TS}" latest )

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

if [[ -n "${CHAIN_ID:-}" ]]; then
  info "Using chain ID: ${CHAIN_ID}"
else
  if declare -F load_chain_id >/dev/null 2>&1; then
    CHAIN_ID="$(load_chain_id "${KEY}")"
    export CHAIN_ID
  fi
fi

if [[ -n "${CHAIN_ID:-}" ]]; then
  write_chain_marker "${CHAIN_ID}" "${LOG_FILE}"
  echo "${CHAIN_ID}" > "${LOG_DIR}/chain.id"
fi

info "Build log → ${LOG_FILE}"

VMID_EFF="${VMID:-${DEFAULT_VMID}}"

AUTH="PVEAPIToken=${PROXMOX_TOKEN_ID}=${PROXMOX_TOKEN_SECRET}"
NODE="${PROXMOX_NODE}"
API_URL="${PROXMOX_URL}/nodes/${NODE}/qemu"

CURL_OPTS="-sf"
[[ "${PROXMOX_SKIP_TLS_VERIFY:-true}" == "true" ]] && CURL_OPTS="${CURL_OPTS} -k"

API_RESPONSE="$(curl ${CURL_OPTS} -H "Authorization: ${AUTH}" "${API_URL}" 2>/dev/null || echo '{"data":[]}')"

EXISTING=$(echo "${API_RESPONSE}" | grep -oE '"vmid":[0-9]+' | awk -F: '{print $2}' | sort -n | tr '\n' ' ' || echo "")

in_use() {
  local check_vmid="$1"
  echo "${EXISTING}" | grep -qw "${check_vmid}"
}

if in_use "${VMID_EFF}"; then
  ORIGINAL_VMID="${VMID_EFF}"
  info "VMID ${VMID_EFF} already in use, finding next available..."

  while in_use "${VMID_EFF}"; do
    VMID_EFF="$(( VMID_EFF + 1 ))"
    [[ "${VMID_EFF}" -lt "$(( ORIGINAL_VMID + 100 ))" ]] || fail "could not find available VMID after 100 attempts" 3
  done

  info "Using VMID ${VMID_EFF} instead"
else
  info "Using VMID ${VMID_EFF}"
fi

export PKR_VAR_vmid="${VMID_EFF}"

BUILD_ONLY=""
if [[ "${DIR}" =~ (linux|ubuntu|rocky|debian|almalinux|alpine) ]]; then
  BUILD_ONLY="-only=linux.proxmox-iso.vm"
elif [[ "${DIR}" =~ (windows|win) ]]; then
  BUILD_ONLY="-only=windows.proxmox-iso.vm"
fi

{
  cd "${DIR}"

  info "Initializing Packer plugins..."    | tee -a "${LOG_FILE}"
  packer init .                           >> "${LOG_FILE}" 2>&1

  info "Validating Packer configuration..." | tee -a "${LOG_FILE}"
  packer validate \
    -var "vmid=${VMID_EFF}" \
    -var-file="${KEY}.pkrvars.hcl" \
    .                                     >> "${LOG_FILE}" 2>&1

  info "Starting Packer build with VMID ${VMID_EFF}..." | tee -a "${LOG_FILE}"
  PACKER_LOG=1 packer build \
    -color=false \
    -var "vmid=${VMID_EFF}" \
    -var-file="${KEY}.pkrvars.hcl" \
    ${BUILD_ONLY} \
    .                                     >> "${LOG_FILE}" 2>&1
} || {
  fail "Build failed - check log: ${LOG_FILE}" 1
}

info "Build completed successfully"

if [[ -f "${TEST_SCRIPT}" ]]; then
  chmod +x "${TEST_SCRIPT}"
  info "Running post-build validation..."
  if "${TEST_SCRIPT}" "${VMID_EFF}" 2>&1 | tee -a "${LOG_FILE}"; then
    info "Template validation passed"
  else
    warn "Template validation failed (template created but not fully tested)"
  fi
else
  warn "test-template.sh not found, skipping validation"
fi

if [[ -x "${EVIDENCE_SCRIPT}" ]]; then
  info "Generating evidence..."
  if "${EVIDENCE_SCRIPT}" \
    --mode build \
    --template "${KEY}" \
    --log-file "${LOG_FILE}" \
    --env "${ENV_FILE}" \
    --out-root "${PROOF_ROOT}" 2>&1 | tee -a "${LOG_FILE}"; then
    info "Evidence generated successfully"
  else
    warn "Evidence generation failed (see log for details)"
  fi
fi

echo
info "✓ Build finished successfully"
info "  Template VMID: ${VMID_EFF}"
info "  Build log: ${LOG_FILE}"
exit 0
