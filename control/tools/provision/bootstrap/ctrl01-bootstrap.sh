#!/usr/bin/env bash
set -Eeuo pipefail

# -------- Config via env (populated by systemd unit in Day-0) ----------
: "${ENABLE_FULL_BOOTSTRAP:=true}"
: "${ENABLE_JENKINS:=true}"
: "${ENABLE_AUTO_HARDEN:=true}"
: "${CIUSER:=ubuntu}"
: "${HARDEN_GRACE_MIN:=10}"
: "${DNS1:=8.8.8.8}"

REPO_URL="${REPO_URL:-https://github.com/jeleel-muibi/hybridops.studio}"
REPO_BRANCH="${REPO_BRANCH:-main}"
REPO_DIR="${REPO_DIR:-/srv/hybridops}"

LOG=/var/log/ctrl01_bootstrap.log
exec > >(tee -a "$LOG") 2>&1
echo "[bootstrap] ctrl01 start $(date -Is)"
export LC_ALL=C LANG=C

# -------- Helpers -------------------------------------------------------
retry() { local n=1; local tries="$1"; local sleep_s="$2"; shift 2;
  until "$@"; do
    if [ $n -ge "$tries" ]; then echo "RETRY: giving up after $n: $*"; return 1; fi
    echo "RETRY: $n/$tries failed: $* ; sleeping ${sleep_s}s"; sleep "$sleep_s"; n=$((n+1))
  done
}

EV_DIR="/srv/hybridops/output/artifacts/ctrl01/$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$EV_DIR"

capture() {
  local _f="$1"; shift
  # ignore optional "--" separator from callers
  while [ "${1-}" = "--" ]; do shift; done
  { echo "$ $*"; "$@"; echo; } >> "${EV_DIR}/${_f}" 2>&1 || true
}

status_json() {
  local ip
  ip="$(hostname -I | awk '{print $1}')"
  mkdir -p /var/lib/ctrl01
  jq -n \
    --arg status "ok" \
    --arg ip "$ip" \
    --arg jenkins "http://$ip:8080" \
    --arg ts "$(date -Is)" \
    --arg bootstrap "${ENABLE_FULL_BOOTSTRAP}" \
    --arg repo "${REPO_URL}@${REPO_BRANCH}" \
    --arg evidence_dir "$EV_DIR" \
    '{status:$status, ip:$ip, jenkins:$jenkins, ts:$ts, bootstrap:$bootstrap, repo:$repo, evidence_dir:$evidence_dir}' \
    > /var/lib/ctrl01/status.json
}

# -------- Network & apt sanity -----------------------------------------
grep -q '::ffff:0:0/96' /etc/gai.conf 2>/dev/null || echo 'precedence ::ffff:0:0/96  100' | tee -a /etc/gai.conf >/dev/null
rm -rf /var/lib/apt/lists/* || true
apt-get clean || true
dpkg --configure -a || true

retry 20 3 bash -lc "ping -c1 -W1 ${DNS1} >/dev/null 2>&1"
retry 20 3 bash -lc 'getent hosts archive.ubuntu.com >/dev/null 2>&1'

# -------- Grow root if applicable --------------------------------------
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

# -------- Base tools & agent -------------------------------------------
retry 8 5 bash -lc 'DEBIAN_FRONTEND=noninteractive apt-get update -o Acquire::ForceIPv4=true'
retry 8 5 bash -lc 'DEBIAN_FRONTEND=noninteractive apt-get -y install qemu-guest-agent curl git jq unzip wget tar ca-certificates make python3-pip ufw'
systemctl enable --now qemu-guest-agent || true

# -------- Toolchain (optional) -----------------------------------------
if [ "${ENABLE_FULL_BOOTSTRAP}" = "true" ]; then
  echo "[bootstrap] installing toolchain"

  . /etc/os-release
  curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $VERSION_CODENAME main" \
    | tee /etc/apt/sources.list.d/hashicorp.list >/dev/null

  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor | tee /usr/share/keyrings/kubernetes-archive-keyring.gpg >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" \
    | tee /etc/apt/sources.list.d/kubernetes.list >/dev/null

  if [ "${ENABLE_JENKINS}" = "true" ]; then
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | gpg --dearmor | tee /usr/share/keyrings/jenkins-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" \
      | tee /etc/apt/sources.list.d/jenkins.list >/dev/null
  fi

  retry 8 5 bash -lc 'DEBIAN_FRONTEND=noninteractive apt-get update -o Acquire::ForceIPv4=true'
  PKGS="terraform packer kubectl ansible fontconfig openjdk-17-jre-headless"
  [ "${ENABLE_JENKINS}" = "true" ] && PKGS="$PKGS jenkins"
  retry 6 5 bash -lc "DEBIAN_FRONTEND=noninteractive apt-get -y install $PKGS"

  # Helm via official script (fallback)
  if ! command -v helm >/dev/null 2>&1; then
    retry 5 5 bash -lc 'curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash'
  fi

  ufw allow 22/tcp || true
  [ "${ENABLE_JENKINS}" = "true" ] && ufw allow 8080/tcp || true
  yes | ufw enable || true

  [ "${ENABLE_JENKINS}" = "true" ] && systemctl enable --now jenkins || true
fi

# -------- Evidence ------------------------------------------------------
capture 00_system_facts.txt -- bash -lc 'uname -a; (lsb_release -a || cat /etc/os-release); df -h; free -m'
capture 20_tool_versions.txt -- bash -lc 'terraform -v; packer -v; kubectl version --client --output=yaml; helm version || true; ansible --version || true'
capture 50_cloudinit_tail.txt -- bash -lc 'journalctl -u cloud-init -n 200 --no-pager || tail -n 200 /var/log/cloud-init-output.log'

# -------- Status JSON ---------------------------------------------------
status_json
echo "[bootstrap] base converge done $(date -Is)"

# -------- Adaptive hardening -------------------------------------------
if [ "${ENABLE_AUTO_HARDEN}" = "true" ]; then
  echo "[bootstrap] adaptive hardening: grace ${HARDEN_GRACE_MIN}m"
  sleep "$(( HARDEN_GRACE_MIN * 60 ))"
  AUTH="/home/${CIUSER}/.ssh/authorized_keys"
  if [ -s "$AUTH" ]; then
    echo "[bootstrap] key detected, disabling password auth"
    mkdir -p /etc/ssh/sshd_config.d
    printf '%s\n' "PasswordAuthentication no" "KbdInteractiveAuthentication no" "ChallengeResponseAuthentication no" "UsePAM yes" \
      > /etc/ssh/sshd_config.d/99-password-off.conf
    systemctl reload ssh || systemctl reload sshd || true
    echo "${CIUSER}:Expired-$(date +%s)!" | chpasswd || true
  else
    echo "[bootstrap] no key found; leaving password auth enabled"
  fi
fi

echo "[bootstrap] done $(date -Is)"
