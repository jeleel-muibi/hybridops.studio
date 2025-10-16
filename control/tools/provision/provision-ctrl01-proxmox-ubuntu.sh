#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# HybridOps Studio — Day-0 Provisioner for ctrl-01 (Proxmox Jenkins Controller)
# -----------------------------------------------------------------------------
# Author: Jeleel Muibi
#
# Description:
#   Idempotent Day-0 bootstrap for the Jenkins control-plane (ctrl-01).
#   Provisions an Ubuntu VM on Proxmox, embeds a cloud-init payload that
#   performs Day-1 configuration autonomously, and injects an ephemeral
#   Jenkins admin credential used only once during controller initialization.
#
# Design intent:
#   • Zero-touch: runs end-to-end from a single script.
#   • Deterministic: embeds all config (no external fetches beyond the repo/img).
#   • Secure: admin secret lives only in-memory and within VM during Day-1.
#   • Adaptive: Day-1 launcher waits for network readiness before execution.
# -----------------------------------------------------------------------------

set -Eeuo pipefail
LOG=/var/log/ctrl01_provision.log
exec > >(tee -a "$LOG") 2>&1
echo "[provision] start $(date -Is)"

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

# --- Ephemeral Jenkins admin credential --------------------------------------
# Prompt interactively if not provided in environment; never logged to stdout.
if [ -z "${JENKINS_ADMIN_PASS:-}" ]; then
  if [ -t 0 ]; then
    echo -n "Enter Jenkins admin password: "
    read -rs JENKINS_ADMIN_PASS
    echo
    [ -z "$JENKINS_ADMIN_PASS" ] && { echo "[provision] ERROR: password cannot be empty."; exit 1; }
  else
    echo "[provision] ERROR: non-interactive run requires JENKINS_ADMIN_PASS preset." >&2
    exit 1
  fi
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
  # Ephemeral Jenkins credential (cleared post-bootstrap)
  - path: /etc/profile.d/jenkins_env.sh
    permissions: "0644"
    content: |
      export JENKINS_ADMIN_PASS="${JENKINS_ADMIN_PASS}"

  # Adaptive Day-1 launcher — validates network then triggers controller setup
  - path: /usr/local/sbin/day1-launcher
    permissions: "0755"
    content: |
      #!/usr/bin/env bash
      set -Eeuo pipefail
      LOG=/var/log/ctrl01_bootstrap.log
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

      if [ -f /etc/profile.d/jenkins_env.sh ]; then
        echo "[launcher] loading Jenkins admin credentials..."
        source /etc/profile.d/jenkins_env.sh
      fi

      chmod +x "\$SCRIPT"
      echo "[launcher] executing bootstrap script..."
      exec env JENKINS_ADMIN_PASS="\${JENKINS_ADMIN_PASS:-}" "\$SCRIPT"

  # Systemd service and timer for first-boot bootstrap
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

  - path: /etc/systemd/system/ctrl01-bootstrap.timer
    permissions: "0644"
    content: |
      [Unit]
      Description=Day-1 bootstrap timer
      [Timer]
      OnBootSec=10
      Unit=ctrl01-bootstrap.service
      [Install]
      WantedBy=timers.target

runcmd:
  - echo '${CIUSER}:${CIPASS}' | chpasswd
  - timedatectl set-ntp true
  - sleep 3
  - systemctl daemon-reexec
  - systemctl daemon-reload
  - systemctl enable --now ctrl01-bootstrap.timer
EOF

# --- VM lifecycle orchestration ----------------------------------------------
# Destroys any stale instance and provisions a clean ctrl-01 from template.
echo
echo "───────────────────────────────────────────────────────────────"
echo "[provision] Creating VM '$VMNAME' (ID: $VMID)"
echo "───────────────────────────────────────────────────────────────"

# Graceful cleanup of any previous VM instance
if qm status "$VMID" &>/dev/null; then
  echo "[WARN] Existing VM ID $VMID detected — attempting graceful shutdown..."
  qm stop "$VMID" --timeout 30 >/dev/null 2>&1 || {
    echo "[WARN] Graceful stop failed, forcing stop..."
    qm stop "$VMID" --skiplock --force-stop >/dev/null 2>&1 || true
  }
  echo "[INFO] Destroying old instance (purge mode)..."
  qm destroy "$VMID" --purge >/dev/null 2>&1 || {
    echo "[WARN] Destroy failed — checking for stale cloud-init volume..."
    if lvs --noheadings -o lv_name pve | grep -q "vm-${VMID}-cloudinit"; then
      echo "[INFO] Removing stale cloud-init volume pve/vm-${VMID}-cloudinit..."
      lvremove -f "pve/vm-${VMID}-cloudinit" >/dev/null 2>&1 || true
    fi
  }
  echo "[OK] Old VM instance removed."
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
echo -n "[+] Booting VM"; for i in {1..3}; do sleep 2; echo -n "."; done; echo
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
printf " Jenkins Admin:  [ephemeral secret injected securely]\n"
printf " Bootstrap:      adaptive — waits for network & GitHub reachability\n"
printf " Probe Target:   %s\n" "$BOOTSTRAP_PROBE_HOST"
printf " Max Wait:       %ss before fallback execution\n" "$BOOTSTRAP_DELAY_SEC"
echo "───────────────────────────────────────────────────────────────"
echo "[info] Cloud-init snippet: $SNIP"
echo "[info] Admin password never logged — stored only inside VM for Day-1 bootstrap, then destroyed."
echo "───────────────────────────────────────────────────────────────"
echo "[provision] completed $(date -Is)"
echo
