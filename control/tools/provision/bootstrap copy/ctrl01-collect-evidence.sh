#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# HybridOps Studio: ctrl-01 Evidence Collection
# -----------------------------------------------------------------------------
# PURPOSE
#   • Collect comprehensive evidence of ctrl-01 bootstrapping
#   • Generate structured evidence aligned with verification runbook
#   • Works even when repository is not available
#
# OPERATIONAL SHAPE
#   • This script can be run standalone at any point
#   • Generates evidence locally when repo is unavailable
# -----------------------------------------------------------------------------

set -Eeuo pipefail

# Evidence parameters
CURRENT_DATE="$(date -u -Is)"
CURRENT_USER="$(id -un)"

# Determine where to store evidence
REPO_PATH="/srv/hybridops"
if [ -d "$REPO_PATH" ]; then
    # If repo exists, use its structure
    EV_BASE="$REPO_PATH/docs/proof/ctrl01"
else
    # Fallback to local user directory
    EV_BASE="/home/ubuntu/bootstrap-evidence/ctrl01"
    echo "[evidence] Repository not found at $REPO_PATH, using local storage: $EV_BASE"
fi

# Evidence directory setup
TS=$(date -u +%Y%m%dT%H%M%SZ)
EV_DIR="$EV_BASE/$TS"
install -d -m 0755 "$EV_DIR"
install -d -m 0755 "$EV_DIR/images"

echo "[evidence] Creating evidence collection at: $EV_DIR"

# Create evidence metadata file
cat > "$EV_DIR/README.md" <<EOF
# ctrl-01 Bootstrap Evidence - ${CURRENT_DATE}

