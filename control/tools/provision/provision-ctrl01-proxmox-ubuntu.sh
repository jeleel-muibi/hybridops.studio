#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# HybridOps Studio — Day-0 Provisioner for ctrl-01 (Proxmox Jenkins Controller)
# -----------------------------------------------------------------------------
# Purpose:
#   Creates and boots the ctrl-01 VM entirely from one file.
#   This script provisions Ubuntu with cloud-init, installs Jenkins on first
#   boot, and injects an ephemeral admin password used only during bootstrap.
#
# Zero-Touch Design:
#   - No external dependencies or repo cloning required.
#   - All logic and cloud-init YAML embedded inline.
#   - Fully repeatable on any Proxmox host with one command.
#
# Security Note:
#   The Jenkins admin password is generated or prompted once and embedded
#   temporarily in the cloud-init snippet. It exists only on the Proxmox host
#   during Day-0 provisioning and inside the VM during Day-1 bootstrap.
#   Jenkins hashes it immediately, and the plaintext can then be discarded.
#   In production, this would be replaced by a vault-sourced secret.
#
# Usage:
#   sudo bash provision-ctrl01-proxmox-ubuntu.sh
# -----------------------------------------------------------------------------

set -Eeuo pipefail
LOG=/var/log/ctrl01_provision.log
exec > >(tee -a "$LOG") 2>&1
echo "[provision] start $(date -Is)"

# --- VM configuration ---------------------------------------------------------
VMID=${VMID:-101}
VMNAME=${VMNAME:-ctrl-01}
BRIDGE=${BRIDGE:-vmbr1}
IPCIDR=${IPCIDR:-172.16.10.5/28}
GATEWAY=${GATEWAY:-172.16.10.1}
DNS=${DNS:-8.8.8.8}
DISKSTORE=${DISKSTORE:-local-lvm}
SNIPSTORE=${SNIPSTORE:-local}

# --- cloud-init user ----------------------------------------------------------
CIUSER=${CIUSER:-hybridops}
CIPASS=${CIPASS:-TempPass123!}

# --- one-time admin password --------------------------------------------------
if [ -z "${JENKINS_ADMIN_PASS:-}" ]; then
  if [ -t 0 ]; then
    echo -n "Enter Jenkins admin password: "
    read -rs JENKINS_ADMIN_PASS
    echo
    if [ -z "$JENKINS_ADMIN_PASS" ]; then
      echo "[provision] ERROR: password cannot be empty in interactive mode." >&2
      exit 1
    fi
  else
    echo "[provision] ERROR: non-interactive run requires JENKINS_ADMIN_PASS preset." >&2
    exit 1
  fi
fi

