#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# HybridOps Studio — ctrl-01 Evidence Collector (Soft-Strict Mode + Jenkins Wait)
# -----------------------------------------------------------------------------
# Purpose:
#   Collect runtime and system artifacts immediately after Day-1 bootstrap.
#   Waits until Jenkins completes its first-run setup (admin config present).
#   Generates proof under docs/proof/ctrl01/<timestamp> for audit and DR validation.
#
# Policy:
#   - Never aborts the pipeline (non-blocking)
#   - Logs explicit warnings for missing data
#   - Waits up to 3 minutes for Jenkins readiness
# -----------------------------------------------------------------------------

set -euo pipefail
trap 'echo "[warn] evidence collection error at line $LINENO — continuing" >&2' ERR
echo "[evidence] start $(date -Is)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${REPO_ROOT}/docs/proof/ctrl01/${TS}"
LATEST_LINK="${REPO_ROOT}/docs/proof/ctrl01/latest"
mkdir -p "${OUT_DIR}"

IP="$(hostname -I | awk '{print $1}')"
STATUS_JSON="/var/lib/ctrl01/status.json"
JENKINS_USER_CFG="/var/lib/jenkins/users/admin/config.xml"

# --- Wait for Jenkins readiness ----------------------------------------------
echo "[evidence] waiting for Jenkins to finish setup..."
for i in {1..18}; do
  if systemctl is-active --quiet jenkins && [ -f "$JENKINS_USER_CFG" ]; then
    echo "[evidence] Jenkins ready (admin user detected)"
    break
  fi
  echo "[evidence] Jenkins not ready yet ($i/18)..."
  sleep 10
done

# --- 00 System Info ----------------------------------------------------------
{
  echo "# System information"
  echo "Timestamp: $(date -Is)"
  echo "Hostname: $(hostname)"
  echo "IP: ${IP:-unknown}"
  echo "Kernel: $(uname -r)"
  echo
  echo "Distro:"
  if command -v lsb_release >/dev/null 2>&1; then
    lsb_release -a 2>/dev/null
  else
    cat /etc/os-release 2>/dev/null || echo "[warn] no OS info found"
  fi
} >"${OUT_DIR}/00_system_info.txt" 2>&1

# --- 01 Services -------------------------------------------------------------
{
  echo "### Jenkins service status"
  systemctl status jenkins --no-pager 2>&1 || echo "[warn] jenkins service not found"
  echo
  echo "### Bootstrap timers"
  systemctl list-timers 'ctrl01*' --all 2>/dev/null || echo "[warn] no ctrl01 timers detected"
} >"${OUT_DIR}/01_services.txt" 2>&1

# --- 02 Logs & Status --------------------------------------------------------
{
  echo "### Bootstrap Log (last 400 lines)"
  tail -n 400 /var/log/ctrl01_bootstrap.log 2>/dev/null || echo "[warn] bootstrap log missing"
  echo
  echo "### Status JSON"
  if [ -f "${STATUS_JSON}" ]; then
    cat "${STATUS_JSON}"
  else
    echo "{}"
    echo "[warn] status.json missing"
  fi
} >"${OUT_DIR}/02_bootstrap_log.txt" 2>&1

# --- 03 Tool Versions --------------------------------------------------------
{
  echo "### Java & Jenkins Versions"
  java -version 2>&1 || echo "[warn] java not installed"
  jenkins --version 2>/dev/null || apt-cache policy jenkins | grep Installed || echo "[warn] jenkins version unavailable"
} >"${OUT_DIR}/03_versions.txt" 2>&1

# --- 04 SSH / Security -------------------------------------------------------
{
  echo "### SSH Config (password auth)"
  grep -E 'PasswordAuthentication|KbdInteractiveAuthentication' /etc/ssh/sshd_config.d/*.conf 2>/dev/null || echo "[warn] no password auth config found"
} >"${OUT_DIR}/04_ssh_config.txt" 2>&1

# --- 05 Repo / Git Context ---------------------------------------------------
{
  echo "### Git Repository Context"
  echo "Repo root: ${REPO_ROOT}"
  if [ -d "${REPO_ROOT}/.git" ]; then
    git -C "${REPO_ROOT}" rev-parse --short HEAD 2>/dev/null || echo "[warn] git commit unavailable"
    git -C "${REPO_ROOT}" branch --show-current 2>/dev/null || echo "[warn] branch unavailable"
    git -C "${REPO_ROOT}" remote -v 2>/dev/null || echo "[warn] remote info unavailable"
  else
    echo "[warn] not a git repository"
  fi
} >"${OUT_DIR}/05_repo.txt" 2>&1

# --- 06 Final System Snapshot -----------------------------------------------
{
  echo "### Disk & Memory Snapshot"
  df -hT 2>/dev/null | sort || echo "[warn] df failed"
  echo
  free -h 2>/dev/null || echo "[warn] free failed"
} >"${OUT_DIR}/06_final_state.txt" 2>&1

# --- README Metadata ---------------------------------------------------------
cat >"${OUT_DIR}/README.md" <<MD
# ctrl-01 Bootstrap Evidence (Soft-Strict Mode)

This folder contains proof artifacts produced automatically after Day-1 bootstrap.
Each file corresponds to a verification point in the HybridOps runbook.

| File | Description |
|------|--------------|
| [00_system_info.txt](./00_system_info.txt) | Kernel, distro, IP metadata |
| [01_services.txt](./01_services.txt) | Jenkins and timer status |
| [02_bootstrap_log.txt](./02_bootstrap_log.txt) | Bootstrap log + JSON status |
| [03_versions.txt](./03_versions.txt) | Java and Jenkins version info |
| [04_ssh_config.txt](./04_ssh_config.txt) | SSH hardening config |
| [05_repo.txt](./05_repo.txt) | Git metadata |
| [06_final_state.txt](./06_final_state.txt) | Disk and memory snapshot |

---

**Location:** \`${OUT_DIR}\`
**Symlink:** \`${LATEST_LINK}\` → \`${OUT_DIR}\` (latest)
**Generated:** $(date -Is)
MD

ln -sfn "${OUT_DIR}" "${LATEST_LINK}"
echo "[evidence] complete $(date -Is)"
