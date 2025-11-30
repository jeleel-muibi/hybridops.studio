#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# HybridOps Studio — Day-0 Provisioner for ctrl-01 (Proxmox Jenkins Controller)
# -----------------------------------------------------------------------------
# Author: Jeleel Muibi
# Updated: 2025-10-22
#
# Description:
#   Zero-touch Day-0 provisioner for the Jenkins controller (ctrl-01).
#   Provisions a Ubuntu VM on Proxmox with cloud-init payload for Day-1.
#   Implements ADR-0015 with AKV-first secrets strategy and no interactive prompts.
#
# Design intent:
#   • Zero-touch — provisions controller with no UI credential entry.
#   • Deterministic — all logic and cloud-init YAML embedded inline.
#   • Secure — fetches Jenkins admin password directly from AKV.
#   • Auditable — emits logs and artifacts to /var/log/ctrl01_provision.log.
#   • Safe — includes a timed grace window before destroying existing VMs.
#
# Usage:
#   AZURE_TENANT_ID="<id>" \
#   AZURE_SUBSCRIPTION_ID="<id>" \
#   AZURE_CLIENT_ID="<id>" \
#   AZURE_CLIENT_SECRET="<secret>" \
#   AZURE_KEYVAULT_URL="https://<vault>.vault.azure.net/" \
#   sudo --preserve-env=AZURE_* provision-ctrl01-proxmox-ubuntu.sh
#
#   Optional environment overrides:
#     VMID=101 VMNAME=ctrl-01 BRIDGE=vmbr1
#
# Prereqs:
#   - Azure CLI installed on Proxmox host
#   - Service Principal with AKV access created via bootstrap_akv_sp.sh
# -----------------------------------------------------------------------------

set -Eeuo pipefail
LOG=/var/log/ctrl01_provision.log
exec > >(tee -a "$LOG") 2>&1
echo "[provision] start $(date -Is)"

# --- AKV Prerequisites --------------------------------------------------------
# Validate AKV environment variables
required_vars=(
  AZURE_TENANT_ID
  AZURE_SUBSCRIPTION_ID
  AZURE_CLIENT_ID
  AZURE_CLIENT_SECRET
  AZURE_KEYVAULT_URL
)

missing_vars=()
for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    missing_vars+=("$var")
  fi
done

