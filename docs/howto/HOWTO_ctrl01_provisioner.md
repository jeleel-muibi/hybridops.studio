---
title: "ctrl-01 Provisioner (Day-0 → Day-1 on Proxmox)"
category: "bootstrap"
summary: "Create a self-configuring control plane VM on Proxmox using a single script — the foundation of HybridOps.Studio’s zero-touch automation."
difficulty: "Intermediate"
video: "https://youtu.be/YOUR_VIDEO_ID"
draft: false
---

# HybridOps Studio — ctrl-01 Provisioner (How to Use)

**Demo:** [Watch on YouTube](https://youtu.be/YOUR_VIDEO_ID)  
**Source:** [View Script on GitHub](../../control/tools/provision/provision-ctrl01-proxmox-ubuntu.sh)

This HOWTO explains how to create a **Day-0 → Day-1** control plane VM on **Proxmox** with a single command.  
It’s designed for professionals and reviewers who want to see the automation process end-to-end — reproducible, auditable, and cloud-ready.

> **Reference:** See [ADR-0012: Control node runs as a VM (cloud-init)](../adr/ADR-0012_control-node-as-vm.md) for design rationale and constraints.

---

## Quick Start

Run these commands **on your Proxmox host**:

```bash
# 1) Upload and execute the provisioner
scp control/provision/provision-ctrl01-proxmox-ubuntu.sh root@<proxmox-ip>:/root/
ssh root@<proxmox-ip>
chmod +x /root/provision-ctrl01-proxmox-ubuntu.sh
/root/provision-ctrl01-proxmox-ubuntu.sh

# 2) After the VM boots, connect inside and monitor Day-1 progress
ssh ubuntu@172.16.10.5
sudo journalctl -u ctrl01-bootstrap.service -f
```

**Default values (customisable via environment variables):**  
Bridge: `vmbr1` IP: `172.16.10.5/28` Gateway: `172.16.10.1` DNS: `8.8.8.8`  
User: `ubuntu` Password: `TempPass123!` Bootstrap delay: 30 s  

---

## Prerequisites

- A Proxmox VE host with outbound internet access  
- A storage that supports **snippets** (`local` is auto-enabled by the script)  
- Optional SSH public key on the Proxmox host: `~/.ssh/id_rsa.pub` or `~/.ssh/id_ed25519.pub`

---

## Overview of the Provisioning Process

### Day-0 (on Proxmox)
1. Downloads the Ubuntu 22.04 (Jammy) cloud image.  
2. Generates a cloud-init file supporting both key and password login.  
3. Creates the VM, attaches cloud-init, and expands the disk (+28 GB).  
4. Configures IP, DNS, and console; boots the VM.

### Day-1 (inside the VM)
1. Expands the filesystem to use the full disk.  
2. Installs baseline packages (`qemu-guest-agent`, `curl`, `git`, `jq`, etc.).  
3. Installs **Terraform**, **Packer**, **kubectl**, **Helm**, **Ansible**, and optionally **Jenkins**.  
4. Clones the repository (`https://github.com/jeleel-muibi/hybridops.studio` → `/srv/hybridops`).  
5. Produces audit evidence: `/var/log/ctrl01_bootstrap.log`, `/var/lib/ctrl01/status.json`.  
6. Opens minimal firewall ports (SSH 22; Jenkins 8080 if enabled).  
7. Applies adaptive hardening — disables password login after the grace period once an SSH key is present.

---

## Customisation via Environment Variables

```bash
VMID=101 VMNAME=ctrl-01 BRIDGE=vmbr1 IPCIDR=172.16.10.5/28 \
GATEWAY=172.16.10.1 DNS1=8.8.8.8 CIUSER=ubuntu CIPASS='ChangeMe!' \
ENABLE_FULL_BOOTSTRAP=true ENABLE_JENKINS=true ENABLE_AUTO_HARDEN=true \
HARDEN_GRACE_MIN=10 BOOTSTRAP_DELAY_SEC=30 \
REPO_URL='https://github.com/jeleel-muibi/hybridops.studio' REPO_BRANCH=main \
REPO_DIR=/srv/hybridops /root/provision-ctrl01-proxmox-ubuntu.sh
```

**Key parameters:**  
- `ENABLE_JENKINS=false` — skip Jenkins setup (port 8080 not opened).  
- `ENABLE_AUTO_HARDEN=false` — keep password authentication active.  
- `HARDEN_GRACE_MIN=20` — wait 20 min before enforcing key-only SSH.  
- `BOOTSTRAP_DELAY_SEC=60` — start Day-1 after 60 seconds.

---

## Verifying Success

Inside the VM:

```bash
sudo journalctl -u ctrl01-bootstrap.service --no-pager | tail -n 60
sudo tail -n 200 /var/log/ctrl01_bootstrap.log
cat /var/lib/ctrl01/status.json

terraform -v
packer -v
kubectl version --client --output=yaml
helm version
ansible --version
```

If Jenkins was enabled:
```bash
sudo systemctl status jenkins --no-pager
sudo ss -lntp | grep :8080 || true
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

**Success indicators:**  
- Jenkins reachable (if enabled)  
- All CLI tools operational  
- `status.json` shows `"phase": "bootstrap-complete"`

---

## Related Documentation

- ADR 0012 — [Control node runs as a VM](../adr/ADR-0012_control-node-as-vm.md)  
- Runbook — [ctrl-01 bootstrap / verification](../runbooks/bootstrap/bootstrap-ctrl01-node.md)  
- Script — [`control/provision/provision-ctrl01-proxmox-ubuntu.sh`](../../control/tools/provision/provision-ctrl01-proxmox-ubuntu.sh)

---

## Security Notes

- The default password is for initial bootstrap only.  
- Adaptive hardening automatically disables password login once a key is present.  
- UFW allows only SSH (22/tcp); Jenkins (8080/tcp) opens only when explicitly enabled.  
- Log and status artifacts are immutable for audit and evidence purposes.

---

**Maintainer:** HybridOps.Studio
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
