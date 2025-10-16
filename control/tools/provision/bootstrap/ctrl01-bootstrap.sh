#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# HybridOps Studio — Day-1 Bootstrap for ctrl-01 (Jenkins Controller)
# -----------------------------------------------------------------------------
# Purpose:
#   Installs Jenkins, imports controller-init Groovy scripts, and prepares
#   the controller for Git-driven CI/CD. Requires JENKINS_ADMIN_PASS from
#   environment (set by Day-0 cloud-init).
#
# Design:
#   - Executes automatically via systemd timer on first boot.
#   - Configures Jenkins non-interactively from Git.
#   - Writes structured audit evidence and enforces SSH hardening.
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

# --- Credential check ---------------------------------------------------------
if [ -z "${JENKINS_ADMIN_PASS:-}" ]; then
  echo "[bootstrap] ERROR: JENKINS_ADMIN_PASS not provided." >&2
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
    echo "[retry] attempt $n/$tries"; sleep "$delay"
  done
}

# --- Jenkins repository + install --------------------------------------------
echo "[bootstrap] adding Jenkins APT repository"
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc >/dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/" \
  | tee /etc/apt/sources.list.d/jenkins.list >/dev/null

retry 10 5 apt-get update -o Acquire::ForceIPv4=true
retry 6 5 apt-get install -y qemu-guest-agent curl git jq unzip ca-certificates \
  openjdk-17-jre-headless make ufw jenkins

systemctl enable --now qemu-guest-agent jenkins

# --- Firewall + readiness -----------------------------------------------------
ufw allow 22/tcp 8080/tcp && yes | ufw enable || true
retry 40 3 bash -lc 'ss -lnt | grep -q ":8080"'

# --- Controller init scripts --------------------------------------------------
echo "[bootstrap] importing controller-init scripts"
install -d -m 0755 "${INIT_DST}"
cp -r "${INIT_SRC}/"* "${INIT_DST}/" || {
  echo "[bootstrap] ERROR: controller-init directory missing at ${INIT_SRC}" >&2
  exit 1
}
chown -R jenkins:jenkins "${INIT_DST}"

systemctl restart jenkins
retry 40 3 bash -lc 'ss -lnt | grep -q ":8080"'

# --- Evidence ---------------------------------------------------------------
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

# --- SSH Hardening ------------------------------------------------------------
if [ "${ENABLE_AUTO_HARDEN}" = "true" ]; then
  echo "[bootstrap] hardening SSH after ${HARDEN_GRACE_MIN}m"
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
