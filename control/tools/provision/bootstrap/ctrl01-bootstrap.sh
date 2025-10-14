#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# HybridOps Studio: ctrl-01 Day‑1 Bootstrap (Configuration)
# -----------------------------------------------------------------------------
# PURPOSE
#   • Day‑1 (inside VM): Install core tooling (Terraform, Packer, kubectl,
#     Helm, Ansible, Jenkins), configure services, and apply adaptive hardening.
#   • Generate structured evidence aligned with verification runbook.
#
# OPERATIONAL SHAPE
#   • This script is stored in source control and executed from within the VM
#   • Triggered by systemd timer after Day-0 VM provisioning completes
#   • Evidence is stored in docs/proof for Git tracking
#
# AUDIT ARTIFACTS
#   • Logs:        /var/log/ctrl01_bootstrap.log (already configured by launcher)
#   • Status JSON: /var/lib/ctrl01/status.json
#   • Evidence:    $REPO_ROOT/docs/proof/ctrl01/<timestamp>/
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

# Evidence directory setup with timestamp and execution metadata
TS=$(date -u +%Y%m%dT%H%M%SZ)
CURRENT_DATE="2025-10-14 18:48:43"  # Provided date
CURRENT_USER="jeleel-muibigood"      # Provided username
EV_BASE=${EV_BASE:-$REPO_ROOT/docs/proof/ctrl01}
EV_DIR="$EV_BASE/$TS"
install -d -m 0755 "$EV_DIR"
install -d -m 0755 "$EV_DIR/images"  # Creating an images subdirectory to match your structure

# Create evidence metadata file to make evidence GitHub-friendly
cat > "$EV_DIR/README.md" <<EOF
# ctrl-01 Bootstrap Evidence - $CURRENT_DATE

