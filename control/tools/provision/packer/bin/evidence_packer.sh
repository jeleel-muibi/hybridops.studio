#!/usr/bin/env bash
# evidence_packer.sh - Collect Packer init/build evidence for Proxmox templates
# Author: Jeleel Muibi | HybridOps.Studio
# Date: 2025-11-16

set -uo pipefail

usage() {
  cat <<'USAGE'
Usage:
  evidence_packer.sh --mode (init|build) --log-file FILE [--env FILE] [--template NAME] [--vmid N] [--out-root DIR]
USAGE
}

MODE=""
LOG_FILE=""
ENV_FILE=""
TEMPLATE=""
OUT_ROOT="docs/proof/platform/packer-builds"
VMID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="${2:-}"; shift 2;;
    --log-file) LOG_FILE="${2:-}"; shift 2;;
    --env) ENV_FILE="${2:-}"; shift 2;;
    --template) TEMPLATE="${2:-}"; shift 2;;
    --out-root) OUT_ROOT="${2:-}"; shift 2;;
    --vmid) VMID="${2:-}"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "ERR : Unknown arg: $1" >&2; usage; exit 2;;
  esac
done

[[ -n "${MODE}" && -n "${LOG_FILE}" ]] || { usage; exit 2; }
[[ -f "${LOG_FILE}" ]] || { echo "ERR : --log-file not found: ${LOG_FILE}" >&2; exit 2; }

timestamp_utc="$(date -u +'%Y-%m-%dT%H%M%SZ')"
host_short="$(hostname -s 2>/dev/null || hostname || echo 'unknown-host')"

redact_secret() {
  local s="${1:-}"
  [[ -z "${s}" ]] && { echo ""; return; }
  local len="${#s}"
  (( len <= 4 )) && { echo "****"; return; }
  printf "%s****" "${s:0:4}"
}

sha256sum_file() {
  local f="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$f" 2>/dev/null | awk '{print $1}' || echo "unknown"
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$f" 2>/dev/null | awk '{print $1}' || echo "unknown"
  else
    echo "unknown"
  fi
}

write_latest_symlink() {
  local from="$1" to="$2"
  mkdir -p "$(dirname "$to")" 2>/dev/null || true
  ln -sfn "$(basename "$from")" "$to" 2>/dev/null || true
}

safe_json_string() {
  local val="${1:-}"
  val="${val//\\/\\\\}"
  val="${val//\"/\\\"}"
  val="${val//$'\n'/\\n}"
  val="${val//$'\r'/\\r}"
  val="${val//$'\t'/\\t}"
  echo "${val}"
}

extract_json_field() {
  local json="$1" field="$2"
  echo "${json}" | grep -oE "\"${field}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -n1 | sed -E "s/.*\"${field}\"[[:space:]]*:[[:space:]]*\"([^\"]*)\".*/\1/" 2>/dev/null || echo ""
}

extract_json_number() {
  local json="$1" field="$2"
  echo "${json}" | grep -oE "\"${field}\"[[:space:]]*:[[:space:]]*(\")?[0-9]+(\")?[,}]" | grep -oE '[0-9]+' | head -n1 2>/dev/null || echo ""
}

proxmox_url=""
proxmox_node=""
token_id=""
token_secret_redacted=""

if [[ -n "${ENV_FILE}" && -f "${ENV_FILE}" ]]; then
  source "${ENV_FILE}" 2>/dev/null || true
  proxmox_url="${PKR_VAR_proxmox_url:-}"
  proxmox_node="${PKR_VAR_proxmox_node:-}"
  token_id="${PKR_VAR_proxmox_token_id:-}"
  token_secret_redacted="$(redact_secret "${PKR_VAR_proxmox_token_secret:-}")"
fi

mkdir -p "${OUT_ROOT}" || { echo "ERR : Cannot create ${OUT_ROOT}" >&2; exit 1; }

