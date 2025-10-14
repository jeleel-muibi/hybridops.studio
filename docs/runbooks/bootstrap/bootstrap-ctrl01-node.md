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

**Purpose**: Confirm Day‑1 automation succeeded and the control node is ready for use.  
**Owner**: platform SRE · **Trigger**: first boot of `ctrl-01` (or manual re-run) · **ETA**: ~10–15 minutes  
**Pre-reqs**: VM created using the [Provisioner script](../../../control/provision/provision-ctrl01-proxmox-ubuntu.sh); network reachability; optional SSH key.  
**Rollback**: destroy/recreate the VM with the Day‑0 script; or re‑run the Day‑1 unit (see step 5).

> References: [ADR‑0012 — Control node as a VM](../../adr/ADR-0012_control-node-as-vm.md) · [How‑to: Provision ctrl‑01](../../howto/HOWTO_ctrl01_provisioner.md) · [Runbook index](../README.md) · [Evidence Map](../../evidence_map.md).

---

## Steps

1) **Confirm Day‑1 timer fired**
   - Command:
     ```bash
     sudo systemctl status ctrl01-bootstrap.timer --no-pager
     sudo journalctl -u ctrl01-bootstrap.service --no-pager | tail -n 60
     ```
   - Expected: timer is `active (waiting)` or `elapsed`; service shows a recent run.
   - Evidence: capture outputs and store per the [Evidence Map](../../evidence_map.md).

2) **Inspect Day‑1 log and status JSON**
   - Command:
     ```bash
     sudo tail -n 200 /var/log/ctrl01_bootstrap.log
     cat /var/lib/ctrl01/status.json
     ```
   - Expected: log ends with `[bootstrap] done ...`; JSON contains `status:"ok"`, `ip`, `ts`, and (if enabled) a `jenkins` URL.
   - Evidence: capture log tail and JSON; store per the [Evidence Map](../../evidence_map.md).

3) **Verify core toolchain**
   - Command:
     ```bash
     terraform -v
     packer -v
     kubectl version --client --output=yaml
     helm version
     ansible --version
     ```
   - Expected: all tools report versions without errors.
   - Evidence: capture versions; store per the [Evidence Map](../../evidence_map.md).

4) **Jenkins (if enabled)**
   - Command:
     ```bash
     sudo systemctl status jenkins --no-pager
     sudo ss -lntp | grep :8080 || true
     sudo cat /var/lib/jenkins/secrets/initialAdminPassword
     ```
   - Expected: service `active (running)`; port `8080` listening; initial admin password present.
   - Evidence: capture outputs; store per the [Evidence Map](../../evidence_map.md).

5) **Re‑run Day‑1 (if needed)**
   - Command:
     ```bash
     sudo systemctl start ctrl01-bootstrap.service
     sudo journalctl -u ctrl01-bootstrap.service -f
     ```
   - Expected: service completes without error.
   - Evidence: capture journal tail; store per the [Evidence Map](../../evidence_map.md).

6) **Adaptive hardening status**
   - Command:
     ```bash
     AUTH=/home/$(id -un)/.ssh/authorized_keys
     test -s "$AUTH" && echo "key-present" || echo "key-missing"
     grep -E 'PasswordAuthentication|KbdInteractiveAuthentication' /etc/ssh/sshd_config.d/*.conf 2>/dev/null || true
     ```
   - Expected: after the grace window, if a key is present, password auth is disabled (`PasswordAuthentication no`).
   - Evidence: capture outputs; store per the [Evidence Map](../../evidence_map.md).

7) **Repo bootstrap**
   - Command:
     ```bash
     test -d /srv/hybridops/.git && echo "repo-present" &&        git -C /srv/hybridops rev-parse --short HEAD &&        git -C /srv/hybridops remote -v
     ```
   - Expected: repository present on the expected branch; recent commit hash visible.
   - Evidence: capture commit/ref details; store per the [Evidence Map](../../evidence_map.md).

---

## Verification
- KPIs: toolchain installed; Day‑1 completed; (optional) Jenkins reachable; post‑grace SSH policy matches expectation.
- Dashboards: n/a (local node), or add CI node health if applicable.
- Evidence: attach artifacts according to the [Evidence Map](../../evidence_map.md).

## Links
- **Provisioner script** — [provision-ctrl01-proxmox-ubuntu.sh](../../../control/tools/provision/provision-ctrl01-proxmox-ubuntu.sh)
- **Design rationale** — [ADR‑0012: Control node as a VM](../../adr/ADR-0012_control-node-as-vm.md)  
- **How‑to** — [Provision ctrl‑01 on Proxmox](../../howto/HOWTO_ctrl01_provisioner.md)  
- **Runbook index** — [Bootstrap category](../README.md)  
- **Evidence Map** — [Claims → proofs index](../../evidence_map.md)