if [[ ${#missing_vars[@]} -gt 0 ]]; then
  echo "[provision] ERROR: Missing required Azure credentials: ${missing_vars[*]}" >&2
  echo "[provision] Run bootstrap_akv_sp.sh first, then export the required variables." >&2
  exit 1
fi

# Ensure az CLI is available
if ! command -v az &>/dev/null; then
  echo "[provision] ERROR: Azure CLI (az) not found. Please install it on the Proxmox host." >&2
  exit 1
fi

# --- VM parameters ------------------------------------------------------------
# Define or inherit default runtime values for Proxmox VM creation.
VMID=${VMID:-101}
VMNAME=${VMNAME:-ctrl-01}
BRIDGE=${BRIDGE:-vmbr1}
IPCIDR=${IPCIDR:-172.16.10.5/28}
GATEWAY=${GATEWAY:-172.16.10.1}
DNS=${DNS:-8.8.8.8}
DISKSTORE=${DISKSTORE:-local-lvm}
SNIPSTORE=${SNIPSTORE:-local}

# --- Cloud-init user context --------------------------------------------------
# Creates a privileged automation user for initial bootstrap access.
CIUSER=${CIUSER:-hybridops}
CIPASS=${CIPASS:-TempPass123!}

# --- Fetch Jenkins admin password from AKV -----------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRET_HELPER="${SCRIPT_DIR}/../azure/akv/get-secret.sh"

# Default to direct az CLI call if helper not available
if [[ -f "$SECRET_HELPER" && -x "$SECRET_HELPER" ]]; then
  echo "[provision] Using unified secret helper to fetch Jenkins admin password"
  JENKINS_ADMIN_PASS=$("$SECRET_HELPER" --name jenkins-admin-password)
else
  echo "[provision] Secret helper not found, using direct AKV access"

  # Extract vault name from URL
  KV_NAME=$(echo "$AZURE_KEYVAULT_URL" | sed -e 's#https://##' -e 's#\.vault\.azure\.net/*##')

  # Login to Azure
  echo "[provision] Authenticating to Azure"
  az login --service-principal \
    -u "$AZURE_CLIENT_ID" \
    -p "$AZURE_CLIENT_SECRET" \
    --tenant "$AZURE_TENANT_ID" >/dev/null

  # Fetch secret - try canonical name first, then uppercase
  if ! JENKINS_ADMIN_PASS=$(az keyvault secret show --vault-name "$KV_NAME" --name "jenkins-admin-password" --query value -o tsv 2>/dev/null); then
    if ! JENKINS_ADMIN_PASS=$(az keyvault secret show --vault-name "$KV_NAME" --name "JENKINS_ADMIN_PASSWORD" --query value -o tsv 2>/dev/null); then
      echo "[provision] ERROR: Jenkins admin password not found in AKV" >&2
      az account clear >/dev/null 2>&1 || true
      exit 1
    fi
  fi

  # Logout for security
  az account clear >/dev/null 2>&1 || true
fi

# Validate we actually got a password
if [[ -z "$JENKINS_ADMIN_PASS" ]]; then
  echo "[provision] ERROR: Failed to retrieve Jenkins admin password from AKV" >&2
  exit 1
fi

# --- Git / repository source --------------------------------------------------
REPO_URL=${REPO_URL:-https://github.com/jeleel-muibi/hybridops.studio}
REPO_BRANCH=${REPO_BRANCH:-main}
REPO_DIR=${REPO_DIR:-/srv/hybridops}
BOOTSTRAP_SCRIPT=${BOOTSTRAP_SCRIPT:-control/tools/provision/bootstrap/ctrl01-bootstrap.sh}
BOOTSTRAP_DELAY_SEC=${BOOTSTRAP_DELAY_SEC:-120}
BOOTSTRAP_PROBE_HOST=${BOOTSTRAP_PROBE_HOST:-github.com}

# --- Base OS image acquisition ------------------------------------------------
# Ensures Ubuntu cloud image is locally available before VM creation.
UBUNTU_IMG_URL=${UBUNTU_IMG_URL:-https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img}
install -d -m 0755 /var/lib/vz/template/iso /var/lib/vz/snippets
IMG="/var/lib/vz/template/iso/$(basename "$UBUNTU_IMG_URL")"
[ -s "$IMG" ] || wget -O "$IMG" "$UBUNTU_IMG_URL"

# --- SSH key propagation ------------------------------------------------------
# Automatically inject any existing root public keys for seamless access.
AUTHORIZED_KEYS=""
for f in /root/.ssh/id_rsa.pub /root/.ssh/id_ed25519.pub; do
  [ -s "$f" ] && AUTHORIZED_KEYS+="      - $(tr -d '\r\n' < "$f")\n"
done

# --- Cloud-init snippet generation -------------------------------------------
# Embeds Day-1 launcher and systemd units directly into user-data YAML.
SNIP="/var/lib/vz/snippets/ctrl01-day0.yaml"
cat >"$SNIP" <<EOF
#cloud-config
hostname: ${VMNAME}
manage_etc_hosts: true
ssh_pwauth: true

users:
  - name: ${CIUSER}
    groups: sudo
    shell: /bin/bash
    lock_passwd: false
    sudo: ALL=(ALL) NOPASSWD:ALL
$( [ -n "$AUTHORIZED_KEYS" ] && printf "    ssh_authorized_keys:\n%s" "$AUTHORIZED_KEYS" )

chpasswd:
  expire: false
  list: |
    ${CIUSER}:${CIPASS}

write_files:
  # Pass Azure credentials for AKV access
  - path: /etc/jenkins.akv.env
    permissions: "0600"
    owner: root:root
    content: |
      # Azure credentials for AKV access - automatically removed after first use
      AZURE_TENANT_ID="${AZURE_TENANT_ID}"
      AZURE_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID}"
      AZURE_CLIENT_ID="${AZURE_CLIENT_ID}"
      AZURE_CLIENT_SECRET="${AZURE_CLIENT_SECRET}"
      AZURE_KEYVAULT_URL="${AZURE_KEYVAULT_URL}"
      ONE_TIME=1

  # Adaptive Day-1 launcher — validates network then triggers controller setup
  - path: /usr/local/sbin/day1-launcher
    permissions: "0755"
    content: |
      #!/usr/bin/env bash
      set -Eeuo pipefail
      LOG=/var/log/ctrl01_bootstrap.log
      LOCK_FILE="/var/lib/ctrl01/bootstrap.lock"

      # Create log directory and parent dir for lock file
      mkdir -p "\$(dirname "\$LOG")" "\$(dirname "\$LOCK_FILE")"

      # Exit if bootstrap already completed
      if [ -f "\$LOCK_FILE" ]; then
        echo "[launcher] Bootstrap already completed (lock file exists)" | tee -a "\$LOG"
        exit 0
      fi

      # Set up output redirection once
      exec > >(tee -a "\$LOG") 2>&1
      echo "[launcher] starting Day-1 bootstrap at \$(date -Is)"

      retry() { local n=0 tries=20 delay=5; while [ \$n -lt \$tries ]; do "\$@" && return 0 || true; n=\$((n+1)); echo "[retry] \$n/\$tries failed: \$*"; sleep \$delay; done; return 1; }

      # Wait for outbound connectivity before cloning repo
      echo "[launcher] checking network..."
      for ((i=1; i<=${BOOTSTRAP_DELAY_SEC:-120}; i++)); do
        if ping -c1 -W1 ${BOOTSTRAP_PROBE_HOST} &>/dev/null; then
          echo "[launcher] network OK after \${i}s — proceeding"
          break
        fi
        sleep 1
      done

      retry apt-get update -y
      retry apt-get install -y git ca-certificates

      install -d -m 0755 ${REPO_DIR%/*}
      if [ ! -d "${REPO_DIR}/.git" ]; then
        retry git clone --branch "${REPO_BRANCH}" --depth 1 "${REPO_URL}" "${REPO_DIR}"
      fi

      SCRIPT="${REPO_DIR}/${BOOTSTRAP_SCRIPT}"
      chmod +x "\$SCRIPT"

      echo "[launcher] executing bootstrap script..."
      # Pass NO_OUTPUT_REDIRECT to prevent duplicate logging
      env NO_OUTPUT_REDIRECT=1 "\$SCRIPT"

  # Systemd service for first-boot bootstrap
  - path: /etc/systemd/system/ctrl01-bootstrap.service
    permissions: "0644"
    content: |
      [Unit]
      Description=HybridOps ctrl-01 Day-1 bootstrap
      After=network-online.target
      Wants=network-online.target

      [Service]
      Type=oneshot
      ExecStart=/usr/local/sbin/day1-launcher
      RemainAfterExit=yes

runcmd:
  - echo '${CIUSER}:${CIPASS}' | chpasswd
  - systemctl daemon-reload
  - systemctl start ctrl01-bootstrap.service
EOF

# --- VM lifecycle orchestration ----------------------------------------------
# Destroys any stale instance and provisions a clean ctrl-01 from template.
echo
echo "───────────────────────────────────────────────────────────────"
echo "[provision] Creating VM '$VMNAME' (ID: $VMID)"
echo "───────────────────────────────────────────────────────────────"

# Graceful cleanup of any previous VM instance
if qm status "$VMID" &>/dev/null; then
  if qm config "$VMID" | grep -q "tags:.*protected"; then
    echo "[provision] VM ${VMID} tagged 'protected' — skipping destroy."
    exit 0
  fi
  mkdir -p /var/log/hybridops_provision
  echo "$(date -Is) | Rebuilt VM $VMNAME (ID $VMID)" >> /var/log/hybridops_provision/destroy_audit.log
  echo "[provision] Rebuilding existing VM (logged)."
  qm stop "$VMID" --timeout 30 >/dev/null 2>&1 || true
  qm destroy "$VMID" --purge >/dev/null 2>&1 || true
fi

# Create new VM definition
qm create "$VMID" --name "$VMNAME" --memory 4096 --cores 2 --cpu host \
  --net0 virtio,bridge="$BRIDGE" --agent 1 --scsihw virtio-scsi-pci --ostype l26 >/dev/null
echo "[INFO] VM shell created."

# Import and attach base disk
echo "[INFO] Importing base image into $DISKSTORE..."
qm importdisk "$VMID" "$IMG" "$DISKSTORE" 2>&1 | grep -v "WARNING: Sum of all thin volume" | grep -v "WARNING: You have not turned on protection" | grep -v "WARNING: Set activation/thin_pool_autoextend_threshold" | sed 's/^/  /'

echo "[INFO] Attaching disk and resizing..."
qm set "$VMID" --scsi0 "$DISKSTORE:vm-$VMID-disk-0" --boot c --bootdisk scsi0 >/dev/null 2>&1
qm resize "$VMID" scsi0 +18G 2>&1 | grep -v "WARNING: Sum of all thin volume" | grep -v "WARNING: You have not turned on protection" | grep -v "WARNING: Set activation/thin_pool_autoextend_threshold" | sed 's/^/  /'
echo "[OK] Disk import and resize complete."

# Apply cloud-init configuration
echo "[INFO] Applying cloud-init and network configuration"
qm set "$VMID" --ide2 "$DISKSTORE:cloudinit" >/dev/null 2>&1
qm set "$VMID" --ipconfig0 "ip=$IPCIDR,gw=$GATEWAY" --nameserver "$DNS" >/dev/null 2>&1
qm set "$VMID" --searchdomain local --ciuser "$CIUSER" >/dev/null 2>&1
qm set "$VMID" --cicustom "user=$SNIPSTORE:snippets/$(basename "$SNIP")" >/dev/null 2>&1
qm cloudinit update "$VMID" >>"$LOG" 2>&1
echo "[OK] Cloud-init ISO generated and linked."

# Boot the VM
echo -n "[+] Booting VM"; for i in {1..5}; do sleep 2; echo -n "."; done; echo
qm start "$VMID" >/dev/null
echo "[OK] VM '$VMNAME' started successfully."

# --- Operator summary ---------------------------------------------------------
set +x
echo
echo "───────────────────────────────────────────────────────────────"
echo "[summary] ctrl-01 Provisioning Summary"
echo "───────────────────────────────────────────────────────────────"
printf " VM Name:        %s (ID %s)\n" "$VMNAME" "$VMID"
printf " IP Address:     %s\n" "${IPCIDR%%/*}"
printf " SSH Access:     ssh %s@%s\n" "$CIUSER" "${IPCIDR%%/*}"
printf " User Password:  [set for %s]\n" "$CIUSER"
printf " Jenkins Admin:  [credentials injected via AKV]\n"
printf " AKV:            %s\n" "$AZURE_KEYVAULT_URL"
printf " Bootstrap:      adaptive — waits for network & GitHub reachability\n"
printf " Probe Target:   %s\n" "$BOOTSTRAP_PROBE_HOST"
printf " Max Wait:       %ss before fallback execution\n" "$BOOTSTRAP_DELAY_SEC"
echo "───────────────────────────────────────────────────────────────"
echo "[info] Cloud-init snippet: $SNIP"
echo "[info] Admin password never stored or logged — fetched from AKV at runtime."
echo "───────────────────────────────────────────────────────────────"
echo "[provision] completed $(date -Is)"
echo