**Run by:** \`${CURRENT_USER}\`
**Timestamp:** \`${TS}\`
**Hostname:** \`$(hostname)\`

## Repository Status
**IMPORTANT: Repository not found at \`/srv/hybridops\`**

This evidence was collected locally since the repository was not available.
This may indicate that:
- The repository has not been cloned yet
- The bootstrap process hasn't completed
- The repository was cloned to a different location

## Evidence Index
1. [System Information](./00_system_info.txt) - Base system configuration
2. [Systemd Status](./01_systemd_status.txt) - Timer and service activation
3. [Bootstrap Log](./02_bootstrap_log.txt) - Day-1 log and status
4. [Tool Versions](./03_tool_versions.txt) - Core toolchain verification
5. [Jenkins Status](./04_jenkins_status.txt) - Jenkins service verification
6. [SSH Configuration](./05_ssh_config.txt) - Adaptive hardening status
7. [Repository Status](./06_repo_status.txt) - Repo bootstrap verification
8. [Final State](./07_final_state.txt) - Post-bootstrap system state

## Configuration
- Full Bootstrap: \`$(cat /var/lib/ctrl01/status.json 2>/dev/null | jq -r '.bootstrap // "unknown"' 2>/dev/null || echo "unknown")\`
- Jenkins Enabled: \`$(systemctl is-active jenkins >/dev/null 2>&1 && echo "true" || echo "false")\`
- Auto Hardening: \`$(grep -q "PasswordAuthentication no" /etc/ssh/sshd_config.d/*.conf 2>/dev/null && echo "true" || echo "false (password auth enabled)")\`

## Status JSON
\`\`\`json
$(cat /var/lib/ctrl01/status.json 2>/dev/null || echo "{\"status\":\"unknown\",\"note\":\"Status file not found\"}")
\`\`\`
EOF

# EVIDENCE 1: Basic system information
{
  echo "=== System Information @ ${CURRENT_DATE} ==="
  echo "User: ${CURRENT_USER}"
  echo "Date: ${CURRENT_DATE} UTC"
  echo "Hostname: $(hostname)"
  echo "IP Address: $(hostname -I | awk '{print $1}')"
  echo -e "\n=== Hardware Information ==="
  uname -a
  lscpu | grep -E "^CPU\(s\)|^Model name|^Architecture" || true
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
  echo "=== Systemd Timer Status @ ${CURRENT_DATE} ==="
  systemctl status ctrl01-bootstrap.timer --no-pager 2>&1 || echo "Timer not found"
  echo -e "\n=== Systemd Service Status ==="
  systemctl status ctrl01-bootstrap.service --no-pager 2>&1 || echo "Service not found"
  echo -e "\n=== Systemd Journal (recent entries) ==="
  journalctl -u ctrl01-bootstrap.service --no-pager | tail -n 60 2>&1 || echo "No journal entries found"
} | tee "$EV_DIR/01_systemd_status.txt"

# EVIDENCE 3: Capture bootstrap log and status
{
  echo "=== Bootstrap Log @ ${CURRENT_DATE} ==="
  if [ -f /var/log/ctrl01_bootstrap.log ]; then
    tail -n 200 /var/log/ctrl01_bootstrap.log
  else
    echo "Log file not found at /var/log/ctrl01_bootstrap.log"
  fi

  echo -e "\n=== Status JSON ==="
  if [ -f /var/lib/ctrl01/status.json ]; then
    cat /var/lib/ctrl01/status.json
  else
    echo "Status file not found at /var/lib/ctrl01/status.json"
  fi
} | tee "$EV_DIR/02_bootstrap_log.txt"

# EVIDENCE 4: Tool versions
{
  echo "=== Core Toolchain Verification @ ${CURRENT_DATE} ==="
  echo -e "\nTerraform version:"
  terraform -v 2>&1 || echo "Terraform not installed"

  echo -e "\nPacker version:"
  packer -v 2>&1 || echo "Packer not installed"

  echo -e "\nKubectl version:"
  kubectl version --client 2>&1 || echo "Kubectl not installed"

  echo -e "\nHelm version:"
  helm version 2>&1 || echo "Helm not installed"

  echo -e "\nAnsible version:"
  ansible --version 2>&1 || echo "Ansible not installed"
} | tee "$EV_DIR/03_tool_versions.txt"

# EVIDENCE 5: Jenkins status
{
  echo "=== Jenkins Status Verification @ ${CURRENT_DATE} ==="
  echo -e "\nService status:"
  systemctl status jenkins --no-pager 2>&1 || echo "Jenkins service not found"

  echo -e "\nPort status (8080):"
  ss -lntp | grep :8080 || echo "Port 8080 not listening"

  echo -e "\nInitial admin password:"
  if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    echo "INITIAL_PASS: $(cat /var/lib/jenkins/secrets/initialAdminPassword)"
  else
    echo "Jenkins initial password file not found"
  fi
} | tee "$EV_DIR/04_jenkins_status.txt"

# EVIDENCE 6: SSH configuration
{
  echo "=== SSH Configuration @ ${CURRENT_DATE} ==="
  echo -e "\nAuthorized keys status:"
  AUTH="/home/ubuntu/.ssh/authorized_keys"
  if [ -s "$AUTH" ]; then
    echo "key-present"
    echo -e "\nKey fingerprints:"
    ssh-keygen -lf "$AUTH" || echo "Cannot read key fingerprints"
  else
    echo "key-missing"
  fi

  echo -e "\nSSH configuration files:"
  ls -la /etc/ssh/sshd_config.d/ 2>&1 || echo "No SSH config directory found"

  echo -e "\nPassword authentication settings:"
  grep -E 'PasswordAuthentication|KbdInteractiveAuthentication' /etc/ssh/sshd_config.d/*.conf 2>/dev/null ||
  grep -E 'PasswordAuthentication|KbdInteractiveAuthentication' /etc/ssh/sshd_config ||
  echo "No SSH password config found"

  echo -e "\nFirewall status:"
  ufw status verbose 2>&1 || echo "Firewall not configured"
} | tee "$EV_DIR/05_ssh_config.txt"

# EVIDENCE 7: Repository status
{
  echo "=== Repository Status @ ${CURRENT_DATE} ==="
  echo -e "\nChecking for repository at /srv/hybridops:"
  if [ -d "/srv/hybridops" ]; then
    echo "Found: /srv/hybridops exists"

    if [ -d "/srv/hybridops/.git" ]; then
      echo "Git repository confirmed"
      echo -e "\nCurrent commit:"
      (cd /srv/hybridops && git rev-parse --short HEAD) || echo "Cannot determine commit hash"

      echo -e "\nRemote information:"
      (cd /srv/hybridops && git remote -v) || echo "No remotes configured"

      echo -e "\nBranch status:"
      (cd /srv/hybridops && git branch -v) || echo "Cannot determine branch"
    else
      echo "Directory exists but is not a git repository"
      echo -e "\nContents:"
      ls -la /srv/hybridops/
    fi
  else
    echo "NOT FOUND: /srv/hybridops directory does not exist"
    echo -e "\nContents of /srv:"
    ls -la /srv/
  fi

  # Check for other potential repo locations
  echo -e "\nChecking alternative locations:"
  for dir in /home/ubuntu/hybridops /opt/hybridops; do
    if [ -d "$dir/.git" ]; then
      echo "Found repository at: $dir"
      echo -e "\nCommit:"
      (cd $dir && git rev-parse --short HEAD) || echo "Cannot determine commit hash"
    fi
  done
} | tee "$EV_DIR/06_repo_status.txt"

# EVIDENCE 8: Final system state
{
  echo "=== Final System State @ ${CURRENT_DATE} ==="
  echo -e "\nDisk Usage:"
  df -h

  echo -e "\nMemory Usage:"
  free -h

  echo -e "\nRunning Services:"
  systemctl list-units --type=service --state=running | head -n 20

  echo -e "\nListening Ports:"
  ss -tuln

  echo -e "\nRecent System Journal:"
  journalctl --no-pager -n 20
} | tee "$EV_DIR/07_final_state.txt"

# Create a symlink to the latest evidence for convenience
ln -sf "$EV_DIR" "$EV_BASE/latest"

echo "[evidence] Evidence collection completed at: $EV_DIR"
echo "[evidence] Evidence README at: $EV_DIR/README.md"

# Print instructions
if [ -d "$REPO_PATH/.git" ]; then
  echo "[evidence] To commit evidence: cd $REPO_PATH && git add docs/proof/ctrl01/ && git commit -m 'Add bootstrap evidence from $CURRENT_DATE'"
else
  echo "[evidence] Repository not found. Evidence stored locally at: $EV_DIR"
  echo "[evidence] You may want to transfer this evidence to a permanent location."
fi
