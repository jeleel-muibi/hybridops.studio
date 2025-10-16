#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# HybridOps Studio — Day-1 Bootstrap for ctrl-01 (Jenkins Controller)
# -----------------------------------------------------------------------------
# Author: Jeleel Muibi
#
# Description:
#   Automated Day-1 configuration for the Jenkins control-plane (ctrl-01).
#   Installs Jenkins, applies controller-init Groovy scripts, and finalizes
#   readiness for Git-driven CI/CD. Runs once at first boot via systemd.
#
# Design intent:
#   • Executed headlessly by Day-0 cloud-init timer.
#   • Ensures deterministic Jenkins setup via versioned Groovy scripts.
#   • Cleans ephemeral secrets after initialization.
#   • Automatically generates Day-1 evidence artifacts.
#   • Disables SSH password logins after a short grace period.
#
# Debugging:
#   sudo tail -f /var/log/ctrl01_bootstrap.log
# -----------------------------------------------------------------------------

set -Eeuo pipefail
LOG=/var/log/ctrl01_bootstrap.log
LOCK_FILE=/var/lib/ctrl01/bootstrap.lock

# Only set up output redirection if this script was called directly
# (not from the launcher which already redirected output)
if [ -z "${NO_OUTPUT_REDIRECT:-}" ]; then
  exec > >(tee -a "$LOG") 2>&1
fi

echo "[bootstrap] start $(date -Is)"

# --- Runtime parameters -------------------------------------------------------
CIUSER=${CIUSER:-hybridops}
JENKINS_ADMIN_USER=${JENKINS_ADMIN_USER:-admin}
JENKINS_SEED_REPO=${JENKINS_SEED_REPO:-https://github.com/jeleel-muibi/hybridops.studio}
JENKINS_SEED_BRANCH=${JENKINS_SEED_BRANCH:-main}
ENABLE_AUTO_HARDEN=${ENABLE_AUTO_HARDEN:-true}
HARDEN_GRACE_MIN=${HARDEN_GRACE_MIN:-1}

# --- Idempotency guard --------------------------------------------------------
if [ -f "$LOCK_FILE" ]; then
  echo "[bootstrap] lock file found — previous run detected, skipping duplicate execution."
  echo "[bootstrap] To rerun manually, remove ${LOCK_FILE} first."
  exit 0
fi

# --- Credential verification --------------------------------------------------
if [ -z "${JENKINS_ADMIN_PASS:-}" ]; then
  echo "[bootstrap] ERROR: JENKINS_ADMIN_PASS not found in environment." >&2
  exit 1
fi

# --- Path resolution ----------------------------------------------------------
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

# --- Network readiness --------------------------------------------------------
echo "[bootstrap] verifying network connectivity..."
if ! getent hosts github.com >/dev/null 2>&1; then
  echo "[bootstrap] DNS seems unavailable — adding fallback nameserver..."
  echo "nameserver 1.1.1.1" > /etc/resolv.conf
fi

# --- Jenkins repository setup -------------------------------------------------
echo "[bootstrap] adding Jenkins repository..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
  | tee /usr/share/keyrings/jenkins-keyring.asc >/dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  > /etc/apt/sources.list.d/jenkins.list

# --- Core installation --------------------------------------------------------
retry 10 5 apt-get update -o Acquire::ForceIPv4=true
retry 6 5 apt-get install -y qemu-guest-agent curl git jq unzip ca-certificates \
  openjdk-17-jre-headless make ufw jenkins
systemctl enable --now qemu-guest-agent jenkins

# --- Firewall configuration ---------------------------------------------------
echo "[bootstrap] configuring UFW..."
ufw --force reset >/dev/null 2>&1 || true
ufw allow 22/tcp comment 'SSH access'
ufw allow 8080/tcp comment 'Jenkins controller UI'
yes | ufw enable >/dev/null 2>&1 || true
ufw status numbered || true

# --- Initialization script injection -----------------------------------------
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
  "phase": "bootstrap-running",
  "ip": "${IP}",
  "jenkins": "http://${IP}:8080",
  "ts": "$(date -Is)"
}
JSON

# --- Ephemeral secret cleanup -------------------------------------------------
echo "[bootstrap] cleaning ephemeral admin secret..."
rm -f /etc/profile.d/jenkins_env.sh || true

# --- Evidence collection ------------------------------------------------------
EVIDENCE_SCRIPT="${REPO_ROOT}/control/tools/provision/evidence/ctrl01-collect-evidence.sh"
if [ -f "$EVIDENCE_SCRIPT" ]; then
  echo "[bootstrap] preparing evidence collector..."
  chmod +x "$EVIDENCE_SCRIPT" || echo "[warn] failed to set execute bit on evidence collector"
  echo "[bootstrap] launching evidence collector (background)..."
  nohup bash "$EVIDENCE_SCRIPT" >/var/log/ctrl01_evidence.log 2>&1 & disown
else
  echo "[warn] evidence collector script not found at $EVIDENCE_SCRIPT"
fi

# --- SSH hardening ------------------------------------------------------------
if [ "${ENABLE_AUTO_HARDEN}" = "true" ]; then
  echo "[bootstrap] scheduling SSH hardening in ${HARDEN_GRACE_MIN}m (background)"
  (
    sleep "$((HARDEN_GRACE_MIN * 60))"
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
  ) &
fi

# Update structured phase marker for CI/audit tools
jq '.phase = "bootstrap-complete"' /var/lib/ctrl01/status.json > /var/lib/ctrl01/status.tmp 2>/dev/null \
  && mv /var/lib/ctrl01/status.tmp /var/lib/ctrl01/status.json

echo "$(date -Is)" > "$LOCK_FILE"
echo "[bootstrap] marked complete — lock written at ${LOCK_FILE}"
echo "[bootstrap] complete $(date -Is)"
