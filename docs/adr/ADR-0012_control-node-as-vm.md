---
id: 0012
title: Control node runs as a VM (cloud‑init); LXC reserved for light helpers
status: accepted
decision_date: 2025-10-12
domains: [platform, sre, infra]
tags: [proxmox, vmware, dr, cloud-init, jenkins, terraform, packer, kubernetes]
---

# ADR-0012 — Control Node runs as a full VM (not LXC)

## Context
We need a reproducible “control node” that hosts CI/CD and platform tooling (Terraform, Packer, kubectl, Helm, Ansible, optional Jenkins). It must be portable across hypervisors (Proxmox now, VMware/cloud later), easy to back up / DR, and compatible with systemd services, kernel modules, and vendor repos.

## Decision
Run the control node as a **full VM** (Ubuntu LTS) instead of an LXC container.

## Rationale
- **Portability & DR:** VM images export/import cleanly; snapshots/backups are standard.
- **Compatibility:** Fewer surprises with systemd, cgroups, kernel deps, and vendor APT repos.
- **Security posture:** Clean OS boundaries; predictable SSH and firewall behavior.
- **Operational clarity:** Day-0 (Proxmox) + Day-1 (in-guest) split. Day-1 runs under systemd.

## Implementation notes
- **Day-0 (Proxmox):**  
  Creates the VM with static IP, console, cloud-init user, password + optional SSH key, and writes a minimal Day-1 launcher unit/timer.
- **Day-1 (in-guest):**  
  Installs toolchain, optionally Jenkins, clones the repo (if configured), then applies **adaptive hardening**: after a grace window, if a public key is present for the login user, disable password auth and rotate the temporary password.
- **Artifacts:**  
  - Logs: `/var/log/ctrl01_bootstrap.log`  
  - Status JSON: `/var/lib/ctrl01/status.json`  
  - Evidence (latest): `docs/proof/ctrl01/latest/` (see links below)

## Security considerations
- Day-0 **intentionally enables** both **password + key** for deterministic first access across devices.  
- Day-1 **disables password auth** (and rotates the temp password) **iff** an SSH public key is present for the CI user, after a grace window (default 10 min).  
- UFW enables SSH (22) and optionally Jenkins (8080) when Jenkins is installed.

## Operational risks & mitigations
- **apt/dpkg interruptions:** Retried; `dpkg --configure -a` used on failure; IPv4 DNS preference reduces flakiness.
- **DNS/network hiccups:** `gai.conf` precedence tweak prefers IPv4; explicit retries around `apt-get update` and repo key fetches.
- **Jenkins optionality:** Controlled by env flags; failure won’t block the rest of Day-1.

## Consequences
- Slightly heavier than LXC; acceptable for the benefits listed.
- Clean “Day-0 → Day-1” flow is easier to reason about, test, and present to assessors.

## References
- **How-to (walkthrough):** [Provision ctrl-01 on Proxmox](../howto/HOWTO_ctrl01_provisioner.md)
- **Runbook (ops/verify):** [ctrl-01 Day-1 bootstrap & verification](../runbooks/bootstrap-ctrl01-node.md)
- **Provisioner script:** [provision-ctrl01-proxmox-ubuntu.sh](../../control/tools/provision/provision-ctrl01-proxmox-ubuntu.sh)
- **Evidence (latest):** [ctrl-01 bootstrap evidence](../proof/ctrl01/latest/README.md)
