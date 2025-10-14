---
title: "ctrl-01 Day-1 bootstrap & verification"
category: "bootstrap"
summary: "Validate that the control node self-bootstraps and is ready for CI/CD and platform tooling."
severity: "P2"
draft: false
template: false
tags: ["proxmox", "cloud-init", "jenkins", "terraform", "packer", "kubernetes"]
---

# ctrl-01 Day-1 bootstrap & verification

**Purpose:** Confirm Day-1 automation succeeded and the control node is ready for use.  
**Owner:** platform SRE · **Trigger:** first boot of `ctrl-01` (or manual re-run) · **ETA:** ~10–15 minutes  
**Pre-reqs:** VM created with the [Provisioner script](../../control/tools/provision/provision-ctrl01-proxmox-ubuntu.sh); network reachability; optional SSH key.  
**Rollback:** destroy/recreate the VM with Day-0; or re-run the Day-1 unit (see step 5).

> References: [ADR-0012 — Control node as a VM](../adr/ADR-0012_control-node-as-vm.md) · [How-to: Provision ctrl-01](../howto/HOWTO_ctrl01_provisioner.md) · [Evidence (latest)](../proof/ctrl01/latest/README.md)

---

## Acceptance criteria
- `/var/lib/ctrl01/status.json` shows `status:"ok"`, an IP, and a recent timestamp.
- Tool versions print successfully (Terraform, Packer, kubectl, Helm, Ansible).
- If enabled, Jenkins is `active (running)` and listening on TCP/8080.
- After the grace window (if a key exists for the user), password auth is disabled.

---

## Steps

1) **Confirm the Day-1 timer fired**
   ```bash
   sudo systemctl status ctrl01-bootstrap.timer --no-pager
   sudo journalctl -u ctrl01-bootstrap.service --no-pager | tail -n 60
   ```
   **Expected:** timer is `active (waiting)` or `elapsed`; service shows a recent run.  
   **Evidence (latest folder):** [Systemd Status](../proof/ctrl01/latest/01_systemd_status.txt)

2) **Inspect Day-1 log and status JSON**
   ```bash
   # Ensure jq is available (harmless if already installed)
   command -v jq >/dev/null || (sudo apt-get update -y && sudo apt-get install -y jq)

   sudo tail -n 200 /var/log/ctrl01_bootstrap.log
   jq . /var/lib/ctrl01/status.json
   ```
   **Expected:** log ends with `[bootstrap] done ...`; JSON includes `status:"ok"`, `ip`, `ts` and (if enabled) a `jenkins` URL.  
   **Evidence (latest folder):** [Bootstrap Log](../proof/ctrl01/latest/02_bootstrap_log.txt)

3) **Verify core toolchain**
   ```bash
   terraform -v
   packer -v
   kubectl version --client --output=yaml
   helm version
   ansible --version
   ```
   **Expected:** all commands print versions without errors.  
   **Evidence (latest folder):** [Tool Versions](../proof/ctrl01/latest/03_tool_versions.txt)

4) **Jenkins (if enabled)**
   ```bash
   sudo systemctl status jenkins --no-pager
   sudo ss -lntp | grep :8080 || true
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```
   **Expected:** `active (running)`; port `8080` listening; initial admin password present.  
   **Evidence (latest folder):** [Jenkins Status](../proof/ctrl01/latest/04_jenkins_status.txt)

5) **Re-run Day-1 (if needed)**
   ```bash
   sudo systemctl start ctrl01-bootstrap.service
   sudo journalctl -u ctrl01-bootstrap.service -f
   ```
   **Expected:** service completes successfully.  
   **Evidence:** append the final journal lines to your run record.

6) **Adaptive hardening status**
   ```bash
   AUTH=/home/$(id -un)/.ssh/authorized_keys
   test -s "$AUTH" && echo "key-present" || echo "key-missing"
   grep -E 'PasswordAuthentication|KbdInteractiveAuthentication' /etc/ssh/sshd_config.d/*.conf 2>/dev/null || true
   ```
   **Expected:** after grace window (default 10m), if a key exists, SSH password auth is disabled.  
   **Evidence (latest folder):** [SSH Configuration](../proof/ctrl01/latest/05_ssh_config.txt)

7) **Repository bootstrap**
   ```bash
   test -d /srv/hybridops/.git && echo "repo-present"      && git -C /srv/hybridops rev-parse --short HEAD      && git -C /srv/hybridops remote -v || echo "repo-missing"
   ```
   **Expected:** repo present (if configured); branch and recent commit visible.  
   **Evidence (latest folder):** [Repository Status](../proof/ctrl01/latest/06_repo_status.txt)

---

## Verification
- KPIs: toolchain installed; Day-1 completed; (if enabled) Jenkins reachable; post-grace SSH policy matches expectations.
- Dashboards: n/a (local node).
- Evidence:
  - **Latest folder:** [docs/proof/ctrl01/latest](../proof/ctrl01/latest/README.md)  
  - Typical files:  
    - [00_system_info.txt](../proof/ctrl01/latest/00_system_info.txt)  
    - [01_systemd_status.txt](../proof/ctrl01/latest/01_systemd_status.txt)  
    - [02_bootstrap_log.txt](../proof/ctrl01/latest/02_bootstrap_log.txt)  
    - [03_tool_versions.txt](../proof/ctrl01/latest/03_tool_versions.txt)  
    - [04_jenkins_status.txt](../proof/ctrl01/latest/04_jenkins_status.txt)  
    - [05_ssh_config.txt](../proof/ctrl01/latest/05_ssh_config.txt)  
    - [06_repo_status.txt](../proof/ctrl01/latest/06_repo_status.txt)  
    - [07_final_state.txt](../proof/ctrl01/latest/07_final_state.txt)

## Links
- **Provisioner script** — [provision-ctrl01-proxmox-ubuntu.sh](../../control/tools/provision/provision-ctrl01-proxmox-ubuntu.sh)  
- **Design rationale** — [ADR-0012: Control node as a VM](../adr/ADR-0012_control-node-as-vm.md)  
- **How-to** — [Provision ctrl-01 on Proxmox](../howto/HOWTO_ctrl01_provisioner.md)  
- **Evidence (latest)** — [ctrl-01 bootstrap evidence](../proof/ctrl01/latest/README.md)