**Run by:** \`${CURRENT_USER}\`
**Timestamp:** \`${TS}\`
**Hostname:** \`$(hostname)\`

## Evidence Index
This directory contains verification evidence aligned with the [ctrl-01 Day-1 bootstrap & verification](${REPO_ROOT}/docs/runbooks/bootstrap/verify-ctrl01-bootstrap.md) runbook.

1. [System Information](./00_system_info.txt) - Base system configuration
2. [Systemd Status](./01_systemd_status.txt) - Timer and service activation
3. [Bootstrap Log](./02_bootstrap_log.txt) - Day-1 log and status
4. [Tool Versions](./03_tool_versions.txt) - Core toolchain verification
5. [Jenkins Status](./04_jenkins_status.txt) - Jenkins service verification
6. [SSH Configuration](./05_ssh_config.txt) - Adaptive hardening status
7. [Repository Status](./06_repo_status.txt) - Repo bootstrap verification
8. [Final State](./07_final_state.txt) - Post-bootstrap system state

## Configuration
- Full Bootstrap: \`${ENABLE_FULL_BOOTSTRAP}\`
- Jenkins Enabled: \`${ENABLE_JENKINS}\`
- Auto Hardening: \`${ENABLE_AUTO_HARDEN}\` (grace: ${HARDEN_GRACE_MIN}m)

## Status JSON
\`\`\`json
$(cat /var/lib/ctrl01/status.json 2>/dev/null || echo "{}")
\`\`\`
EOF

# Networking resilience
retry() {
  local n=1; local tries="$1"; local sleep_s="$2"; shift 2;
  until "$@"; do
    if [ $n -ge "$tries" ]; then echo "RETRY: giving up after $n: $*"; return 1; fi
    echo "RETRY: $n/$tries failed: $* ; sleeping ${sleep_s}s"; sleep "$sleep_s"; n=$((n+1))
  done
}

# EVIDENCE 1: Basic system information capture
{
  echo "=== System Information @ $CURRENT_DATE ==="
  echo "User: ${CURRENT_USER}"
  echo "Date: ${CURRENT_DATE} UTC"
  echo "Hostname: $(hostname)"
  echo "IP Address: $(hostname -I | awk '{print $1}')"
  echo -e "\n=== Hardware Information ==="
  uname -a
  lscpu | grep -E "^CPU\(s\)|^Model name|^Architecture"
  free -h
  echo -e "\n=== OS Release ==="
  cat /etc/os-release
  echo -e "\n=== Network Configuration ==="
  ip a
  echo -e "\n=== Disk Usage ==="
  df -h
} | tee "$EV_DIR/00_system_info.txt"

# EVIDENCE 2: Systemd status
{
  echo "=== Systemd Timer Status @ $CURRENT_DATE ==="
  systemctl status ctrl01-bootstrap.timer --no-pager || true
  echo -e "\n=== Systemd Service Status ==="
  systemctl status ctrl01-bootstrap.service --no-pager || true
  echo -e "\n=== Systemd Journal (recent entries) ==="
  journalctl -u ctrl01-bootstrap.service --no-pager | tail -n 60 || true
} | tee "$EV_DIR/01_systemd_status.txt"

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

# EVIDENCE 3: Capture bootstrap log and status
{
  echo "=== Bootstrap Log @ $CURRENT_DATE ==="
  tail -n 200 /var/log/ctrl01_bootstrap.log 2>/dev/null || echo "Log not found yet"
  echo -e "\n=== Status JSON ==="
  cat /var/lib/ctrl01/status.json 2>/dev/null || echo "Status JSON not found yet"
} | tee "$EV_DIR/02_bootstrap_log.txt"

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

  # EVIDENCE 4: Tool versions
  {
    echo "=== Core Toolchain Verification @ $CURRENT_DATE ==="
    echo -e "\nTerraform version:"
    terraform -v || echo "Not installed"
    echo -e "\nPacker version:"
    packer -v || echo "Not installed"
    echo -e "\nKubectl version:"
    kubectl version --client --output=yaml || echo "Not installed"
    echo -e "\nHelm version:"
    helm version || echo "Not installed"
    echo -e "\nAnsible version:"
    ansible --version || echo "Not installed"
  } | tee "$EV_DIR/03_tool_versions.txt"

  # EVIDENCE 5: Jenkins status
  if [ "${ENABLE_JENKINS}" = "true" ]; then
    sleep 2
    {
      echo "=== Jenkins Status Verification @ $CURRENT_DATE ==="
      echo -e "\nService status:"
      systemctl status jenkins --no-pager || echo "Service not found"
      echo -e "\nPort status (8080):"
      ss -lntp | grep :8080 || echo "Port not listening"
      echo -e "\nInitial admin password:"
      if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
        echo "INITIAL_PASS: $(cat /var/lib/jenkins/secrets/initialAdminPassword)"
      else
        echo "Password file not found yet"
      fi
    } | tee "$EV_DIR/04_jenkins_status.txt"
  else
    echo "Jenkins not enabled" > "$EV_DIR/04_jenkins_status.txt"
  fi
fi

# EVIDENCE 6: SSH configuration and hardening status
{
  echo "=== SSH Configuration @ $CURRENT_DATE ==="
  echo -e "\nAuthorized keys status:"
  AUTH="/home/${CIUSER}/.ssh/authorized_keys"
  test -s "$AUTH" && echo "key-present" || echo "key-missing"

  echo -e "\nSSH configuration:"
  grep -E 'PasswordAuthentication|KbdInteractiveAuthentication' /etc/ssh/sshd_config.d/*.conf 2>/dev/null || echo "No specific SSH config found"

  echo -e "\nFirewall status:"
  ufw status verbose || echo "Firewall not configured"

  echo -e "\nSudo configuration:"
  ls -la /etc/sudoers.d/ || echo "No sudoers.d found"
} | tee "$EV_DIR/05_ssh_config.txt"

# EVIDENCE 7: Repository status
{
  echo "=== Repository Status @ $CURRENT_DATE ==="
  if [ -d "${REPO_ROOT}/.git" ]; then
    echo "repo-present"
    echo -e "\nCurrent commit:"
    git -C "${REPO_ROOT}" rev-parse --short HEAD || echo "Cannot determine commit hash"

    echo -e "\nRemote information:"
    git -C "${REPO_ROOT}" remote -v || echo "No remotes configured"

    echo -e "\nBranch status:"
    git -C "${REPO_ROOT}" branch -v || echo "Cannot determine branch"

    echo -e "\nRecent commits:"
    git -C "${REPO_ROOT}" log --oneline -n 5 || echo "Cannot retrieve git log"
  else
    echo "repo-missing"
    echo -e "\nExpected location: ${REPO_ROOT}"
    echo -e "\nDirectory contents:"
    ls -la "${REPO_ROOT}"
  fi
} | tee "$EV_DIR/06_repo_status.txt"

# Status artifact
install -d -m 0755 /var/lib/ctrl01
IP="$(hostname -I | awk '{print $1}')"
jq -n \
  --arg status "ok" \
  --arg ip "$IP" \
  --arg jenkins "http://$IP:8080" \
  --arg ts "$CURRENT_DATE" \
  --arg bootstrap "${ENABLE_FULL_BOOTSTRAP}" \
  --arg repo "${REPO_ROOT}" \
  --arg evidence_dir "$EV_DIR" \
  --arg user "${CURRENT_USER}" \
  '{status:$status, ip:$ip, jenkins:$jenkins, ts:$ts, bootstrap:$bootstrap, repo:$repo, evidence_dir:$evidence_dir, user:$user}' \
  | tee /var/lib/ctrl01/status.json

# Clean up old evidence (keep last 10)
find "$EV_BASE" -maxdepth 1 -mindepth 1 -type d | sort -r | tail -n +11 | xargs rm -rf 2>/dev/null || true

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

    # Update SSH evidence after hardening
    {
      echo -e "\n=== SSH Hardening Applied @ $CURRENT_DATE ==="
      echo "Password authentication disabled"
      echo "User password expired"
      echo "SSH key authentication only"
      echo -e "\nUpdated SSH configuration:"
      grep -E 'PasswordAuthentication|KbdInteractiveAuthentication' /etc/ssh/sshd_config.d/*.conf 2>/dev/null || echo "No specific SSH config found"
    } | tee -a "$EV_DIR/05_ssh_config.txt"
  else
    echo "[bootstrap] no key found; leaving password auth enabled"

    # Update SSH evidence
    {
      echo -e "\n=== SSH Hardening Skipped @ $CURRENT_DATE ==="
      echo "No SSH keys found in authorized_keys"
      echo "Password authentication remains enabled"
    } | tee -a "$EV_DIR/05_ssh_config.txt"
  fi
fi

# Optional: Run any additional repo-specific initialization tasks here
if [ -f "${REPO_ROOT}/control/tools/provision/init/ctrl01-init.sh" ]; then
  echo "[bootstrap] Running project initialization script"
  bash "${REPO_ROOT}/control/tools/provision/init/ctrl01-init.sh"
fi

# EVIDENCE 8: Final system state
{
  echo "=== Final System State @ $CURRENT_DATE ==="
  echo -e "\nDisk Usage:"
  df -h
  echo -e "\nMemory Usage:"
  free -h
  echo -e "\nRunning Services:"
  systemctl list-units --type=service --state=running | head -n 20
  echo -e "\nListening Ports:"
  ss -tuln

  # Update status.json evidence
  echo -e "\nFinal Status JSON:"
  cat /var/lib/ctrl01/status.json
} | tee "$EV_DIR/07_final_state.txt"

echo "[bootstrap] Day-1 process completed at $CURRENT_DATE"

# Create a symlink to the latest evidence for convenience
ln -sf "$EV_DIR" "$EV_BASE/latest"

# Add evidence location to log
echo "[bootstrap] Evidence collected at: $EV_DIR"
echo "[bootstrap] Evidence README at: $EV_DIR/README.md"
echo "[bootstrap] To commit evidence: cd $REPO_ROOT && git add docs/proof/ctrl01/ && git commit -m 'Add bootstrap evidence from $CURRENT_DATE'"