CHAIN_ID="${CHAIN_ID:-}"
[[ -z "${CHAIN_ID}" ]] && CHAIN_ID="$(grep -E '\[CHAIN\].*CHAIN_ID=' "${LOG_FILE}" 2>/dev/null | tail -n1 | sed -E 's/.*CHAIN_ID=([^ ]+).*/\1/' || echo "")"

status="unknown"
artifact_vmid=""

if grep -q 'Template.*PASSED' "${LOG_FILE}" 2>/dev/null; then
  status="success"
  artifact_vmid="$(grep -oE '(Testing template|Template) [0-9]+' "${LOG_FILE}" 2>/dev/null | grep -oE '[0-9]+' | head -n1 || echo "")"
elif grep -qE 'A template was created: [0-9]+' "${LOG_FILE}" 2>/dev/null; then
  status="success"
  artifact_vmid="$(grep -oE 'A template was created: [0-9]+' "${LOG_FILE}" 2>/dev/null | tail -n1 | awk '{print $5}' || echo "")"
elif grep -qE "Build '.*' errored|Some builds didn't complete successfully|^==>.*error:" "${LOG_FILE}" 2>/dev/null; then
  status="failed"
fi

[[ -z "${VMID}" && -n "${artifact_vmid}" ]] && VMID="${artifact_vmid}"

test_status="not_run"
test_guest_agent="unknown"
test_connectivity="unknown"
test_network="unknown"

if grep -q "Running post-build validation\|Testing template" "${LOG_FILE}" 2>/dev/null; then
  if grep -q "Template.*PASSED\|validation passed" "${LOG_FILE}" 2>/dev/null; then
    test_status="passed"
    grep -q "Agent responding" "${LOG_FILE}" 2>/dev/null && test_guest_agent="working"

    if grep -q "Agent responding" "${LOG_FILE}" 2>/dev/null; then
      test_connectivity="working"
    fi

    grep -qE "IP:.*[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" "${LOG_FILE}" 2>/dev/null && test_network="working"
  elif grep -q "Template.*FAILED\|validation failed" "${LOG_FILE}" 2>/dev/null; then
    test_status="failed"
  fi
fi

pve_name=""
pve_template_flag=""
pve_cores=""
pve_sockets=""
pve_scsi0=""
pve_cdrom=""
pve_net0=""
pve_memory=""
pve_ostype=""

enrich_proxmox() {
  [[ -n "${VMID}" && -n "${proxmox_url}" && -n "${proxmox_node}" && -n "${PKR_VAR_proxmox_token_id:-}" && -n "${PKR_VAR_proxmox_token_secret:-}" ]] || return 0

  command -v curl >/dev/null 2>&1 || return 0

  local AUTH="Authorization: PVEAPIToken=${PKR_VAR_proxmox_token_id}=${PKR_VAR_proxmox_token_secret}"
  local base="${proxmox_url}/nodes/${proxmox_node}/qemu/${VMID}"
  local curl_opts="-sf"
  [[ "${PKR_VAR_proxmox_skip_tls_verify:-true}" == "true" ]] && curl_opts="-k ${curl_opts}"

  curl ${curl_opts} -H "${AUTH}" "${base}/config" >/dev/null 2>&1 || return 0

  local cfg
  cfg="$(curl ${curl_opts} -H "${AUTH}" "${base}/config" 2>/dev/null || echo "")"
  [[ -z "${cfg}" ]] && return 0

  pve_name="$(extract_json_field "${cfg}" "name")"
  pve_template_flag="$(extract_json_number "${cfg}" "template")"
  pve_cores="$(extract_json_number "${cfg}" "cores")"
  pve_sockets="$(extract_json_number "${cfg}" "sockets")"
  pve_memory="$(extract_json_number "${cfg}" "memory")"
  pve_ostype="$(extract_json_field "${cfg}" "ostype")"
  pve_scsi0="$(extract_json_field "${cfg}" "scsi0")"
  pve_net0="$(extract_json_field "${cfg}" "net0")"

  pve_cdrom="$(echo "${cfg}" | grep -oE "\"ide[0-9]\"[[:space:]]*:[[:space:]]*\"[^\"]*cdrom[^\"]*\"" 2>/dev/null | head -n1 | sed -E 's/.*"ide[0-9]"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/' || echo "")"
  [[ -z "${pve_cdrom}" ]] && pve_cdrom="$(echo "${cfg}" | grep -oE "\"scsi[0-9]\"[[:space:]]*:[[:space:]]*\"[^\"]*cdrom[^\"]*\"" 2>/dev/null | head -n1 | sed -E 's/.*"scsi[0-9]"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/' || echo "")"
}

