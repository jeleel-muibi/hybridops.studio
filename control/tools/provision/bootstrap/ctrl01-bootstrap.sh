#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# HybridOps Studio — ctrl-01 Day-1 Bootstrap (Configuration + Evidence)
# -----------------------------------------------------------------------------
# PURPOSE
#   • Install core tooling (Terraform, Packer, kubectl, Helm, Ansible, Jenkins)
#   • Configure services and adaptive SSH hardening
#   • Emit deterministic evidence artifacts for runbooks/review
#
# ARTIFACTS
#   • Log (live):       /var/log/ctrl01_bootstrap.log
#   • Status (machine): /var/lib/ctrl01/status.json
#   • Evidence (human): /srv/hybridops/output/artifacts/ctrl01/<UTC_TS>/
# -----------------------------------------------------------------------------

set -Eeuo pipefail

# ---- Tunables (env-overridable) ---------------------------------------------
ENABLE_FULL_BOOTSTRAP=${ENABLE_FULL_BOOTSTRAP:-true}
ENABLE_JENKINS=${ENABLE_JENKINS:-true}
ENABLE_AUTO_HARDEN=${ENABLE_AUTO_HARDEN:-true}
HARDEN_GRACE_MIN=${HARDEN_GRACE_MIN:-10}
CIUSER=${CIUSER:-ubuntu}

# ---- Repo context ------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../" &>/dev/null && pwd)"

# ---- Logging ----------------------------------------------------------------
LOG=/var/log/ctrl01_bootstrap.log
install -d -m 0755 "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1
echo "[bootstrap] start $(date -Is) :: script=$0 repo_root=${REPO_ROOT}"

# ---- Evidence directory ------------------------------------------------------
EV_BASE=/srv/hybridops/output/artifacts/ctrl01
TS=$(date -u +%Y%m%dT%H%M%SZ)
EV_DIR="${EV_BASE}/${TS}"
install -d -m 0755 "$EV_DIR"

# helper: append numbered files, maintain a simple index
SEQ=0
nextf() { printf "%02d_%s" "$SEQ" "$1"; SEQ=$((SEQ+10)); }
emit()  { local name="$1"; shift; { "$@" ; } >"${EV_DIR}/$(nextf "$name").txt" 2>&1 || true; }
append_json() { # key value to evidence index
  local k="$1" v="$2"
  jq -n --arg k "$k" --arg v "$v" '{($k):$v}' >"${EV_DIR}/.add.json"
  if [ -s "${EV_DIR}/index.json" ]; then
    jq -s 'add' "${EV_DIR}/index.json" "${EV_DIR}/.add.json" >"${EV_DIR}/.tmp" && mv "${EV_DIR}/.tmp" "${EV_DIR}/index.json"
  else
    mv "${EV_DIR}/.add.json" "${EV_DIR}/index.json"
  fi
  rm -f "${EV_DIR}/.add.json"
}

# Write a minimal index header early
append_json "started_at" "$(date -Is)"
append_json "script" "$0"
append_json "repo_root" "${REPO_ROOT}"

# ---- Safety / retry helpers --------------------------------------------------
retry() {
  local n=1; local tries="$1"; local sleep_s="$2"; shift 2
  until "$@"; do
    if [ $n -ge "$tries" ]; then echo "RETRY: giving up after $n: $*"; return 1; fi
    echo "RETRY: $n/$tries failed: $* ; sleeping ${sleep_s}s"; sleep "$sleep_s"; n=$((n+1))
  done
}

# On error: emit status + last log tail for evidence
on_err() {
  local rc=$?
  echo "[bootstrap] ERROR rc=$rc at $(date -Is)"
  tail -n 200 "$LOG" > "${EV_DIR}/99_error_tail.txt" || true
  IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
  mkdir -p /var/lib/ctrl01
  jq -n --arg status "error" \
        --arg ip "${IP:-unknown}" \
        --arg ts "$(date -Is)" \
        --arg evidence_dir "$EV_DIR" \
        '{status:$status, ip:$ip, ts:$ts, evidence_dir:$evidence_dir}' \
        > /var/lib/ctrl01/status.json
  append_json "status" "error"
  append_json "evidence_dir" "$EV_DIR"
  exit $rc
}
trap on_err ERR

# ---- Network readiness & dpkg hygiene ---------------------------------------
# prefer IPv4 for flaky links
grep -q '::ffff:0:0/96' /etc/gai.conf 2>/dev/null || echo 'precedence ::ffff:0:0/96  100' | tee -a /etc/gai.conf >/dev/null