# --- repository parameters ----------------------------------------------------
REPO_URL=${REPO_URL:-https://github.com/jeleel-muibi/hybridops.studio}
REPO_BRANCH=${REPO_BRANCH:-main}
REPO_DIR=${REPO_DIR:-/srv/hybridops}
BOOTSTRAP_SCRIPT=${BOOTSTRAP_SCRIPT:-control/tools/provision/bootstrap/ctrl01-bootstrap.sh}
BOOTSTRAP_DELAY_SEC=${BOOTSTRAP_DELAY_SEC:-120}

# --- base image ---------------------------------------------------------------
UBUNTU_IMG_URL=${UBUNTU_IMG_URL:-https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img}
install -d -m 0755 /var/lib/vz/template/iso /var/lib/vz/snippets
IMG="/var/lib/vz/template/iso/$(basename "$UBUNTU_IMG_URL")"
[ -s "$IMG" ] || wget -O "$IMG" "$UBUNTU_IMG_URL"

# --- ssh key injection --------------------------------------------------------
AUTHORIZED_KEYS=""
for f in /root/.ssh/id_rsa.pub /root/.ssh/id_ed25519.pub; do
  [ -s "$f" ] && AUTHORIZED_KEYS+="      - $(tr -d '\r\n' < "$f")\n"
done

# --- Generate cloud-init config ----------------------------------------------
# Inline heredoc integrated to preserve single-file zero-touch reproducibility.
# The embedded password is ephemeral and exists only for initial boot.
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
  - path: /etc/profile.d/jenkins_env.sh
    permissions: "0600"
    content: |
      export JENKINS_ADMIN_PASS="${JENKINS_ADMIN_PASS}"

  - path: /usr/local/sbin/day1-launcher
    permissions: "0755"
    content: |
      #!/usr/bin/env bash
      set -Eeuo pipefail
      LOG=/var/log/ctrl01_bootstrap.log
      exec > >(tee -a "$LOG") 2>&1
      echo "[launcher] starting Day-1 at \$(date -Is)"
      retry() { local n=0 tries=20 delay=10; while [ \$n -lt \$tries ]; do "\$@" && return 0 || true; n=\$((n+1)); echo "[retry] \$n/\$tries failed: \$*"; sleep \$delay; done; return 1; }
      retry bash -lc 'getent hosts github.com >/dev/null 2>&1'
      apt-get update -y && apt-get install -y git ca-certificates
      install -d -m 0755 ${REPO_DIR%/*}
      [ -d "${REPO_DIR}/.git" ] || retry git clone --branch "${REPO_BRANCH}" --depth 1 "${REPO_URL}" "${REPO_DIR}"
      SCRIPT="${REPO_DIR}/${BOOTSTRAP_SCRIPT}"
      chmod +x "\$SCRIPT"
      exec "\$SCRIPT"

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
      OnBootSec=${BOOTSTRAP_DELAY_SEC}
      Unit=ctrl01-bootstrap.service
      [Install]
      WantedBy=timers.target

runcmd:
  - echo '${CIUSER}:${CIPASS}' | chpasswd
  - systemctl daemon-reload
  - systemctl enable --now ctrl01-bootstrap.timer
EOF

# --- Create VM ---------------------------------------------------------------
echo
echo "───────────────────────────────────────────────────────────────"
echo "[provision] Creating VM '$VMNAME' (ID: $VMID)"
echo "───────────────────────────────────────────────────────────────"

# stop and clean any old VM silently
qm stop "$VMID" &>/dev/null || true
qm destroy "$VMID" --purge &>/dev/null || true

# create base VM
echo "[+] Creating VM definition..."
qm create "$VMID" \
  --name "$VMNAME" \
  --memory 4096 \
  --cores 2 \
  --cpu host \
  --net0 virtio,bridge="$BRIDGE" \
  --agent 1 \
  --scsihw virtio-scsi-pci \
  --ostype l26  >/dev/null

# import disk and attach
echo "[+] Importing base image..."
qm importdisk "$VMID" "$IMG" "$DISKSTORE" >>"$LOG" 2>&1

echo "[+] Configuring cloud-init and network..."
qm set "$VMID" --scsi0 "$DISKSTORE:vm-$VMID-disk-0" --boot c --bootdisk scsi0 >/dev/null
qm set "$VMID" --ide2 "$DISKSTORE:cloudinit" >/dev/null
qm set "$VMID" --ipconfig0 "ip=$IPCIDR,gw=$GATEWAY" --nameserver "$DNS" >/dev/null
qm set "$VMID" --searchdomain local --ciuser "$CIUSER" >/dev/null

# verify snippet exists
if [ ! -s "$SNIP" ]; then
  echo "[provision] ERROR: cloud-init snippet not found or empty at $SNIP" >&2
  exit 1
fi

echo "[+] Linking cloud-init snippet..."
qm set "$VMID" --cicustom "user=$SNIPSTORE:snippets/$(basename "$SNIP")" >/dev/null

# Finalize and start
echo "[+] Generating cloud-init ISO..."
qm cloudinit update "$VMID" >>"$LOG" 2>&1
echo "[provision] done $(date -Is)"
echo -n "[+] Booting VM"
for i in {1..3}; do
  sleep 1
  echo -n "."
done
echo
qm start "$VMID" >/dev/null

echo "[info] Waiting a few seconds for Proxmox to register VM state..."
sleep 3

# --- Final summary ------------------------------------------------------------
set +x
echo
echo "───────────────────────────────────────────────────────────────"
echo "[summary] ctrl-01 Provisioning Summary"
echo "───────────────────────────────────────────────────────────────"
printf " VM Name:        %s (ID %s)\n" "$VMNAME" "$VMID"
printf " IP Address:     %s\n" "${IPCIDR%%/*}"
printf " SSH Access:     ssh %s@%s\n" "$CIUSER" "${IPCIDR%%/*}"
printf " Password:       %s\n" "$CIPASS"
printf " Wait Time:      1–3 minutes for initial boot and network setup\n"
printf " Day-1 Timer:    Triggers after %ss\n" "$BOOTSTRAP_DELAY_SEC"
echo "───────────────────────────────────────────────────────────────"
echo "[info] Cloud-init snippet: $SNIP"
echo "[info] Admin password is ephemeral — used once during Jenkins initialization, then hashed internally."
echo "───────────────────────────────────────────────────────────────"
echos
