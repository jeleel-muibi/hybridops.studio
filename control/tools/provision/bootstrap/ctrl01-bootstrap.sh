#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# HybridOps Studio — ctrl-01 Day-1 Bootstrap (Jenkins Controller)
# -----------------------------------------------------------------------------
# Purpose:
#   Configure a clean, auditable Jenkins controller VM from Git.
#   Installs Jenkins only (no heavy toolchains; agents handle workloads).
#   Produces machine-verifiable evidence and enforces SSH hardening post-bootstrap.
# -----------------------------------------------------------------------------

set -Eeuo pipefail
LOG=/var/log/ctrl01_bootstrap.log
exec > >(tee -a "$LOG") 2>&1
echo "[bootstrap] start $(date -Is)"

CIUSER=${CIUSER:-hybridops}
JENKINS_ADMIN_USER=${JENKINS_ADMIN_USER:-admin}
JENKINS_ADMIN_PASS=${JENKINS_ADMIN_PASS:-ChangeMe_$(date +%s)}
JENKINS_PLUGINS=${JENKINS_PLUGINS:-"configuration-as-code job-dsl git workflow-aggregator pipeline-utility-steps ansible ssh-slaves credentials-binding matrix-auth timestamper blueocean"}
JENKINS_SEED_JOB=${JENKINS_SEED_JOB:-ctrl01-bootstrap}
JENKINS_SEED_REPO=${JENKINS_SEED_REPO:-https://github.com/jeleel-muibi/hybridops.studio}
JENKINS_SEED_BRANCH=${JENKINS_SEED_BRANCH:-main}
ENABLE_AUTO_HARDEN=${ENABLE_AUTO_HARDEN:-true}
HARDEN_GRACE_MIN=${HARDEN_GRACE_MIN:-10}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
EVIDENCE_BASE="${REPO_ROOT}/docs/proof/ctrl01"
mkdir -p "$EVIDENCE_BASE"

# --- Helper: retry ------------------------------------------------------------
retry() { local n=1 tries="${1:-8}" delay="${2:-5}"; shift 2
  until "$@"; do
    ((n++>=tries)) && { echo "Retry failed after $tries attempts: $*"; return 1; }
    echo "[retry] attempt $n/$tries"; sleep "$delay"
  done
}

# --- Ensure base packages -----------------------------------------------------
retry 10 5 apt-get update -o Acquire::ForceIPv4=true
retry 6 5 apt-get install -y qemu-guest-agent curl git jq unzip ca-certificates make ufw openjdk-17-jre-headless jenkins
systemctl enable --now qemu-guest-agent jenkins

# --- Firewall baseline --------------------------------------------------------
ufw allow 22/tcp 8080/tcp && yes | ufw enable || true

# --- Jenkins readiness + plugin bootstrap ------------------------------------
retry 40 3 bash -lc 'ss -lnt | grep -q ":8080"'
/usr/lib/jenkins/jenkins-plugin-cli --plugins ${JENKINS_PLUGINS} || true
systemctl restart jenkins
retry 40 3 bash -lc 'ss -lnt | grep -q ":8080"'

# --- Admin user & seed job ----------------------------------------------------
install -d -m 0755 /var/lib/jenkins/init.groovy.d

cat >/var/lib/jenkins/init.groovy.d/01-admin.groovy <<GROOVY
import jenkins.model.*
import hudson.security.*

def j = Jenkins.get()
def realm = new HudsonPrivateSecurityRealm(false)
if (realm.getAllUsers()?.isEmpty()) {
  realm.createAccount("${JENKINS_ADMIN_USER}", "${JENKINS_ADMIN_PASS}")
  j.setSecurityRealm(realm)
  def strat = new FullControlOnceLoggedInAuthorizationStrategy()
  strat.setAllowAnonymousRead(false)
  j.setAuthorizationStrategy(strat)
  j.save()
}
GROOVY

cat >/var/lib/jenkins/init.groovy.d/02-seed-mbp.groovy <<GROOVY
import jenkins.model.*
import jenkins.branch.*
import jenkins.plugins.git.*
import org.jenkinsci.plugins.workflow.multibranch.*

def j = Jenkins.instance
def name = "${JENKINS_SEED_JOB}"
if (j.getItem(name) == null) {
  def mbp = new WorkflowMultiBranchProject(j, name)
  def scm = new GitSCMSource("${JENKINS_SEED_REPO}")
  scm.setTraits([new BranchDiscoveryTrait()])
  mbp.getSourcesList().add(new BranchSource(scm))
  mbp.setDisplayName("HybridOps • ctrl-01")
  j.putItem(mbp)
  mbp.scheduleBuild2(0)
}
GROOVY

chown -R jenkins:jenkins /var/lib/jenkins
systemctl restart jenkins

# --- Evidence collection ------------------------------------------------------
IP="$(hostname -I | awk '{print $1}')"
EVID_DIR="${EVIDENCE_BASE}/$(date -u +%Y%m%dT%H%M%SZ)"
install -d -m 0755 "$EVID_DIR"

cat > /var/lib/ctrl01/status.json <<JSON
{
  "status": "ok",
  "ip": "${IP}",
  "jenkins": "http://${IP}:8080",
  "timestamp": "$(date -Is)",
  "repo": "${REPO_ROOT}"
}
JSON

bash "${SCRIPT_DIR}/ctrl01-collect-evidence.sh" || true

# --- Adaptive SSH hardening ---------------------------------------------------
if [ "${ENABLE_AUTO_HARDEN}" = "true" ]; then
  echo "[bootstrap] hardening in ${HARDEN_GRACE_MIN}m"
  sleep "$((HARDEN_GRACE_MIN*60))"
  AUTH="/home/${CIUSER}/.ssh/authorized_keys"
  if [ -s "$AUTH" ]; then
    echo "[bootstrap] key detected → disable password auth"
    mkdir -p /etc/ssh/sshd_config.d
    cat >/etc/ssh/sshd_config.d/99-password-off.conf <<'CONF'
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
CONF
    systemctl reload ssh || systemctl reload sshd
  fi
fi

echo "[bootstrap] done $(date -Is)"
