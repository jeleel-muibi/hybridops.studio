#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# HybridOps Studio — Day-1 Bootstrap for ctrl-01 (Jenkins Controller)
# -----------------------------------------------------------------------------
# Purpose:
#   Installs Jenkins, applies controller-init Groovy scripts, and prepares
#   the controller for Git-driven CI/CD. Cleans sensitive secrets on success.
# -----------------------------------------------------------------------------

set -Eeuo pipefail
LOG=/var/log/ctrl01_bootstrap.log
exec > >(tee -a "$LOG") 2>&1
echo "[bootstrap] start $(date -Is)"

# --- Parameters ---------------------------------------------------------------
CIUSER=${CIUSER:-hybridops}
JENKINS_ADMIN_USER=${JENKINS_ADMIN_USER:-admin}
JENKINS_SEED_REPO=${JENKINS_SEED_REPO:-https://github.com/jeleel-muibi/hybridops.studio}
JENKINS_SEED_BRANCH=${JENKINS_SEED_BRANCH:-main}
ENABLE_AUTO_HARDEN=${ENABLE_AUTO_HARDEN:-true}
HARDEN_GRACE_MIN=${HARDEN_GRACE_MIN:-10}

# --- Verify Jenkins admin password --------------------------------------------
if [ -z "${JENKINS_ADMIN_PASS:-}" ]; then
  echo "[bootstrap] ERROR: JENKINS_ADMIN_PASS not found in environment." >&2
  exit 1
fi

# --- Paths --------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
INIT_SRC="${REPO_ROOT}/control/tools/jenkins/controller-init"
INIT_DST="/var/lib/jenkins/init.groovy.d"

# --- Helper: retry ------------------------------------------------------------
retry() {
  local tries="${1:-8}" delay="${2:-5}"
  shift 2
  local n=1
  until "$@"; do
    ((n++>=tries)) && { echo "[retry] failed: $*"; return 1; }
    echo "[retry] attempt $n/$tries"
    sleep "$delay"
  done
}

# --- Add official Jenkins repository ------------------------------------------
echo "[bootstrap] adding Jenkins repository..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc >/dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  > /etc/apt/sources.list.d/jenkins.list

# --- Install Jenkins and dependencies ----------------------------------------
retry 10 5 apt-get update -o Acquire::ForceIPv4=true
retry 6 5 apt-get install -y qemu-guest-agent curl git jq unzip ca-certificates \
  openjdk-17-jre-headless make ufw jenkins

systemctl enable --now qemu-guest-agent jenkins
ufw allow 22/tcp 8080/tcp && yes | ufw enable || true
retry 40 3 bash -lc 'ss -lnt | grep -q ":8080"'

# --- Import controller-init Groovy scripts -----------------------------------
echo "[bootstrap] importing controller-init from ${INIT_SRC}"
install -d -m 0755 "${INIT_DST}"
if [ -d "${INIT_SRC}" ]; then
  cp -r "${INIT_SRC}/"* "${INIT_DST}/"
  chown -R jenkins:jenkins "${INIT_DST}"
else
  echo "[bootstrap] ERROR: controller-init not found at ${INIT_SRC}" >&2
  exit 1
fi

systemctl restart jenkins
retry 40 3 bash -lc 'ss -lnt | grep -q ":8080"'

# --- Evidence snapshot --------------------------------------------------------
IP="$(hostname -I | awk '{print $1}')"
mkdir -p /var/lib/ctrl01
cat > /var/lib/ctrl01/status.json <<JSON
{
  "status": "ok",
  "ip": "${IP}",
  "jenkins": "http://${IP}:8080",
  "ts": "$(date -Is)"
}
JSON

# --- Clean ephemeral password file -------------------------------------------
if [ -f /etc/profile.d/jenkins_env.sh ]; then
  echo "[bootstrap] cleaning ephemeral admin secret..."
  shred -u /etc/profile.d/jenkins_env.sh 2>/dev/null || rm -f /etc/profile.d/jenkins_env.sh
fi

# --- Optional SSH hardening ---------------------------------------------------
if [ "${ENABLE_AUTO_HARDEN}" = "true" ]; then
  echo "[bootstrap] scheduling SSH hardening in ${HARDEN_GRACE_MIN}m"
  sleep "$((HARDEN_GRACE_MIN*60))"
  AUTH="/home/${CIUSER}/.ssh/authorized_keys"
  if [ -s "$AUTH" ]; then
    mkdir -p /etc/ssh/sshd_config.d
    cat >/etc/ssh/sshd_config.d/99-password-off.conf <<'CONF'
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
CONF
    systemctl reload ssh || systemctl reload sshd
    echo "[bootstrap] SSH password authentication disabled."
  fi
fi

echo "[bootstrap] complete $(date -Is)"
