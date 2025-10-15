#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# HybridOps Studio — Day-1 Bootstrap for ctrl-01 (Jenkins Controller)
# -----------------------------------------------------------------------------
# Purpose:
#   Installs Jenkins, loads controller-init Groovy scripts, and prepares
#   the controller for Git-driven CI/CD.  Expects JENKINS_ADMIN_PASS from
#   Day-0 environment; fails fast if missing.
#
# Notes:
#   - No plaintext credentials are persisted.
#   - Jenkins hashes admin credentials internally (BCrypt).

# Usage:
#   This script is invoked automatically by ctrl01-bootstrap.service on first boot.
#   It can also be run manually after Day-0 provisioning, e.g. for recovery.

# Debugging:
# sudo tail -f /var/log/ctrl01_bootstrap.log

# -----------------------------------------------------------------------------

set -Eeuo pipefail
LOG=/var/log/ctrl01_bootstrap.log
exec > >(tee -a "$LOG") 2>&1

echo "[bootstrap] start $(date -Is)"

# --- Variables ----------------------------------------------------------------
CIUSER=${CIUSER:-hybridops}
JENKINS_ADMIN_USER=${JENKINS_ADMIN_USER:-admin}
JENKINS_SEED_REPO=${JENKINS_SEED_REPO:-https://github.com/jeleel-muibi/hybridops.studio}
JENKINS_SEED_BRANCH=${JENKINS_SEED_BRANCH:-main}
ENABLE_AUTO_HARDEN=${ENABLE_AUTO_HARDEN:-true}
HARDEN_GRACE_MIN=${HARDEN_GRACE_MIN:-10}

# --- Credential verification --------------------------------------------------
if [ -z "${JENKINS_ADMIN_PASS:-}" ]; then
  echo "[bootstrap] ERROR: JENKINS_ADMIN_PASS not set in environment." >&2
  exit 1
fi

# --- Helper: retry ------------------------------------------------------------
retry() {
  local tries="${1:-8}" delay="${2:-5}"; shift 2
  local n=1
  until "$@"; do
    (( n++ >= tries )) && { echo "[retry] failed: $*"; return 1; }
    echo "[retry] attempt $n/$tries"; sleep "$delay"
  done
}

# --- Install Jenkins ----------------------------------------------------------
echo "[bootstrap] installing Jenkins and dependencies..."
retry 10 5 apt-get update -o Acquire::ForceIPv4=true
retry 6 5 apt-get install -y \
  qemu-guest-agent curl git jq unzip ca-certificates make ufw \
  openjdk-17-jre-headless jenkins

systemctl enable --now qemu-guest-agent jenkins

# --- Firewall -----------------------------------------------------------------
ufw allow 22/tcp 8080/tcp && yes | ufw enable || true
retry 40 3 bash -lc 'ss -lnt | grep -q ":8080"'

# --- Jenkins seed / controller-init import ------------------------------------
echo "[bootstrap] preparing controller-init scripts..."
REPO_DIR="/srv/hybridops"
INIT_SRC="${REPO_DIR}/control/tools/jenkins/controller-init"
INIT_DST="/var/lib/jenkins/init.groovy.d"

install -d -m 0755 "$REPO_DIR"
if [ ! -d "$REPO_DIR/.git" ]; then
  retry 6 5 git clone --branch "$JENKINS_SEED_BRANCH" --depth 1 "$JENKINS_SEED_REPO" "$REPO_DIR"
fi

if [ -d "$INIT_SRC" ]; then
  echo "[bootstrap] importing from $INIT_SRC"
  install -d -m 0755 "$INIT_DST"
  cp -r "$INIT_SRC/"* "$INIT_DST/" || true
  chown -R jenkins:jenkins "$INIT_DST"
else
  echo "[bootstrap] ERROR: controller-init not found at $INIT_SRC" >&2
  exit 1
fi

systemctl restart jenkins
retry 40 3 bash -lc 'ss -lnt | grep -q ":8080"'

# --- Evidence -----------------------------------------------------------------
IP="$(hostname -I | awk '{print $1}')"
echo "{\"status\":\"ok\",\"ip\":\"${IP}\",\"jenkins\":\"http://${IP}:8080\",\"ts\":\"$(date -Is)\"}" \
  > /var/lib/ctrl01/status.json

# --- SSH Hardening ------------------------------------------------------------
if [[ "${ENABLE_AUTO_HARDEN}" == "true" ]]; then
  echo "[bootstrap] will harden SSH after ${HARDEN_GRACE_MIN}m grace period..."
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
      echo "[bootstrap] SSH password login disabled $(date -Is)"
    fi
  ) &
fi

echo "[bootstrap] complete $(date -Is)"
