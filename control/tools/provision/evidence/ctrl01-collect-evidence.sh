#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# HybridOps Studio — ctrl-01 Evidence Collector (Soft-Strict Mode)
# -----------------------------------------------------------------------------
# Author: Jeleel Muibi
#
# Description:
#   Non-blocking post-bootstrap collector for runtime and system artifacts.
#   Designed to execute immediately after successful Day-1 bootstrap to
#   produce timestamped, immutable proof material for audit, DR, and CI/CD
#   verification. Operates safely under “soft-strict” policy:
#     • never aborts on errors
#     • emits explicit warnings
#     • always produces a complete folder structure
#
# Design intent:
#   • Capture reproducible state evidence for hybrid infrastructure governance.
#   • Allow CI agents and reviewers to validate control-plane integrity offline.
#   • Maintain symbolic “latest” pointer for automated report ingestion.
# -----------------------------------------------------------------------------

set -euo pipefail
trap 'echo "[warn] evidence collection encountered an error at line $LINENO — continuing" >&2' ERR
echo "[evidence] start $(date -Is)"

# --- Path resolution ----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${REPO_ROOT}/docs/proof/ctrl01/${TS}"
LATEST_LINK="${REPO_ROOT}/docs/proof/ctrl01/latest"
mkdir -p "${OUT_DIR}"

IP="$(hostname -I | awk '{print $1}')"
STATUS_JSON="/var/lib/ctrl01/status.json"

# --- 00 System Metadata -------------------------------------------------------
# Captures baseline host identity, kernel, and OS signature.
{
  echo "# System information"
  echo "Timestamp: $(date -Is)"
  echo "Hostname: $(hostname)"
  echo "IP: ${IP:-unknown}"
  echo "Kernel: $(uname -r)"
  echo "Distro:"
  if command -v lsb_release >/dev/null 2>&1; then
    lsb_release -a 2>/dev/null
  else
    cat /etc/os-release 2>/dev/null || echo "[warn] no OS info found"
  fi
} >"${OUT_DIR}/00_system_info.txt" 2>&1

# --- 01 Service State ---------------------------------------------------------
# Verifies core service availability (Jenkins, timers).
{
  echo "### Jenkins service status"
  systemctl status jenkins --no-pager 2>&1 || echo "[warn] jenkins service not found"
  echo
  echo "### Bootstrap timers"
  systemctl list-timers 'ctrl01*' --all 2>/dev/null || echo "[warn] no ctrl01 timers detected"
} >"${OUT_DIR}/01_services.txt" 2>&1

# --- 02 Logs and Status -------------------------------------------------------
# Preserves bootstrap output and runtime JSON status snapshot.
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

# --- 03 Toolchain Versions ----------------------------------------------------
# Confirms Java/Jenkins versions for reproducibility and support audits.
{
  echo "### Java & Jenkins Versions"
  java -version 2>&1 || echo "[warn] java not installed"
  jenkins --version 2>/dev/null || apt-cache policy jenkins | grep Installed || echo "[warn] jenkins version unavailable"
} >"${OUT_DIR}/03_versions.txt" 2>&1

# --- 04 SSH and Security Baseline --------------------------------------------
# Documents effective SSH authentication configuration for traceability.
{
  echo "### SSH Config (password auth)"
  grep -E 'PasswordAuthentication|KbdInteractiveAuthentication' /etc/ssh/sshd_config.d/*.conf 2>/dev/null \
    || echo "[warn] no password auth config found"
} >"${OUT_DIR}/04_ssh_config.txt" 2>&1

# --- 05 Repository Context ----------------------------------------------------
# Records repo metadata (commit, branch, remotes) for provenance validation.
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

# --- 06 System Resource Snapshot ---------------------------------------------
# Captures current disk and memory footprint for post-DR analysis.
{
  echo "### Disk & Memory Snapshot"
  df -hT 2>/dev/null | sort || echo "[warn] df failed"
  echo
  free -h 2>/dev/null || echo "[warn] free failed"
} >"${OUT_DIR}/06_final_state.txt" 2>&1

# --- README Metadata ----------------------------------------------------------
# Generates a Markdown manifest summarizing evidence contents.
cat >"${OUT_DIR}/README.md" <<MD
# ctrl-01 Bootstrap Evidence (Soft-Strict Mode)

This folder contains runtime evidence generated automatically after Day-1 bootstrap.
Each file aligns with a verification control in the HybridOps runbook.

| File | Description |
|------|--------------|
| [00_system_info.txt](./00_system_info.txt) | Kernel, distro, IP metadata |
| [01_services.txt](./01_services.txt) | Jenkins and timer status |
| [02_bootstrap_log.txt](./02_bootstrap_log.txt) | Bootstrap log + JSON status |
| [03_versions.txt](./03_versions.txt) | Java and Jenkins version info |
| [04_ssh_config.txt](./04_ssh_config.txt) | SSH hardening configuration |
| [05_repo.txt](./05_repo.txt) | Git metadata and provenance |
| [06_final_state.txt](./06_final_state.txt) | Disk and memory snapshot |

---

**Location:** \`${OUT_DIR}\`
**Symlink:** \`${LATEST_LINK}\` → \`${OUT_DIR}\` *(latest)*
**Generated:** $(date -Is)
MD

# Maintain “latest” pointer for easy CI consumption or DR verification.
ln -sfn "${OUT_DIR}" "${LATEST_LINK}"

echo "[evidence] complete $(date -Is)"
