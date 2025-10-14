#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# HybridOps Studio: ctrl-01 Day‑0 Provisioner (Ubuntu / Proxmox)
# -----------------------------------------------------------------------------

set -euo pipefail

# VM configuration
VMID=${VMID:-101}
VMNAME=${VMNAME:-ctrl-01}
BRIDGE=${BRIDGE:-vmbr1}
IPCIDR=${IPCIDR:-172.16.10.5/28}
GATEWAY=${GATEWAY:-172.16.10.1}
DNS=${DNS:-8.8.8.8}
DISKSTORE=${DISKSTORE:-local-lvm}
SNIPSTORE=${SNIPSTORE:-local}

# Authentication (critical for SSH access)
CIUSER=${CIUSER:-ubuntu}
CIPASS=${CIPASS:-TempPass123!}

# Bootstrap configuration
BOOTSTRAP_DELAY_SEC=${BOOTSTRAP_DELAY_SEC:-120}
REPO_URL=${REPO_URL:-https://github.com/jeleel-muibi/hybridops.studio}
REPO_BRANCH=${REPO_BRANCH:-main}
REPO_DIR=${REPO_DIR:-/srv/hybridops}
BOOTSTRAP_SCRIPT=${BOOTSTRAP_SCRIPT:-control/tools/provision/bootstrap/ctrl01-bootstrap.sh}

# SSH keys (optional but recommended)
PUBKEY_FILES=(
  /root/.ssh/id_rsa.pub
  /root/.ssh/id_ed25519.pub
)

# Ubuntu cloud image
UBUNTU_IMG_URL=${UBUNTU_IMG_URL:-https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img}

# Setup directories and paths
set -x
install -d -m 0755 /var/lib/vz/template/iso /var/lib/vz/snippets
pvesm set "$SNIPSTORE" --content vztmpl,iso,backup,snippets >/dev/null 2>&1 || true

# Download image if needed
IMG="/var/lib/vz/template/iso/$(basename "$UBUNTU_IMG_URL")"
[ -s "$IMG" ] || wget -O "$IMG" "$UBUNTU_IMG_URL"

# Process SSH keys
AUTHORIZED_KEYS=""
for f in "${PUBKEY_FILES[@]}"; do
  if [ -s "$f" ]; then
    line=$(sed -e 's/[\\/&]/\\&/g' "$f")
    AUTHORIZED_KEYS="${AUTHORIZED_KEYS}      - ${line}\n"
  fi
done

# Create cloud-init configuration with explicit password auth
SNIP="/var/lib/vz/snippets/ctrl01-day0.yaml"
cat >"$SNIP" <<EOF
#cloud-config
preserve_hostname: false
hostname: ${VMNAME}
fqdn: ${VMNAME}
manage_etc_hosts: true
ssh_pwauth: true

users:
  - name: ${CIUSER}
    gecos: Control Node User
    groups: sudo
    shell: /bin/bash
    lock_passwd: false
    sudo: ALL=(ALL) NOPASSWD:ALL
    passwd: ${CIPASS}
$( [ -n "$AUTHORIZED_KEYS" ] && printf "    ssh_authorized_keys:\n%s" "$AUTHORIZED_KEYS" )

write_files:
  # CRITICAL: Force password authentication in multiple locations
  - path: /etc/ssh/sshd_config.d/50-cloud-init.conf
    permissions: "0644"
    content: |
      # Cloud-init configuration - ALLOW PASSWORD AUTH
      PasswordAuthentication yes
      ChallengeResponseAuthentication yes
      UsePAM yes
      X11Forwarding yes
      PrintMotd no

  # Day‑1 bootstrap launcher with resilient design
  - path: /usr/local/sbin/day1-launcher
    permissions: "0755"
    content: |
      #!/usr/bin/env bash
      set -Eeuo pipefail
      LOG=/var/log/ctrl01_bootstrap.log
      exec > >(tee -a "\$LOG") 2>&1
      echo "[launcher] Starting Day-1 bootstrap at \$(date -Is)"

      # Create tracking markers
      mkdir -p /var/lib/ctrl01
      touch /var/lib/ctrl01/bootstrap-started-\$(date +%s)

      # Network retry helper
      retry() {
        local n=0; local tries=20; local delay=10;
        while [ \$n -lt \$tries ]; do
          if "\$@"; then return 0; fi
          n=\$((n+1))
          echo "[retry] \$n/\$tries failed: \$*"
          sleep \$delay
          delay=\$((delay >= 60 ? 60 : delay + 10))
        done
        return 1
      }

      # Ensure DNS works
      echo "[launcher] Waiting for DNS resolution..."
      retry host github.com

      # Install git
      export DEBIAN_FRONTEND=noninteractive
      retry apt-get update
      retry apt-get -y install git

      # Clone repo
      install -d -m 0755 ${REPO_DIR%/*}
      if [ ! -d "${REPO_DIR}/.git" ]; then
        echo "[launcher] Cloning ${REPO_URL} to ${REPO_DIR}"
        retry git clone --branch "${REPO_BRANCH}" --depth 1 "${REPO_URL}" "${REPO_DIR}"
      fi

      # Run bootstrap script
      SCRIPT="${REPO_DIR}/${BOOTSTRAP_SCRIPT}"
      if [ -f "\$SCRIPT" ]; then
        echo "[launcher] Running bootstrap script"
        chmod +x "\$SCRIPT"
        exec "\$SCRIPT"
      else
        echo "[launcher] ERROR: Bootstrap script not found at \$SCRIPT"
        exit 1
      fi

  # Systemd units
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
      AccuracySec=5s
      Unit=ctrl01-bootstrap.service

      [Install]
      WantedBy=timers.target

runcmd:
  # CRITICAL: These steps fix SSH password authentication
  - sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  - sed -i 's/^#*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
  - echo '${CIUSER}:${CIPASS}' | chpasswd
  - systemctl restart ssh || systemctl restart sshd

  # Enable bootstrap services
  - systemctl daemon-reload
  - systemctl enable --now ctrl01-bootstrap.timer
EOF

# Remove any existing VM
qm stop "$VMID" >/dev/null 2>&1 || true
qm destroy "$VMID" --purge >/dev/null 2>&1 || true

# Create VM
qm create "$VMID" --name "$VMNAME" --memory 4096 --cores 2 --cpu host \
  --net0 virtio,bridge="$BRIDGE" --agent 1 --scsihw virtio-scsi-pci --ostype l26
qm importdisk "$VMID" "$IMG" "$DISKSTORE"
qm set "$VMID" --scsi0 "$DISKSTORE:vm-$VMID-disk-0" --boot c --bootdisk scsi0
qm set "$VMID" --ide2 "$DISKSTORE:cloudinit"
qm set "$VMID" --serial0 socket --vga qxl

# Enlarge disk
qm disk resize "$VMID" scsi0 +28G

# Set cloud-init parameters
qm set "$VMID" --ciuser "$CIUSER" --cipassword "$CIPASS"
qm set "$VMID" --ipconfig0 "ip=$IPCIDR,gw=$GATEWAY"
qm set "$VMID" --nameserver "$DNS"

# Use our custom user-data
qm set "$VMID" --cicustom "user=$SNIPSTORE:snippets/$(basename "$SNIP")"

# Finalize and start
qm cloudinit update "$VMID"
qm start "$VMID"

set +x
echo
echo "==================== ctrl-01 Provisioning Summary ===================="
echo " VM:            ${VMNAME} (ID ${VMID})"
echo " IP:            ${IPCIDR%%/*}"
echo " SSH access:    ssh ${CIUSER}@${IPCIDR%%/*}"
echo " Password:      ${CIPASS}"
echo " Waiting time:  2-3 minutes for boot and network setup"
echo " Day-1 timer:   Will run after ${BOOTSTRAP_DELAY_SEC}s"
echo "=================================================================="