case "${MODE}" in
  init)
    proof_dir="${OUT_ROOT}/init/${timestamp_utc}"
    mkdir -p "${proof_dir}" || { echo "ERR : Cannot create ${proof_dir}" >&2; exit 1; }
    cp -f "${LOG_FILE}" "${proof_dir}/init-packer.log" || { echo "ERR : Cannot copy log file" >&2; exit 1; }

    packer_version="$(grep -m1 'Packer.*v[0-9]' "${LOG_FILE}" 2>/dev/null | sed -E 's/.*(Packer v[0-9][^ ]*).*/\1/' || echo "")"
    http_bind="$(grep -m1 'HTTP_BIND_ADDRESS=' "${LOG_FILE}" 2>/dev/null | awk -F'=' '{print $2}' | tr -d ' ' || echo "")"

    cat > "${proof_dir}/proof.json" <<'JSONEOF'
{
  "type": "init",
  "timestamp_utc": "TIMESTAMP_UTC_PLACEHOLDER",
  "host": "HOST_SHORT_PLACEHOLDER",
  "chain_id": "CHAIN_ID_PLACEHOLDER",
  "proxmox_url": "PROXMOX_URL_PLACEHOLDER",
  "proxmox_node": "PROXMOX_NODE_PLACEHOLDER",
  "packer_version": "PACKER_VERSION_PLACEHOLDER",
  "http_bind": "HTTP_BIND_PLACEHOLDER",
  "token_id": "TOKEN_ID_PLACEHOLDER",
  "token_secret_redacted": "TOKEN_SECRET_REDACTED_PLACEHOLDER",
  "log_file": "init-packer.log"
}
JSONEOF

    sed -i "s|TIMESTAMP_UTC_PLACEHOLDER|$(safe_json_string "${timestamp_utc}")|g" "${proof_dir}/proof.json"
    sed -i "s|HOST_SHORT_PLACEHOLDER|$(safe_json_string "${host_short}")|g" "${proof_dir}/proof.json"
    sed -i "s|CHAIN_ID_PLACEHOLDER|$(safe_json_string "${CHAIN_ID}")|g" "${proof_dir}/proof.json"
    sed -i "s|PROXMOX_URL_PLACEHOLDER|$(safe_json_string "${proxmox_url}")|g" "${proof_dir}/proof.json"
    sed -i "s|PROXMOX_NODE_PLACEHOLDER|$(safe_json_string "${proxmox_node}")|g" "${proof_dir}/proof.json"
    sed -i "s|PACKER_VERSION_PLACEHOLDER|$(safe_json_string "${packer_version}")|g" "${proof_dir}/proof.json"
    sed -i "s|HTTP_BIND_PLACEHOLDER|$(safe_json_string "${http_bind}")|g" "${proof_dir}/proof.json"
    sed -i "s|TOKEN_ID_PLACEHOLDER|$(safe_json_string "${token_id}")|g" "${proof_dir}/proof.json"
    sed -i "s|TOKEN_SECRET_REDACTED_PLACEHOLDER|$(safe_json_string "${token_secret_redacted}")|g" "${proof_dir}/proof.json"

    cat > "${proof_dir}/README.md" <<MDEOF
# Proof: Packer Init (Proxmox Bootstrap)

