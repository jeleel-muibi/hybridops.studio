#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# HybridOps Studio: ctrl-01 Day‑0 → Day‑1 Provisioner (Ubuntu / Proxmox)
# -----------------------------------------------------------------------------
# PURPOSE
#   • Day‑0 (Proxmox-side): create an Ubuntu cloud VM with deterministic access
#     (password + SSH key), correct console, static IP, and cloud‑init user-data.
#   • Day‑1 (inside VM): auto-install core tooling (Terraform, Packer, kubectl,
#     Helm, Ansible, Jenkins), clone the HybridOps repo, then adaptive hardening.
#
# WHY (ties to ADR‑0012)
#   • Control node as a FULL VM for portability (Proxmox ⇄ VMware), clean
#     systemd, and DR export. LXC kept for light helpers only.
#
# OPERATIONAL SHAPE
#   • One file, run on the Proxmox host. It writes a cloud‑init snippet and
#     creates/starts the VM. Inside the guest, a systemd timer triggers Day‑1.
#
# SAFE DEFAULTS
#   • Login user: ubuntu / TempPass123! (change below or via env vars)
#   • Day‑1 delay: 30s, then robust retries for apt/dpkg/network.
#   • Disk is expanded on Day‑0 (+28G) and grown in-guest at Day‑1.
#
# AUDIT ARTIFACTS (in-guest)
#   • Logs:        /var/log/ctrl01_bootstrap.log
#   • Status JSON: /var/lib/ctrl01/status.json
#
# NOTE
#   • Toggle flags below are COMMENTED examples you can pre-set for demos.
#   • You can also set any variable via the environment when calling this script.
# -----------------------------------------------------------------------------

set -euo pipefail

# ====== EDITABLE VARS (Override with env, e.g. VMID=201 ./this.sh) ======
VMID=${VMID:-101}
VMNAME=${VMNAME:-ctrl-01}
BRIDGE=${BRIDGE:-vmbr1}
IPCIDR=${IPCIDR:-172.16.10.5/28}
GATEWAY=${GATEWAY:-172.16.10.1}
DNS1=${DNS1:-8.8.8.8}
DNS2=${DNS2:-1.1.1.1}
DISKSTORE=${DISKSTORE:-local-lvm}
SNIPSTORE=${SNIPSTORE:-local}

# Login (Day‑0)
CIUSER=${CIUSER:-ubuntu}
CIPASS=${CIPASS:-TempPass123!}

# Day‑1 behavior (feature flags)
ENABLE_FULL_BOOTSTRAP=${ENABLE_FULL_BOOTSTRAP:-true}   # install the full toolchain
ENABLE_JENKINS=${ENABLE_JENKINS:-true}                 # install & start Jenkins
ENABLE_AUTO_HARDEN=${ENABLE_AUTO_HARDEN:-true}         # disable password auth if a key exists
HARDEN_GRACE_MIN=${HARDEN_GRACE_MIN:-10}               # minutes to wait before hardening
BOOTSTRAP_DELAY_SEC=${BOOTSTRAP_DELAY_SEC:-30}         # seconds to wait after boot before Day‑1

