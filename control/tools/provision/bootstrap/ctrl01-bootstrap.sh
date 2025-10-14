#!/usr/bin/env bash
# HybridOps — ctrl01 Day‑1 bootstrap (to live in repo at control/tools/provision/bootstrap/ctrl01-bootstrap.sh)
set -Eeuo pipefail

LOG=/var/log/ctrl01_bootstrap.log
exec > >(tee -a "$LOG") 2>&1
echo "[day1] start $(date -Is)"
export LC_ALL=C LANG=C

ENABLE_FULL_BOOTSTRAP=${ENABLE_FULL_BOOTSTRAP:-true}
ENABLE_JENKINS=${ENABLE_JENKINS:-true}
ENABLE_AUTO_HARDEN=${ENABLE_AUTO_HARDEN:-true}
HARDEN_GRACE_MIN=${HARDEN_GRACE_MIN:-10}
CIUSER=${CIUSER:-admin}

REPO_URL=${REPO_URL:-https://github.com/jeleel-muibi/hybridops.studio}
REPO_BRANCH=${REPO_BRANCH:-main}
REPO_DIR=${REPO_DIR:-/srv/hybridops}

TS="$(date -u +%Y%m%dT%H%M%SZ)"
EV_DIR="/srv/hybridops/output/artifacts/ctrl01/${TS}"
mkdir -p "${EV_DIR}" || true

capture() { local _fname="$1"; shift; { echo "$ $*"; "$@"; } > "${EV_DIR}/${_fname}" 2>&1 || true; }

grep -q '::ffff:0:0/96' /etc/gai.conf 2>/dev/null || echo 'precedence ::ffff:0:0/96  100' | tee -a /etc/gai.conf >/dev/null
rm -rf /var/lib/apt/lists/* || true
apt-get clean || true
dpkg --configure -a || true

retry() { local n=1; local tries="$1"; local sleep_s="$2"; shift 2;
  until "$@"; do
    if [ $n -ge "$tries" ]; then echo "RETRY: giving up after $n: $*"; return 1; fi
    echo "RETRY: $n/$tries failed: $* ; sleeping ${sleep_s}s"; sleep "$sleep_s"; n=$((n+1))
  done
}

retry 20 3 bash -lc 'ping -c1 -W1 8.8.8.8 >/dev/null 2>&1'
retry 20 3 bash -lc 'getent hosts archive.ubuntu.com >/dev/null 2>&1'

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
capture 00_system_facts.txt -- bash -lc 'uname -a; cat /etc/os-release; lsblk; df -hT'

retry 8 5 bash -lc 'DEBIAN_FRONTEND=noninteractive apt-get update -o Acquire::ForceIPv4=true'
retry 8 5 bash -lc 'DEBIAN_FRONTEND=noninteractive apt-get -y install qemu-guest-agent curl git jq unzip wget tar ca-certificates make python3-pip ufw'
systemctl enable --now qemu-guest-agent || true

if [ "${ENABLE_FULL_BOOTSTRAP}" = "true" ]; then
  . /etc/os-release
  curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $VERSION_CODENAME main" | tee /etc/apt/sources.list.d/hashicorp.list >/dev/null

  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor | tee /usr/share/keyrings/kubernetes-archive-keyring.gpg >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list >/dev/null

  if [ "${ENABLE_JENKINS}" = "true" ]; then
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | gpg --dearmor | tee /usr/share/keyrings/jenkins-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list >/dev/null
  fi

  retry 8 5 bash -lc 'DEBIAN_FRONTEND=noninteractive apt-get update -o Acquire::ForceIPv4=true'
  PKGS="terraform packer kubectl ansible fontconfig openjdk-17-jre-headless"
  if [ "${ENABLE_JENKINS}" = "true" ]; then PKGS="$PKGS jenkins"; fi
  retry 6 5 bash -lc "DEBIAN_FRONTEND=noninteractive apt-get -y install $PKGS"

  if ! command -v helm >/dev/null 2>&1; then
    retry 5 5 bash -lc 'curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash'
  fi

  ufw allow 22/tcp || true
  [ "${ENABLE_JENKINS}" = "true" ] && ufw allow 8080/tcp || true
  yes | ufw enable || true

  [ "${ENABLE_JENKINS}" = "true" ] && systemctl enable --now jenkins || true
fi

install -d -m 0755 "${REPO_DIR%/*}"
if [ ! -d "${REPO_DIR}/.git" ]; then
  echo "[day1] cloning repo ${REPO_URL} -> ${REPO_DIR} (branch ${REPO_BRANCH})"
  retry 6 5 git clone --branch "${REPO_BRANCH}" --depth 1 "${REPO_URL}" "${REPO_DIR}"
else
  echo "[day1] updating repo ${REPO_DIR}"
  git -C "${REPO_DIR}" fetch --depth 1 origin "${REPO_BRANCH}" || true
  git -C "${REPO_DIR}" checkout "${REPO_BRANCH}" || true
  git -C "${REPO_DIR}" pull --ff-only || true
fi

capture 20_tool_versions.txt -- terraform -v
capture 20_tool_versions.txt -- packer -v
capture 20_tool_versions.txt -- kubectl version --client=true --output=yaml
capture 20_tool_versions.txt -- helm version
capture 20_tool_versions.txt -- ansible --version

if [ "${ENABLE_JENKINS}" = "true" ]; then
  capture 30_jenkins_status.txt -- bash -lc 'systemctl status jenkins --no-pager; ss -lntp | grep :8080 || true; test -f /var/lib/jenkins/secrets/initialAdminPassword && cat /var/lib/jenkins/secrets/initialAdminPassword || true'
fi

capture 40_ufw_status.txt -- ufw status verbose
capture 50_cloudinit_tail.txt -- tail -n 200 /var/log/cloud-init-output.log

IP="$(hostname -I | awk '{print $1}')"
cat > "${EV_DIR}/index.json" <<JSON
{
  "ts": "${TS}",
  "node": "$(hostname)",
  "ip": "${IP}",
  "repo": "${REPO_URL}@${REPO_BRANCH}",
  "files": [
    "00_system_facts.txt",
    "20_tool_versions.txt",
    "30_jenkins_status.txt",
    "40_ufw_status.txt",
    "50_cloudinit_tail.txt"
  ]
}
JSON

install -d -m 0755 /var/lib/ctrl01
printf '{"status":"ok","ip":"%s","jenkins":"http://%s:8080","ts":"%s","bootstrap":"%s","repo":"%s@%s","evidence_dir":"%s"}
'   "$IP" "$IP" "$(date -Is)" "${ENABLE_FULL_BOOTSTRAP}" "${REPO_URL}" "${REPO_BRANCH}" "${EV_DIR}"   > /var/lib/ctrl01/status.json

echo "[day1] adaptive hardening: ${ENABLE_AUTO_HARDEN} (grace ${HARDEN_GRACE_MIN}m)"
if [ "${ENABLE_AUTO_HARDEN}" = "true" ]; then
  sleep "$(( HARDEN_GRACE_MIN * 60 ))"
  AUTH="/home/${CIUSER}/.ssh/authorized_keys"
  if [ -s "$AUTH" ]; then
    echo "[day1] key detected, disabling password auth"
    mkdir -p /etc/ssh/sshd_config.d
    printf '%s
' "PasswordAuthentication no" "KbdInteractiveAuthentication no" "ChallengeResponseAuthentication no" "UsePAM yes" > /etc/ssh/sshd_config.d/99-password-off.conf
    systemctl reload ssh || systemctl reload sshd || true
    echo '${CIUSER}:Expired-'$(date +%s)'!' | chpasswd || true
  else
    echo "[day1] no key found; leaving password auth enabled"
  fi
fi

echo "[day1] done $(date -Is)"
