#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# HybridOps Studio: ctrl-01 Day‑1 Bootstrap (Configuration)
# -----------------------------------------------------------------------------
# PURPOSE
#   • Day‑1 (inside VM): Install core tooling (Terraform, Packer, kubectl,
#     Helm, Ansible, Jenkins), configure services, and apply adaptive hardening.
#
# OPERATIONAL SHAPE
#   • This script is stored in source control and executed from within the VM
#   • Triggered by systemd timer after Day-0 VM provisioning completes
# -----------------------------------------------------------------------------

set -Eeuo pipefail

# Environment variables with defaults (can be overridden when calling script)
ENABLE_FULL_BOOTSTRAP=${ENABLE_FULL_BOOTSTRAP:-true}   # install the full toolchain
ENABLE_JENKINS=${ENABLE_JENKINS:-true}                 # install & start Jenkins
ENABLE_AUTO_HARDEN=${ENABLE_AUTO_HARDEN:-true}         # disable password auth if a key exists
HARDEN_GRACE_MIN=${HARDEN_GRACE_MIN:-10}               # minutes to wait before hardening
CIUSER=${CIUSER:-ubuntu}                               # should match Day-0 user

# Get our bearings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../" &>/dev/null && pwd)"
echo "[bootstrap] Starting Day-1 process from ${SCRIPT_DIR} (repo: ${REPO_ROOT})"

# Networking resilience
retry() {
  local n=1; local tries="$1"; local sleep_s="$2"; shift 2;
  until "$@"; do
    if [ $n -ge "$tries" ]; then echo "RETRY: giving up after $n: $*"; return 1; fi
    echo "RETRY: $n/$tries failed: $* ; sleeping ${sleep_s}s"; sleep "$sleep_s"; n=$((n+1))
  done
}

# Prefer IPv4 for flaky links
grep -q '::ffff:0:0/96' /etc/gai.conf 2>/dev/null || echo 'precedence ::ffff:0:0/96  100' | sudo tee -a /etc/gai.conf >/dev/null

# Ensure dpkg/apt are sane and caches are minimal
rm -rf /var/lib/apt/lists/* || true
apt-get clean || true
dpkg --configure -a || true

# Network readiness
retry 20 3 bash -lc 'ping -c1 -W1 8.8.8.8 >/dev/null 2>&1'
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

if [ "${ENABLE_FULL_BOOTSTRAP}" = "true" ]; then
  echo "[bootstrap] installing toolchain"

  # HashiCorp (terraform/packer)
  . /etc/os-release
  curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $VERSION_CODENAME main" | tee /etc/apt/sources.list.d/hashicorp.list >/dev/null

  # Kubernetes (kubectl)
  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor | tee /usr/share/keyrings/kubernetes-archive-keyring.gpg >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list >/dev/null

  # Jenkins (optional)
  if [ "${ENABLE_JENKINS}" = "true" ]; then
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | gpg --dearmor | tee /usr/share/keyrings/jenkins-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list >/dev/null
  fi

  retry 8 5 bash -lc 'DEBIAN_FRONTEND=noninteractive apt-get update -o Acquire::ForceIPv4=true'
  PKGS="terraform packer kubectl ansible fontconfig openjdk-17-jre-headless"
  if [ "${ENABLE_JENKINS}" = "true" ]; then PKGS="$PKGS jenkins"; fi
  retry 6 5 bash -lc "DEBIAN_FRONTEND=noninteractive apt-get -y install $PKGS"

  # Helm via official script (fallback)
  if ! command -v helm >/dev/null 2>&1; then
    retry 5 5 bash -lc 'curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash'
  fi

  # Firewall (SSH + Jenkins if installed)
  ufw allow 22/tcp || true
  [ "${ENABLE_JENKINS}" = "true" ] && ufw allow 8080/tcp || true
  yes | ufw enable || true

  [ "${ENABLE_JENKINS}" = "true" ] && systemctl enable --now jenkins || true
fi

# Status artifact
install -d -m 0755 /var/lib/ctrl01
IP="$(hostname -I | awk '{print $1}')"
jq -n \
  --arg status "ok" \
  --arg ip "$IP" \
  --arg jenkins "http://$IP:8080" \
  --arg ts "$(date -Is)" \
  --arg bootstrap "${ENABLE_FULL_BOOTSTRAP}" \
  --arg repo "${REPO_ROOT}" \
  '{status:$status, ip:$ip, jenkins:$jenkins, ts:$ts, bootstrap:$bootstrap, repo:$repo}' \
  | tee /var/lib/ctrl01/status.json

echo "[bootstrap] base converge done $(date -Is)"

if [ "${ENABLE_AUTO_HARDEN}" = "true" ]; then
  echo "[bootstrap] adaptive hardening: grace ${HARDEN_GRACE_MIN}m"
  sleep "$((HARDEN_GRACE_MIN * 60))"
  AUTH="/home/${CIUSER}/.ssh/authorized_keys"
  if [ -s "$AUTH" ]; then
    echo "[bootstrap] key detected, disabling password auth"
    mkdir -p /etc/ssh/sshd_config.d
    printf '%s\n' "PasswordAuthentication no" "KbdInteractiveAuthentication no" "ChallengeResponseAuthentication no" "UsePAM yes" > /etc/ssh/sshd_config.d/99-password-off.conf
    systemctl reload ssh || systemctl reload sshd || true
    echo "${CIUSER}:Expired-$(date +%s)!" | chpasswd || true
  else
    echo "[bootstrap] no key found; leaving password auth enabled"
  fi
fi

# Optional: Run any additional repo-specific initialization tasks here
if [ -f "${REPO_ROOT}/control/tools/provision/init/ctrl01-init.sh" ]; then
  echo "[bootstrap] Running project initialization script"
  bash "${REPO_ROOT}/control/tools/provision/init/ctrl01-init.sh"
fi

echo "[bootstrap] Day-1 process completed at $(date -Is)"

# Run evidence collection script if it exists (same directory)
EVIDENCE_SCRIPT="${SCRIPT_DIR}/ctrl01-collect-evidence.sh"
if [ -f "$EVIDENCE_SCRIPT" ]; then
  echo "[bootstrap] Running evidence collection script"
  chmod +x "$EVIDENCE_SCRIPT"
  CURRENT_DATE="2025-10-14 20:02:06" CURRENT_USER="jeleel-muibi" bash "$EVIDENCE_SCRIPT"
fi
