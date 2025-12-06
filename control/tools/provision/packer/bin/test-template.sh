#!/usr/bin/env bash
# test-template.sh - Validate Proxmox VM template functionality (flash test)
# Maintainer: HybridOps.Studio
# Date: 2025-11-16

set -euo pipefail

TEMPLATE_ID="${1:-}"
TEST_VM_ID_MIN=999
TEST_VM_ID_MAX=1111
AGENT_TIMEOUT=300

if [[ -z "${TEMPLATE_ID}" ]]; then
  echo "Usage: $0 <template-vmid>" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../.." && pwd)"
ENV_FILE="${REPO_ROOT}/infra/env/.env.proxmox"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "✗ .env not found: ${ENV_FILE}" >&2
  exit 1
fi
# shellcheck disable=SC1090
source "${ENV_FILE}"

PROXMOX_HOST=$(echo "${PROXMOX_URL}" | sed -E 's|https?://([^:/]+).*|\1|')

find_available_vmid() {
  local candidate=$((TEST_VM_ID_MIN + RANDOM % (TEST_VM_ID_MAX - TEST_VM_ID_MIN + 1)))
  local attempts=0
  local max_attempts=$((TEST_VM_ID_MAX - TEST_VM_ID_MIN + 1))

  while (( attempts < max_attempts )); do
    local status
    status=$(ssh "root@${PROXMOX_HOST}" "qm status ${candidate} 2>&1" || true)

    if echo "${status}" | grep -qE "Configuration file.*does not exist|does not exist"; then
      echo "${candidate}"
      return 0
    fi

    candidate=$(( (candidate - TEST_VM_ID_MIN + 1) % (TEST_VM_ID_MAX - TEST_VM_ID_MIN + 1) + TEST_VM_ID_MIN ))
    ((attempts++))
  done

  echo "✗ Could not find available VMID in range ${TEST_VM_ID_MIN}-${TEST_VM_ID_MAX}" >&2
  exit 1
}

TEST_VM_ID=$(find_available_vmid)
echo "Selected test VMID: ${TEST_VM_ID}"

cleanup() {
  local vm_status
  vm_status=$(ssh "root@${PROXMOX_HOST}" "qm status ${TEST_VM_ID} 2>&1" || true)
  if echo "${vm_status}" | grep -qE "running|stopped"; then
    ssh "root@${PROXMOX_HOST}" "qm stop ${TEST_VM_ID} 2>/dev/null || true" >/dev/null
    sleep 2
    ssh "root@${PROXMOX_HOST}" "qm destroy ${TEST_VM_ID} --purge 2>/dev/null || true" >/dev/null
  fi
}
trap cleanup EXIT INT TERM

echo "Testing template ${TEMPLATE_ID}..."
echo ""

echo "1. Cleanup..."
cleanup

TEMPLATE_CONFIG=$(ssh "root@${PROXMOX_HOST}" "qm config ${TEMPLATE_ID}")
if echo "${TEMPLATE_CONFIG}" | grep -qi "windows"; then
  OS_FAMILY="windows"
  AGENT_TIMEOUT=$((AGENT_TIMEOUT * 2))
else
  OS_FAMILY="linux"
fi

VM_NAME="${OS_FAMILY}-templatetest"
echo "Detected OS family: ${OS_FAMILY} (timeout ${AGENT_TIMEOUT}s)"
echo "VM name will be: ${VM_NAME}"

echo "2. Cloning..."
ssh "root@${PROXMOX_HOST}" \
  "qm clone ${TEMPLATE_ID} ${TEST_VM_ID} --name ${VM_NAME} --full" | tail -1

echo "3. Configuring cloud-init..."
ssh "root@${PROXMOX_HOST}" \
  "set +H; qm set ${TEST_VM_ID} --ciuser hybridops --cipassword Temporary\\! --ipconfig0 ip=dhcp --agent enabled=1" | head -1

for i in {1..10}; do
  if ssh "root@${PROXMOX_HOST}" "lvs | grep -q vm-${TEST_VM_ID}-cloudinit"; then
    echo "   ✓ Cloud-init ISO attached"
    break
  fi
  sleep 1
done

echo "4. Starting VM..."
ssh "root@${PROXMOX_HOST}" "qm start ${TEST_VM_ID}" >/dev/null

echo "5. Waiting for guest agent (max ${AGENT_TIMEOUT}s)..."
ELAPSED=0
IP=""
while (( ELAPSED < AGENT_TIMEOUT )); do
  IP=$(ssh "root@${PROXMOX_HOST}" \
       "qm agent ${TEST_VM_ID} network-get-interfaces 2>/dev/null" | \
       grep -oP '(?<=\"ip-address\" : \")[^\"]+' | grep -v "127.0.0.1" | grep -v "::" | head -1 || true)
  if [[ -n "${IP}" ]]; then
    echo "   ✓ Agent responding after ${ELAPSED}s"
    break
  fi
  (( ELAPSED % 30 == 0 )) && (( ELAPSED > 0 )) && echo "   ... waiting ($ELAPSED s)"
  sleep 5
  ((ELAPSED+=5))
done

if [[ -z "${IP}" ]]; then
  echo "   ✗ Agent timeout after ${AGENT_TIMEOUT}s" >&2
  exit 1
fi

echo "6. Network info..."
OS=$(ssh "root@${PROXMOX_HOST}" "qm agent ${TEST_VM_ID} get-osinfo 2>/dev/null" | \
     grep -oP '(?<=\"pretty-name\" : \")[^\"]+' | head -1 || echo "Unknown")

echo "   ✓ VM Name: ${VM_NAME}"
echo "   ✓ IP:      ${IP}"
echo "   ✓ OS:      ${OS:-Unknown}"
echo ""
echo "✓ Template ${TEMPLATE_ID} PASSED"
exit 0
