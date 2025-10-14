#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# HybridOps Studio — ctrl‑01 Day‑1 bootstrap
# Installs core tooling, clones the repo, optional Jenkins, and collects evidence.
# Designed to be fetched/exec'd by Day‑0 fetcher.
# -----------------------------------------------------------------------------
set -Eeuo pipefail
LOG=/var/log/ctrl01_bootstrap.log
exec > >(tee -a "$LOG") 2>&1
echo "[bootstrap] start $(date -Is)"
export LC_ALL=C LANG=C

# ---------- Tunables via environment (have sane defaults) ----------
CIUSER=${CIUSER:-admin}
ENABLE_FULL_BOOTSTRAP=${ENABLE_FULL_BOOTSTRAP:-true}
ENABLE_JENKINS=${ENABLE_JENKINS:-true}
ENABLE_AUTO_HARDEN=${ENABLE_AUTO_HARDEN:-true}
HARDEN_GRACE_MIN=${HARDEN_GRACE_MIN:-10}

REPO_URL=${REPO_URL:-https://github.com/jeleel-muibi/hybridops.studio}
REPO_BRANCH=${REPO_BRANCH:-main}
REPO_DIR=${REPO_DIR:-/srv/hybridops}

# Evidence dir
TS=$(date -u +%Y%m%dT%H%M%SZ)
EV_BASE=${EV_BASE:-/srv/hybridops/output/artifacts/ctrl01}
EV_DIR="$EV_BASE/$TS"
install -d -m 0755 "$EV_DIR"

retry() { local n=1; local tries="$1"; local sleep_s="$2"; shift 2;
  until "$@"; do
    if [ $n -ge "$tries" ]; then echo "RETRY: giving up after $n: $*"; return 1; fi
    echo "RETRY: $n/$tries failed: $* ; sleeping ${sleep_s}s"; sleep "$sleep_s"; n=$((n+1))
  done
}

# Prefer IPv4
grep -q '::ffff:0:0/96' /etc/gai.conf 2>/dev/null || echo 'precedence ::ffff:0:0/96  100' | sudo tee -a /etc/gai.conf >/dev/null

# Basic network/dpkg sanity
rm -rf /var/lib/apt/lists/* || true
apt-get clean || true
dpkg --configure -a || true

# Network readiness
retry 20 3 bash -lc 'ping -c1 -W1 8.8.8.8 >/dev/null 2>&1'
retry 20 3 bash -lc 'getent hosts archive.ubuntu.com >/dev/null 2>&1'

# Grow root if needed
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
retry 8 5 bash -lc 'DEBIAN_FRONTEND=noninteractive apt-get update -o Acquire::ForceIPv4=true | tee '"$EV_DIR"'/10_apt_update.txt'
retry 8 5 bash -lc 'DEBIAN_FRONTEND=noninteractive apt-get -y install qemu-guest-agent curl git jq unzip wget tar ca-certificates make python3-pip ufw | tee -a '"$EV_DIR"'/10_apt_update.txt'
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

  retry 8 10 bash -lc 'DEBIAN_FRONTEND=noninteractive apt-get update -o Acquire::ForceIPv4=true | tee -a '"$EV_DIR"'/10_apt_update.txt'
  PKGS="terraform packer kubectl ansible fontconfig openjdk-17-jre-headless"
  if [ "${ENABLE_JENKINS}" = "true" ]; then PKGS="$PKGS jenkins"; fi
  retry 8 10 bash -lc 'DEBIAN_FRONTEND=noninteractive apt-get -y install '"$PKGS"' | tee '"$EV_DIR"'/20_tool_install.txt'

  # Helm (script installer)
  if ! command -v helm >/dev/null 2>&1; then
    retry 5 10 bash -lc 'curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash | tee '"$EV_DIR"'/21_helm_install.txt'
  fi

  # Firewall (SSH + Jenkins if installed)
  ufw allow 22/tcp || true
  [ "${ENABLE_JENKINS}" = "true" ] && ufw allow 8080/tcp || true
  yes | ufw enable || true
fi

# Clone/update repo
install -d -m 0755 "$(dirname "$REPO_DIR")"
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "[bootstrap] cloning repo $REPO_URL -> $REPO_DIR (branch $REPO_BRANCH)"
  retry 6 10 git clone --branch "$REPO_BRANCH" --depth 1 "$REPO_URL" "$REPO_DIR" | tee "$EV_DIR/30_repo_clone.txt"
else
  echo "[bootstrap] updating repo $REPO_DIR"
  git -C "$REPO_DIR" fetch --depth 1 origin "$REPO_BRANCH" || true
  git -C "$REPO_DIR" checkout "$REPO_BRANCH" || true
  git -C "$REPO_DIR" pull --ff-only || true
fi

# Tool versions
{
  echo "==== versions @ $(date -Is) ===="
  terraform -v || true
  packer -v || true
  kubectl version --client --output=yaml || true
  helm version || true
  ansible --version || true
} | tee "$EV_DIR/40_tool_versions.txt"

# Jenkins status/evidence
if [ "${ENABLE_JENKINS}" = "true" ]; then
  systemctl enable --now jenkins || true
  sleep 2
  {
    systemctl status jenkins --no-pager || true
    ss -lntp | grep :8080 || true
    test -f /var/lib/jenkins/secrets/initialAdminPassword && echo "INITIAL_PASS: $(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)"
  } | tee "$EV_DIR/50_jenkins_status.txt"
fi

# Extra captures
ip a | tee "$EV_DIR/00_ip_addr.txt"
df -h | tee "$EV_DIR/00_df.txt"
tail -n 200 /var/log/cloud-init-output.log 2>/dev/null | tee "$EV_DIR/60_cloudinit_tail.txt" || true

# Status JSON (include evidence_dir)
install -d -m 0755 /var/lib/ctrl01
IP="$(hostname -I | awk '{print $1}')"
JENK="http://$IP:8080"
jq -n \
  --arg status "ok" \
  --arg ip "$IP" \
  --arg jenkins "$JENK" \
  --arg ts "$(date -Is)" \
  --arg bootstrap "$ENABLE_FULL_BOOTSTRAP" \
  --arg repo "${REPO_URL}@${REPO_BRANCH}" \
  --arg evidence_dir "$EV_DIR" \
  '{status:$status, ip:$ip, jenkins:$jenkins, ts:$ts, bootstrap:$bootstrap, repo:$repo, evidence_dir:$evidence_dir}' \
  | tee /var/lib/ctrl01/status.json >/dev/null

echo "[bootstrap] base converge done $(date -Is)"

# Adaptive hardening
if [ "${ENABLE_AUTO_HARDEN}" = "true" ]; then
  echo "[bootstrap] adaptive hardening: grace ${HARDEN_GRACE_MIN}m"
  sleep "$(( HARDEN_GRACE_MIN * 60 ))"
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

echo "[bootstrap] done $(date -Is)"