# Repo bootstrap (cloned on Day‑1)
REPO_URL=${REPO_URL:-https://github.com/jeleel-muibi/hybridops.studio}
REPO_BRANCH=${REPO_BRANCH:-main}
REPO_DIR=${REPO_DIR:-/srv/hybridops}

# OPTIONAL PRE-SET EXAMPLES (uncomment to bake in for demos/assessors)
# ENABLE_FULL_BOOTSTRAP=false
# ENABLE_JENKINS=false
# ENABLE_AUTO_HARDEN=false
# HARDEN_GRACE_MIN=20
# BOOTSTRAP_DELAY_SEC=60
# REPO_URL=https://github.com/yourorg/yourrepo
# REPO_BRANCH=main

# Public keys to embed (add more paths as needed)
PUBKEY_FILES=(
  /root/.ssh/id_rsa.pub
  /root/.ssh/id_ed25519.pub
)

# Ubuntu 22.04 LTS cloud image
UBUNTU_IMG_URL=${UBUNTU_IMG_URL:-https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img}

# -----------------------------------------------------------------------------
# Day‑0 (Proxmox host): Create VM + Cloud‑init snippet
# -----------------------------------------------------------------------------
set -x
install -d -m 0755 /var/lib/vz/template/iso /var/lib/vz/snippets
pvesm set "$SNIPSTORE" --content vztmpl,iso,backup,snippets >/dev/null 2>&1 || true

IMG="/var/lib/vz/template/iso/$(basename "$UBUNTU_IMG_URL")"
[ -s "$IMG" ] || wget -O "$IMG" "$UBUNTU_IMG_URL"

# Build YAML list of authorized_keys
AUTHORIZED_KEYS=""
for f in "${PUBKEY_FILES[@]}"; do
  if [ -s "$f" ]; then
    line=$(sed -e 's/[\\/&]/\\&/g' "$f")
    AUTHORIZED_KEYS="${AUTHORIZED_KEYS}      - ${line}\n"
  fi
done

# Cloud‑init user-data: Day‑0 + Day‑1 (no nested heredocs)
SNIP="/var/lib/vz/snippets/ctrl01-ubuntu-login.yaml"
cat >"$SNIP" <<EOF
#cloud-config
preserve_hostname: false
hostname: ${VMNAME}
fqdn: ${VMNAME}
manage_etc_hosts: true
ssh_pwauth: true
growpart:
  mode: auto
  devices: ['/']
  ignore_growroot_disabled: false

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
  # Day‑0 SSH policy: allow both methods for guaranteed access
  - path: /etc/ssh/sshd_config.d/01-password-auth.conf
    permissions: "0644"
    content: |
      PasswordAuthentication yes
      PubkeyAuthentication yes
      KbdInteractiveAuthentication yes
      ChallengeResponseAuthentication yes
      UsePAM yes
      PermitRootLogin no

  # Serial console for Proxmox (optional but handy)
  - path: /etc/systemd/system/serial-getty@ttyS0.service.d/override.conf
    permissions: "0644"
    content: |
      [Service]
      ExecStart=
      ExecStart=-/sbin/agetty -o '-p -- \\u' --keep-baud 115200,38400,9600 ttyS0 vt220

  # Day‑1 bootstrap script (runs via systemd timer)
  - path: /usr/local/sbin/ctrl01-bootstrap
    permissions: "0755"
    content: |
      #!/usr/bin/env bash
      # HybridOps Day‑1: Tooling install, repo clone, adaptive hardening
      set -Eeuo pipefail
      LOG=/var/log/ctrl01_bootstrap.log
      exec > >(tee -a "\$LOG") 2>&1
      echo "[bootstrap] start \$(date -Is)"
      export LC_ALL=C LANG=C

      retry() { local n=1; local tries="\$1"; local sleep_s="\$2"; shift 2;
        until "\$@"; do
          if [ \$n -ge "\$tries" ]; then echo "RETRY: giving up after \$n: \$*"; return 1; fi
          echo "RETRY: \$n/\$tries failed: \$* ; sleeping \${sleep_s}s"; sleep "\$sleep_s"; n=\$((n+1))
        done
      }

      # Prefer IPv4 for flaky links
      grep -q '::ffff:0:0/96' /etc/gai.conf 2>/dev/null || echo 'precedence ::ffff:0:0/96  100' | sudo tee -a /etc/gai.conf >/dev/null

      # Ensure dpkg/apt are sane and caches are minimal
      rm -rf /var/lib/apt/lists/* || true
      apt-get clean || true
      dpkg --configure -a || true

      # Network readiness
      retry 20 3 bash -lc 'ping -c1 -W1 ${DNS1} >/dev/null 2>&1'
      retry 20 3 bash -lc 'getent hosts archive.ubuntu.com >/dev/null 2>&1'

      # Grow root partition & filesystem (no‑op if already maxed)
      if ! command -v growpart >/dev/null 2>&1; then
        retry 8 5 bash -lc 'DEBIAN_FRONTEND=noninteractive apt-get update -o Acquire::ForceIPv4=true'
        retry 8 5 bash -lc 'DEBIAN_FRONTEND=noninteractive apt-get -y install cloud-guest-utils'
      fi
      if lsblk -no FSTYPE /dev/sda1 2>/dev/null | grep -qi ext4; then
        (command -v growpart >/dev/null 2>&1 && growpart /dev/sda 1) || true
        resize2fs /dev/sda1 || true
      elif lsblk -no FSTYPE /dev/sda1 2>/dev/null | grep -qi xfs; then
        (command -v growpart >/dev/null 2>&1 && growpart /dev/sda 1) || true
        xfs_growfs -d / || true
      fi

      # Base tools + guest agent
      retry 8 5 bash -lc 'DEBIAN_FRONTEND=noninteractive apt-get update -o Acquire::ForceIPv4=true'
      retry 8 5 bash -lc 'DEBIAN_FRONTEND=noninteractive apt-get -y install qemu-guest-agent curl git jq unzip wget tar ca-certificates make python3-pip ufw'
      systemctl enable --now qemu-guest-agent || true

      if [ "\${ENABLE_FULL_BOOTSTRAP:-true}" = "true" ]; then
        echo "[bootstrap] installing toolchain"

        # HashiCorp (terraform/packer)
        . /etc/os-release
        curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com \$VERSION_CODENAME main" | tee /etc/apt/sources.list.d/hashicorp.list >/dev/null

        # Kubernetes (kubectl)
        curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor | tee /usr/share/keyrings/kubernetes-archive-keyring.gpg >/dev/null
        echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list >/dev/null

        # Jenkins (optional)
        if [ "\${ENABLE_JENKINS:-true}" = "true" ]; then
          curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | gpg --dearmor | tee /usr/share/keyrings/jenkins-keyring.gpg >/dev/null
          echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list >/dev/null
        fi

        retry 8 5 bash -lc 'DEBIAN_FRONTEND=noninteractive apt-get update -o Acquire::ForceIPv4=true'
        PKGS="terraform packer kubectl ansible fontconfig openjdk-17-jre-headless"
        if [ "\${ENABLE_JENKINS:-true}" = "true" ]; then PKGS="\$PKGS jenkins"; fi
        retry 6 5 bash -lc "DEBIAN_FRONTEND=noninteractive apt-get -y install \$PKGS"

        # Helm via official script (fallback)
        if ! command -v helm >/dev/null 2>&1; then
          retry 5 5 bash -lc 'curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash'
        fi

        # Firewall (SSH + Jenkins if installed)
        ufw allow 22/tcp || true
        [ "\${ENABLE_JENKINS:-true}" = "true" ] && ufw allow 8080/tcp || true
        yes | ufw enable || true

        [ "\${ENABLE_JENKINS:-true}" = "true" ] && systemctl enable --now jenkins || true
      fi

      # Clone or update the repo (idempotent)
      install -d -m 0755 ${REPO_DIR%/*}
      if [ ! -d "${REPO_DIR}/.git" ]; then
        echo "[bootstrap] cloning repo ${REPO_URL} -> ${REPO_DIR} (branch ${REPO_BRANCH})"
        retry 6 5 git clone --branch "${REPO_BRANCH}" --depth 1 "${REPO_URL}" "${REPO_DIR}"
      else
        echo "[bootstrap] updating repo ${REPO_DIR}"
        git -C "${REPO_DIR}" fetch --depth 1 origin "${REPO_BRANCH}" || true
        git -C "${REPO_DIR}" checkout "${REPO_BRANCH}" || true
        git -C "${REPO_DIR}" pull --ff-only || true
      fi

      # TODO: Seed Jenkins jobs / pipelines from repo (if present)
      # e.g., run a bootstrap make target or groovy init script.
      # Placeholder runbook hook:
      #   ${REPO_DIR}/docs/runbooks/ctrl01/bootstrap.md

      # Status artifact
      install -d -m 0755 /var/lib/ctrl01
      IP="\$(hostname -I | awk '{print \$1}')"
      printf '{"status":"ok","ip":"%s","jenkins":"http://%s:8080","ts":"%s","bootstrap":"%s","repo":"%s@%s"}\n' \
        "\$IP" "\$IP" "\$(date -Is)" "\${ENABLE_FULL_BOOTSTRAP:-true}" "${REPO_URL}" "${REPO_BRANCH}" > /var/lib/ctrl01/status.json
      echo "[bootstrap] base converge done \$(date -Is)"

      if [ "\${ENABLE_AUTO_HARDEN:-true}" = "true" ]; then
        echo "[bootstrap] adaptive hardening: grace ${HARDEN_GRACE_MIN}m"
        sleep "\$(( ${HARDEN_GRACE_MIN} * 60 ))"
        AUTH="/home/${CIUSER}/.ssh/authorized_keys"
        if [ -s "\$AUTH" ]; then
          echo "[bootstrap] key detected, disabling password auth"
          mkdir -p /etc/ssh/sshd_config.d
          printf '%s\n' "PasswordAuthentication no" "KbdInteractiveAuthentication no" "ChallengeResponseAuthentication no" "UsePAM yes" > /etc/ssh/sshd_config.d/99-password-off.conf
          systemctl reload ssh || systemctl reload sshd || true
          echo '${CIUSER}:Expired-'\$(date +%s)'!' | chpasswd || true
        else
          echo "[bootstrap] no key found; leaving password auth enabled"
        fi
      fi

      echo "[bootstrap] done \$(date -Is)"

  # Day‑1 systemd unit + timer (no network-online dependency)
  - path: /etc/systemd/system/ctrl01-bootstrap.service
    permissions: "0644"
    content: |
      [Unit]
      Description=HybridOps ctrl-01 Day-1 bootstrap

      [Service]
      Type=oneshot
      Environment=ENABLE_FULL_BOOTSTRAP=${ENABLE_FULL_BOOTSTRAP}
      Environment=ENABLE_JENKINS=${ENABLE_JENKINS}
      Environment=ENABLE_AUTO_HARDEN=${ENABLE_AUTO_HARDEN}
      Environment=CIUSER=${CIUSER}
      ExecStart=/usr/local/sbin/ctrl01-bootstrap
      RemainAfterExit=yes

  - path: /etc/systemd/system/ctrl01-bootstrap.timer
    permissions: "0644"
    content: |
      [Unit]
      Description=Delay then run Day-1 bootstrap

      [Timer]
      OnBootSec=${BOOTSTRAP_DELAY_SEC}
      AccuracySec=5s
      Unit=ctrl01-bootstrap.service

      [Install]
      WantedBy=timers.target

runcmd:
  - sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  - systemctl restart ssh || systemctl restart sshd
  - systemctl daemon-reload
  - systemctl enable --now serial-getty@ttyS0.service
  - systemctl enable --now ctrl01-bootstrap.timer
EOF

# Recreate VM cleanly
qm stop "$VMID" >/dev/null 2>&1 || true
qm destroy "$VMID" --purge >/dev/null 2>&1 || true

# Create VM
qm create "$VMID" --name "$VMNAME" --memory 4096 --cores 2 --cpu host \
  --net0 virtio,bridge="$BRIDGE" --agent 1 --scsihw virtio-scsi-pci --ostype l26
qm importdisk "$VMID" "$IMG" "$DISKSTORE"
qm set "$VMID" --scsi0 "$DISKSTORE:vm-$VMID-disk-0" --boot c --bootdisk scsi0
qm set "$VMID" --ide2 "$DISKSTORE:cloudinit"
qm set "$VMID" --serial0 socket --vga qxl

# Enlarge disk for real workloads (adds ~28G → ~30G total typical)
qm disk resize "$VMID" scsi0 +28G

# Built‑in cloud‑init flags (visible Day‑0 password + static IP + DNS)
qm set "$VMID" --ciuser "$CIUSER" --cipassword "$CIPASS"
qm set "$VMID" --ipconfig0 "ip=$IPCIDR,gw=$GATEWAY"
qm set "$VMID" --nameserver "$DNS1"

# Use our custom user-data
qm set "$VMID" --cicustom "user=$SNIPSTORE:snippets/$(basename "$SNIP")"

# Materialize cloud‑init and boot
qm cloudinit update "$VMID"
qm start "$VMID"

set +x
echo
echo "==================== ctrl-01 Ubuntu Day0→Day1 ===================="
echo " VM:                 ${VMNAME} (ID ${VMID})"
echo " IP:                 ${IPCIDR%%/*} (GW ${GATEWAY})"
echo " Login (pwd):        ssh ${CIUSER}@${IPCIDR%%/*}  (pass: ${CIPASS})"
echo " Login (key):        embedded from: ${PUBKEY_FILES[*]}"
echo " Disk size:          ~30G (auto-grown in guest)"
echo " Day-1 trigger:      ctrl01-bootstrap.timer (after ${BOOTSTRAP_DELAY_SEC}s)"
echo " Day-1 logs:         /var/log/ctrl01_bootstrap.log"
echo " Status JSON:        /var/lib/ctrl01/status.json"
echo " Repo:               ${REPO_URL} @ ${REPO_BRANCH} -> ${REPO_DIR}"
echo " Auto-hardening:     ${ENABLE_AUTO_HARDEN} (grace ${HARDEN_GRACE_MIN}m)"
echo " Jenkins install:    ${ENABLE_JENKINS}"
echo " Tools install:      ${ENABLE_FULL_BOOTSTRAP}"
echo " ADR linkage:        ADR-0012 Control node as VM"
echo "==============================================================="