**Generated:** ${timestamp_utc}
**Host:** \`${host_short}\`

## Artifacts
- [\`init-packer.log\`](./init-packer.log) - Full initialization log
- [\`proof.json\`](./proof.json) - Machine-readable evidence
MDEOF

    write_latest_symlink "${proof_dir}" "${OUT_ROOT}/init/latest"
    echo "INFO: Init proof written → ${proof_dir}" >&2
    ;;

  build)
    [[ -n "${TEMPLATE}" ]] || { echo "ERR : --template required in build mode" >&2; exit 2; }

    if [[ "${status}" != "success" ]]; then
      echo "ERR : Build status='${status}' (not success); refusing to create proof." >&2
      exit 3
    fi

    proof_dir="${OUT_ROOT}/builds/${TEMPLATE}/${timestamp_utc}"
    mkdir -p "${proof_dir}" || { echo "ERR : Cannot create ${proof_dir}" >&2; exit 1; }
    cp -f "${LOG_FILE}" "${proof_dir}/packer.log" || { echo "ERR : Cannot copy log" >&2; exit 1; }
    echo "✓ Log copied" >&2

    enrich_proxmox
    echo "✓ Enrichment complete" >&2

    log_sha="$(sha256sum_file "${proof_dir}/packer.log")"
    log_bytes="$(wc -c < "${proof_dir}/packer.log" 2>/dev/null | tr -d ' ' || echo "0")"
    build_duration="$(grep -E "Build '.*' finished" "${LOG_FILE}" 2>/dev/null | grep -oE '[0-9]+ (minute|second)s? [0-9]+ (second|minute)s?' | head -n1 || echo "unknown")"
    echo "✓ Metadata calculated" >&2

    # Create JSON using sed replacement to avoid heredoc expansion issues
    cat > "${proof_dir}/proof.json" <<'JSONEOF'
{
  "type": "build",
  "timestamp_utc": "TIMESTAMP_UTC_PH",
  "host": "HOST_SHORT_PH",
  "chain_id": "CHAIN_ID_PH",
  "template": "TEMPLATE_PH",
  "vmid": "VMID_PH",
  "build_duration": "BUILD_DURATION_PH",
  "proxmox_url": "PROXMOX_URL_PH",
  "proxmox_node": "PROXMOX_NODE_PH",
  "vm_facts": {
    "name": "PVE_NAME_PH",
    "template_flag": "PVE_TEMPLATE_FLAG_PH",
    "cores": "PVE_CORES_PH",
    "sockets": "PVE_SOCKETS_PH",
    "memory_mb": "PVE_MEMORY_PH",
    "os_type": "PVE_OSTYPE_PH",
    "disk_scsi0": "PVE_SCSI0_PH",
    "cdrom": "PVE_CDROM_PH",
    "net0": "PVE_NET0_PH"
  },
  "validation_test": {
    "status": "TEST_STATUS_PH",
    "guest_agent": "TEST_GUEST_AGENT_PH",
    "connectivity": "TEST_CONNECTIVITY_PH",
    "network": "TEST_NETWORK_PH"
  },
  "log_file": "packer.log",
  "log_sha256": "LOG_SHA_PH",
  "log_bytes": LOG_BYTES_PH
}
JSONEOF

    sed -i "s|TIMESTAMP_UTC_PH|$(safe_json_string "${timestamp_utc}")|g" "${proof_dir}/proof.json"
    sed -i "s|HOST_SHORT_PH|$(safe_json_string "${host_short}")|g" "${proof_dir}/proof.json"
    sed -i "s|CHAIN_ID_PH|$(safe_json_string "${CHAIN_ID}")|g" "${proof_dir}/proof.json"
    sed -i "s|TEMPLATE_PH|$(safe_json_string "${TEMPLATE}")|g" "${proof_dir}/proof.json"
    sed -i "s|VMID_PH|$(safe_json_string "${VMID}")|g" "${proof_dir}/proof.json"
    sed -i "s|BUILD_DURATION_PH|$(safe_json_string "${build_duration}")|g" "${proof_dir}/proof.json"
    sed -i "s|PROXMOX_URL_PH|$(safe_json_string "${proxmox_url}")|g" "${proof_dir}/proof.json"
    sed -i "s|PROXMOX_NODE_PH|$(safe_json_string "${proxmox_node}")|g" "${proof_dir}/proof.json"
    sed -i "s|PVE_NAME_PH|$(safe_json_string "${pve_name:-unknown}")|g" "${proof_dir}/proof.json"
    sed -i "s|PVE_TEMPLATE_FLAG_PH|$(safe_json_string "${pve_template_flag:-unknown}")|g" "${proof_dir}/proof.json"
    sed -i "s|PVE_CORES_PH|$(safe_json_string "${pve_cores:-unknown}")|g" "${proof_dir}/proof.json"
    sed -i "s|PVE_SOCKETS_PH|$(safe_json_string "${pve_sockets:-unknown}")|g" "${proof_dir}/proof.json"
    sed -i "s|PVE_MEMORY_PH|$(safe_json_string "${pve_memory:-unknown}")|g" "${proof_dir}/proof.json"
    sed -i "s|PVE_OSTYPE_PH|$(safe_json_string "${pve_ostype:-unknown}")|g" "${proof_dir}/proof.json"
    sed -i "s|PVE_SCSI0_PH|$(safe_json_string "${pve_scsi0:-unknown}")|g" "${proof_dir}/proof.json"
    sed -i "s|PVE_CDROM_PH|$(safe_json_string "${pve_cdrom:-none}")|g" "${proof_dir}/proof.json"
    sed -i "s|PVE_NET0_PH|$(safe_json_string "${pve_net0:-unknown}")|g" "${proof_dir}/proof.json"
    sed -i "s|TEST_STATUS_PH|$(safe_json_string "${test_status}")|g" "${proof_dir}/proof.json"
    sed -i "s|TEST_GUEST_AGENT_PH|$(safe_json_string "${test_guest_agent}")|g" "${proof_dir}/proof.json"
    sed -i "s|TEST_CONNECTIVITY_PH|$(safe_json_string "${test_connectivity}")|g" "${proof_dir}/proof.json"
    sed -i "s|TEST_NETWORK_PH|$(safe_json_string "${test_network}")|g" "${proof_dir}/proof.json"
    sed -i "s|LOG_SHA_PH|$(safe_json_string "${log_sha}")|g" "${proof_dir}/proof.json"
    sed -i "s|LOG_BYTES_PH|${log_bytes:-0}|g" "${proof_dir}/proof.json"

    echo "✓ proof.json created" >&2

    cat > "${proof_dir}/README.md" <<MDEOF
# Proof: Packer Build — ${TEMPLATE}

**Generated:** ${timestamp_utc}
**Status:** SUCCESS
**VMID:** ${VMID}
**Build Duration:** ${build_duration}

## VM Configuration

| Property | Value |
|----------|-------|
| Name | \`${pve_name:-n/a}\` |
| OS Type | \`${pve_ostype:-n/a}\` |
| CPU | ${pve_sockets:-?} socket(s) × ${pve_cores:-?} core(s) |
| Memory | ${pve_memory:-n/a} MB |
| Disk (scsi0) | \`${pve_scsi0:-n/a}\` |
| Network (net0) | \`${pve_net0:-n/a}\` |
| Template Flag | ${pve_template_flag:-n/a} |

## Post-Build Validation

**Status:** ${test_status}

| Test | Status |
|------|--------|
| Guest Agent | ${test_guest_agent} |
| Connectivity | ${test_connectivity} |
| Network | ${test_network} |

## Artifacts

- [\`packer.log\`](./packer.log) - Full build log
  - **SHA256:** \`${log_sha}\`
  - **Size:** ${log_bytes} bytes
- [\`proof.json\`](./proof.json) - Machine-readable evidence

---

_Infrastructure Maintainer: Jeleel Muibi | HybridOps.Studio_
_Evidence Generated: ${timestamp_utc}_
MDEOF

    echo "✓ README.md created" >&2

    write_latest_symlink "${proof_dir}" "${OUT_ROOT}/builds/${TEMPLATE}/latest"
    echo "✓ Symlink created" >&2

    echo "INFO: Build proof → ${proof_dir}" >&2
    ;;

  *)
    echo "ERR : Unknown --mode '${MODE}'" >&2
    exit 2
    ;;
esac