rm -rf /var/lib/apt/lists/* || true
apt-get clean || true
dpkg --configure -a || true

retry 20 3 bash -lc 'ping -c1 -W1 8.8.8.8 >/dev/null 2>&1'
retry 20 3 bash -lc 'getent hosts archive.ubuntu.com >/dev/null 2>&1'

# ---- System facts (evidence) -------------------------------------------------
emit "system_facts" bash -lc 'set -x; uname -a; id; df -h; lsblk; ip -br a; cat /etc/os-release'

# ---- Grow filesystem (if needed) --------------------------------------------
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

# ---- Base tools + guest agent -----------------------------------------------
retry 8 5 bash -lc 'DEBIAN_FRONTEND=noninteractive apt-get update -o Acquire::ForceIPv4=true'
emit "10_apt_install_base" bash -lc 'DEBIAN_FRONTEND=noninteractive apt-get -y install qemu-guest-agent curl git jq unzip wget tar ca-certificates make python3-pip ufw'
systemctl enable --now qemu-guest-agent || true

# ---- Toolchain (optional) ----------------------------------------------------
if [ "${ENABLE_FULL_BOOTSTRAP}" = "true" ]; then
  echo "[bootstrap] installing toolchain"
  . /etc/os-release
  curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $VERSION_CODENAME main" | tee /etc/apt/sources.list.d/hashicorp.list >/dev/null

  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor | tee /usr/share/keyrings/kubernetes-archive-keyring.gpg >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list >/dev/null

  if [ "${ENABLE_JENKINS}" = "true" ]; then
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | gpg --dearmor | tee /usr/share/keyrings/jenkins-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list >/dev/null
  fi

  retry 8 5 bash -lc 'DEBIAN_FRONTEND=noninteractive apt-get update -o Acquire::ForceIPv4=true'
  PKGS="terraform packer kubectl ansible fontconfig openjdk-17-jre-headless"
  if [ "${ENABLE_JENKINS}" = "true" ]; then PKGS="$PKGS jenkins"; fi
  emit "20_apt_install_toolchain" bash -lc "DEBIAN_FRONTEND=noninteractive apt-get -y install $PKGS"

  # Helm via official script (if not packaged)
  if ! command -v helm >/dev/null 2>&1; then
    emit "25_install_helm" bash -lc 'curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash'
  fi

  # versions
  emit "30_tool_versions" bash -lc 'set -x; terraform -v; packer -v; kubectl version --client --output=yaml || true; helm version || true; ansible --version || true'

  # Firewall (SSH + Jenkins)
  ufw allow 22/tcp || true
  [ "${ENABLE_JENKINS}" = "true" ] && ufw allow 8080/tcp || true
  yes | ufw enable || true
  emit "40_ufw_status" ufw status verbose

  # Jenkins service status (if enabled)
  if [ "${ENABLE_JENKINS}" = "true" ]; then
    systemctl enable --now jenkins || true
    emit "30b_jenkins_status" bash -lc 'set -x; systemctl status jenkins --no-pager; ss -lntp | grep :8080 || true; test -f /var/lib/jenkins/secrets/initialAdminPassword && sudo cat /var/lib/jenkins/secrets/initialAdminPassword || true'
  fi
fi

# ---- Cloud-init tail for convenience ----------------------------------------
emit "50_cloudinit_tail" bash -lc 'test -f /var/log/cloud-init-output.log && tail -n 400 /var/log/cloud-init-output.log || true'

# ---- Status JSON (final) -----------------------------------------------------
install -d -m 0755 /var/lib/ctrl01
IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
JENK=""
if [ "${ENABLE_JENKINS}" = "true" ]; then JENK="http://${IP}:8080"; fi

jq -n \
  --arg status "ok" \
  --arg ip "${IP:-unknown}" \
  --arg ts "$(date -Is)" \
  --arg evidence_dir "$EV_DIR" \
  --arg jenkins "$JENK" \
  --arg repo "${REPO_ROOT}" \
  --arg bootstrap "${ENABLE_FULL_BOOTSTRAP}" \
  '{status:$status, ip:$ip, ts:$ts, evidence_dir:$evidence_dir, jenkins:$jenkins, repo:$repo, bootstrap:$bootstrap}' \
  > /var/lib/ctrl01/status.json

append_json "status" "ok"
append_json "ip" "${IP:-unknown}"
append_json "evidence_dir" "$EV_DIR"
[ -n "$JENK" ] && append_json "jenkins" "$JENK"

echo "[bootstrap] base converge done $(date -Is)"

# ---- Adaptive hardening ------------------------------------------------------
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
  else
    echo "[bootstrap] no key found; leaving password auth enabled"
  fi
fi

echo "[bootstrap] done $(date -Is)"
append_json "finished_at" "$(date -Is)"
