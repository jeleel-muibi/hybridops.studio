#!/usr/bin/env bash
# Collects evidence for ctrl-01 bootstrap into repo docs/proof/ctrl01/<ts>/ and updates 'latest' symlink
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." &>/dev/null && pwd)"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${REPO_ROOT}/docs/proof/ctrl01/${TS}"
LATEST="${REPO_ROOT}/docs/proof/ctrl01/latest"
mkdir -p "${OUT_DIR}/images"

status_json="/var/lib/ctrl01/status.json"
ip="$(hostname -I | awk '{print $1}')"

# 00 System info
{
  echo "# System information"
  echo "Timestamp: $(date -Is)"
  echo "Hostname: $(hostname)"
  echo "IP: ${ip}"
  echo "Kernel: $(uname -r)"
  echo "Distro:"; lsb_release -a 2>/dev/null || cat /etc/os-release
} > "${OUT_DIR}/00_system_info.txt"

# 01 Systemd
{
  systemctl list-timers '*ctrl01*' --all || true
  systemctl status ctrl01-day1-fetch.timer --no-pager || true
  systemctl status ctrl01-day1-fetch.service --no-pager || true
} > "${OUT_DIR}/01_systemd_status.txt"

# 02 Day-1 log + status
{
  [ -f /var/log/ctrl01_bootstrap.log ] && tail -n 400 /var/log/ctrl01_bootstrap.log || echo "no log"
  [ -f "${status_json}" ] && cat "${status_json}" || echo "{}"
} > "${OUT_DIR}/02_bootstrap_log.txt"

# 03 Tool versions
{
  terraform -v 2>&1 || true
  packer -v 2>&1 || true
  kubectl version --client --output=yaml 2>&1 || true
  helm version 2>&1 || true
  ansible --version 2>&1 || true
} > "${OUT_DIR}/03_tool_versions.txt"

# 04 Jenkins
{
  systemctl status jenkins --no-pager 2>&1 || true
  ss -lntp | grep :8080 || true
  [ -f /var/lib/jenkins/secrets/initialAdminPassword ] && sudo cat /var/lib/jenkins/secrets/initialAdminPassword || true
} > "${OUT_DIR}/04_jenkins_status.txt"

# 05 SSH config
{
  grep -E 'PasswordAuthentication|KbdInteractiveAuthentication' /etc/ssh/sshd_config.d/*.conf 2>/dev/null || true
} > "${OUT_DIR}/05_ssh_config.txt"

# 06 Repo
{
  echo "Repo root: ${REPO_ROOT}"
  if [ -d "${REPO_ROOT}/.git" ]; then
    git -C "${REPO_ROOT}" rev-parse --short HEAD || true
    git -C "${REPO_ROOT}" branch --show-current || true
    git -C "${REPO_ROOT}" remote -v || true
  else
    echo "WARNING: repository not found at ${REPO_ROOT}"
  fi
} > "${OUT_DIR}/06_repo_status.txt"

# 07 Final state
{
  df -h
  free -h
} > "${OUT_DIR}/07_final_state.txt"

# README
cat > "${OUT_DIR}/README.md" <<'MD'
# ctrl-01 Bootstrap Evidence

This folder contains artifacts collected after the Day-1 bootstrap finished.
Each text file corresponds to a verification point in the runbook.
MD

ln -sfn "${OUT_DIR}" "${LATEST}"
echo "${OUT_DIR}"
