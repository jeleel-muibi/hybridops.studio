\
# HybridOps Studio — ctrl‑01 Provisioner (How to Use)

This guide shows you how to create a **Day‑0 → Day‑1** control node VM on **Proxmox** with a single script.
It’s written for newcomers (YouTube friendly) and for assessors who want a clear, auditable flow.

> 📌 **Why this exists**  
> See [ADR‑0012: Control node runs as a VM (cloud‑init)](../adr/ADR-0012_control-node-as-vm.md) for the rationale, scope, and constraints.

---

## TL;DR (Copy‑Paste)

On your **Proxmox host**:

```bash
# 1) Upload and run
scp control/provision/provision-ctrl01-proxmox-ubuntu.sh root@<proxmox-ip>:/root/
ssh root@<proxmox-ip>
chmod +x /root/provision-ctrl01-proxmox-ubuntu.sh
/root/provision-ctrl01-proxmox-ubuntu.sh

# 2) After boot, go inside the VM and follow Day‑1
ssh ubuntu@172.16.10.5            # default IP from script (change if needed)
sudo journalctl -u ctrl01-bootstrap.service -f
```

**Defaults** (override via env vars):  
- Bridge: `vmbr1`  
- IP: `172.16.10.5/28` / GW `172.16.10.1` / DNS `8.8.8.8`  
- User: `ubuntu` / Pass: `TempPass123!`  
- Day‑1 starts **30s** after first boot

---

## Prerequisites

- Proxmox host with internet access
- A storage that supports **snippets** (the script auto‑enables for `local` if possible)
- An SSH public key on the Proxmox host (optional but recommended):  
  `~/.ssh/id_rsa.pub` or `~/.ssh/id_ed25519.pub`

---

## What the script does (in plain English)

### Day‑0 (on Proxmox)
1. Downloads Ubuntu 22.04 cloud image (Jammy).
2. Writes a **cloud‑init** file that enables password **and** key login.
3. Creates the VM, attaches cloud‑init, and **expands disk** (+28GB).
4. Sets static IP, DNS, and console options; then boots the VM.

### Day‑1 (inside the VM, auto)
1. Grows the root partition/filesystem to use the expanded disk.
2. Installs base tools: `qemu-guest-agent curl git jq unzip wget tar ca-certificates make python3-pip ufw`.
3. Installs **Terraform, Packer, kubectl, Helm, Ansible** and **(optional) Jenkins**.
4. **Clones your repo** (defaults to `https://github.com/jeleel-muibi/hybridops.studio` → `/srv/hybridops`).  
5. Creates audit artifacts: `/var/log/ctrl01_bootstrap.log`, `/var/lib/ctrl01/status.json`.
6. Opens firewall (SSH 22; Jenkins 8080 only if enabled).
7. **Adaptive hardening:** after a grace (default 10 min), if an SSH key is present → disable password auth.

---

## Customising (env vars)

Pass these **before** the script call on Proxmox:

```bash
VMID=101 VMNAME=ctrl-01 BRIDGE=vmbr1 IPCIDR=172.16.10.5/28 GATEWAY=172.16.10.1 \
DNS1=8.8.8.8 CIUSER=ubuntu CIPASS='ChangeMe!' \
ENABLE_FULL_BOOTSTRAP=true ENABLE_JENKINS=true ENABLE_AUTO_HARDEN=true \
HARDEN_GRACE_MIN=10 BOOTSTRAP_DELAY_SEC=30 \
REPO_URL='https://github.com/jeleel-muibi/hybridops.studio' REPO_BRANCH=main REPO_DIR=/srv/hybridops \
/root/provision-ctrl01-proxmox-ubuntu.sh
```

Key flags:
- `ENABLE_JENKINS=false` → skip Jenkins (no 8080 hole in UFW).
- `ENABLE_AUTO_HARDEN=false` → keep password auth for demos.
- `HARDEN_GRACE_MIN=20` → wait 20 minutes before hardening.
- `BOOTSTRAP_DELAY_SEC=60` → start Day‑1 after 60 seconds.

---

## Verifying success

Inside the VM:
```bash
# Day‑1 logs and status
sudo journalctl -u ctrl01-bootstrap.service --no-pager | tail -n 60
sudo tail -n 200 /var/log/ctrl01_bootstrap.log
cat /var/lib/ctrl01/status.json

# CLI tools
terraform -v; packer -v; kubectl version --client --output=yaml
helm version; ansible --version

# Jenkins (if enabled)
sudo systemctl status jenkins --no-pager
sudo ss -lntp | grep :8080 || true
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

## Related docs
- ADR: [0012 – Control node runs as a VM](../adr/ADR-0012_control-node-as-vm.md)
- Runbook: [ctrl‑01 bootstrap / verification](../runbooks/bootstrap/bootstrap-ctrl01-node.md)
- Script: [`control/provision/provision-ctrl01-proxmox-ubuntu.sh`](../../control/tools/provision/provision-ctrl01-proxmox-ubuntu.sh)

---

## Security notes (important for assessors)
- Default password is for first‑boot convenience only; change it or rely on SSH keys.
- Adaptive hardening disables password auth once a key is present after the grace window.
- UFW defaults to allow SSH only; Jenkins port is opened **only** if Jenkins is enabled.
