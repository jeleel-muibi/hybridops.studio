#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# HybridOps Studio — Day‑0 Provisioner (Proxmox ➜ Ubuntu cloud VM)
# Creates ctrl‑01 VM and installs a Day‑1 *fetcher* that will clone your repo
# and execute: control/tools/provision/bootstrap/ctrl01-bootstrap.sh
# -----------------------------------------------------------------------------

# ===== Defaults (override via env, e.g. VMID=201 ./this.sh) =====
VMID=${VMID:-101}
VMNAME=${VMNAME:-ctrl-01}
BRIDGE=${BRIDGE:-vmbr1}
IPCIDR=${IPCIDR:-172.16.10.5/28}
GATEWAY=${GATEWAY:-172.16.10.1}
DNS1=${DNS1:-8.8.8.8}
DNS2=${DNS2:-1.1.1.1}
DISKSTORE=${DISKSTORE:-local-lvm}
SNIPSTORE=${SNIPSTORE:-local}

# Day‑0 login
CIUSER=${CIUSER:-ubuntu}
CIPASS=${CIPASS:-TempPass123!}

# Repo to fetch on Day‑1
REPO_URL=${REPO_URL:-https://github.com/jeleel-muibi/hybridops.studio}
REPO_BRANCH=${REPO_BRANCH:-main}
REPO_DIR=${REPO_DIR:-/srv/hybridops}
DAY1_REL_PATH=${DAY1_REL_PATH:-control/tools/provision/bootstrap/ctrl01-bootstrap.sh}

# Day‑1 timing
BOOTSTRAP_DELAY_SEC=${BOOTSTRAP_DELAY_SEC:-30}

# Feature flags passed to Day‑1
ENABLE_FULL_BOOTSTRAP=${ENABLE_FULL_BOOTSTRAP:-true}
ENABLE_JENKINS=${ENABLE_JENKINS:-true}
ENABLE_AUTO_HARDEN=${ENABLE_AUTO_HARDEN:-true}
HARDEN_GRACE_MIN=${HARDEN_GRACE_MIN:-10}

# Ubuntu 22.04 LTS image URL
UBUNTU_IMG_URL=${UBUNTU_IMG_URL:-https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img}

# Public keys to embed
PUBKEY_FILES=(/root/.ssh/id_rsa.pub /root/.ssh/id_ed25519.pub)

set -x
install -d -m 0755 /var/lib/vz/template/iso /var/lib/vz/snippets
pvesm set "$SNIPSTORE" --content vztmpl,iso,backup,snippets >/dev/null 2>&1 || true

IMG="/var/lib/vz/template/iso/$(basename "$UBUNTU_IMG_URL")"
[ -s "$IMG" ] || wget -O "$IMG" "$UBUNTU_IMG_URL"

AUTHORIZED_KEYS=""
for f in "${PUBKEY_FILES[@]}"; do
  if [ -s "$f" ]; then
    line=$(tr -d '\r\n' < "$f")
    AUTHORIZED_KEYS="${AUTHORIZED_KEYS}      - ${line}\n"
  fi
done

SNIP="/var/lib/vz/snippets/ctrl01-ubuntu-day0.yaml"
cat >"$SNIP" <<EOF
#cloud-config
preserve_hostname: false
hostname: ${VMNAME}
manage_etc_hosts: true
ssh_pwauth: true
users:
  - name: ${CIUSER}
    gecos: Control Node User
    groups: sudo
    shell: /bin/bash
    lock_passwd: false
    sudo: ALL=(ALL) NOPASSWD:ALL
    plain_text_passwd: '${CIPASS}'
$( [ -n "$AUTHORIZED_KEYS" ] && printf "    ssh_authorized_keys:\n%s" "$AUTHORIZED_KEYS" )
write_files:
  - path: /etc/ssh/sshd_config.d/01-password-auth.conf
    permissions: "0644"
    content: |
      PasswordAuthentication yes
      PubkeyAuthentication yes
      KbdInteractiveAuthentication yes
      ChallengeResponseAuthentication yes
      UsePAM yes
      PermitRootLogin no

  # Day‑1 fetcher: clones repo and executes in-repo bootstrap
  - path: /usr/local/sbin/ctrl01-day1-fetch
    permissions: "0755"
    content: |
      #!/usr/bin/env bash
      set -Eeuo pipefail
      LOG=/var/log/ctrl01_bootstrap.log
      exec > >(tee -a "$LOG") 2>&1
      echo "[day1-fetch] start $(date -Is)"

      retry() { n=1; tries="$1"; sleep_s="$2"; shift 2;
        until "$@"; do
          if [ "$n" -ge "$tries" ]; then echo "RETRY: giving up after $n: $*"; exit 1; fi
          echo "RETRY: $n/$tries failed: $* ; sleeping ${sleep_s}s"; sleep "$sleep_s"; n=$((n+1))
        done
      }

      grep -q '::ffff:0:0/96' /etc/gai.conf 2>/dev/null || echo 'precedence ::ffff:0:0/96  100' | tee -a /etc/gai.conf >/dev/null
      rm -rf /var/lib/apt/lists/* || true
      apt-get clean || true
      dpkg --configure -a || true
      retry 20 3 bash -lc 'ping -c1 -W1 ${DNS1} >/dev/null 2>&1'
      retry 20 3 bash -lc 'getent hosts archive.ubuntu.com >/dev/null 2>&1'

      install -d -m 0755 ${REPO_DIR%/*}
      if [ ! -d "${REPO_DIR}/.git" ]; then
        echo "[day1-fetch] cloning ${REPO_URL}@${REPO_BRANCH}"
        retry 8 5 git clone --branch "${REPO_BRANCH}" --depth 1 "${REPO_URL}" "${REPO_DIR}"
      else
        echo "[day1-fetch] updating repo"
        git -C "${REPO_DIR}" fetch --depth 1 origin "${REPO_BRANCH}" || true
        git -C "${REPO_DIR}" checkout "${REPO_BRANCH}" || true
        git -C "${REPO_DIR}" pull --ff-only || true
      fi

      BOOT="${REPO_DIR}/${DAY1_REL_PATH}"
      if [ ! -x "$BOOT" ]; then
        echo "[day1-fetch] ERROR: bootstrap not found at $BOOT"; exit 2
      fi
      echo "[day1-fetch] exec $BOOT"
      ENABLE_FULL_BOOTSTRAP=${ENABLE_FULL_BOOTSTRAP} \
      ENABLE_JENKINS=${ENABLE_JENKINS} \
      ENABLE_AUTO_HARDEN=${ENABLE_AUTO_HARDEN} \
      HARDEN_GRACE_MIN=${HARDEN_GRACE_MIN} \
      CIUSER=${CIUSER} \
      bash "$BOOT"

  - path: /etc/systemd/system/ctrl01-day1-fetch.service
    permissions: "0644"
    content: |
      [Unit]
      Description=HybridOps ctrl-01 Day-1 fetch & launch
      After=network-online.target
      Wants=network-online.target

      [Service]
      Type=oneshot
      ExecStart=/usr/local/sbin/ctrl01-day1-fetch
      RemainAfterExit=yes

  - path: /etc/systemd/system/ctrl01-day1-fetch.timer
    permissions: "0644"
    content: |
      [Unit]
      Description=Delay then run ctrl01-day1-fetch

      [Timer]
      OnBootSec=${BOOTSTRAP_DELAY_SEC}
      AccuracySec=5s
      Unit=ctrl01-day1-fetch.service

      [Install]
      WantedBy=timers.target

runcmd:
  - sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  - systemctl restart ssh || systemctl restart sshd
  - systemctl daemon-reload
  - systemctl enable --now ctrl01-day1-fetch.timer
EOF

# Recreate VM
qm stop "$VMID" >/dev/null 2>&1 || true
qm destroy "$VMID" --purge >/dev/null 2>&1 || true

qm create "$VMID" --name "$VMNAME" --memory 4096 --cores 2 --cpu host \
  --net0 virtio,bridge="$BRIDGE" --agent 1 --scsihw virtio-scsi-pci --ostype l26
qm importdisk "$VMID" "$IMG" "$DISKSTORE"
qm set "$VMID" --scsi0 "$DISKSTORE:vm-$VMID-disk-0" --boot c --bootdisk scsi0
qm set "$VMID" --ide2 "$DISKSTORE:cloudinit"
qm set "$VMID" --serial0 socket --vga qxl
qm disk resize "$VMID" scsi0 +28G || true

qm set "$VMID" --ciuser "$CIUSER" --cipassword "$CIPASS"
qm set "$VMID" --ipconfig0 "ip=$IPCIDR,gw=$GATEWAY"
qm set "$VMID" --nameserver "$DNS1"

qm set "$VMID" --cicustom "user=$SNIPSTORE:snippets/$(basename "$SNIP")"
qm cloudinit update "$VMID"
qm start "$VMID"

set +x
echo
echo "=== Day-0 complete ==="
echo "VM: $VMNAME  IP: ${IPCIDR%%/*}  User: $CIUSER  Pass: $CIPASS"
echo "Day-1 will start via: ctrl01-day1-fetch.timer (~${BOOTSTRAP_DELAY_SEC}s)"
