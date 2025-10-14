---
id: 0012
title: Control node runs as a VM (cloud‑init); LXC reserved for light helpers
status: accepted
decision_date: 2025-10-12
domains: [platform, sre, infra]
tags: [proxmox, vmware, dr, cloud-init, jenkins, terraform, packer, kubernetes]
---

# ADR-0012: Control node runs as a VM (cloud‑init)

## Context
We need a repeatable **control node** (`ctrl-01`) to host CI/CD and platform tooling (Jenkins, Terraform, Packer, kubectl/helm, repo bootstrap). The node must be **portable** (Proxmox ⇄ VMware), **fast to recover** in DR, and isolated from host-level quirks.

Running this as an LXC container is lightweight but creates friction around systemd services, kernel/cgroup features, and migration. A **VM** avoids those edge cases and makes export/import simple.

## Decision
Run `ctrl-01` as a **full VM** provisioned with **cloud-init** on Proxmox. Keep LXC for small, stateless helpers only.

## Decision Drivers
- **Portability:** OVA/OVF export/import to VMware with no format gymnastics.
- **Isolation:** Clean systemd, networking, and package boundaries (no LXC caps/cgroup gaps).
- **DR speed:** Snapshot/replicate/restore the VM anywhere.
- **Predictability:** Fewer host-kernel interactions vs. unprivileged LXC.

## Options Considered
- **LXC for `ctrl-01`** — Light & fast, but brittle for Jenkins/services and not VMware‑friendly.
- **Full VM for `ctrl-01`** — Slightly heavier, but portable and robust. **Chosen.**

## Consequences
- + Simple DR/export to VMware.
- + Fewer surprises with system services/tooling.
- − Slightly more RAM/CPU vs. LXC (acceptable for a single VM).

## Scope & Boundaries
- **In scope:** Jenkins (optional), HashiCorp tools (Terraform, Packer), Kubernetes CLIs (kubectl/Helm), repo bootstrap, Day‑0/Day‑1 chain, audit artifacts.
- **Out of scope:** Databases, Kubernetes control plane (handled by separate ADRs).

## Implementation Notes (normative)
- **Base image:** Ubuntu 22.04 cloud image (Jammy) via Proxmox cloud‑init.
- **Network:** Static IP on a dedicated bridge (e.g., `vmbr1`, `172.16.10.0/28`).
- **Access pattern:** Day‑0 enables *both* password and SSH key for deterministic access.
- **Day‑1 orchestration:** systemd timer triggers `/usr/local/sbin/ctrl01-bootstrap` to install toolchain, clone repo (`${REPO_URL}` → `${REPO_DIR}` on branch `${REPO_BRANCH}`), open minimal firewall, write `/var/lib/ctrl01/status.json`, and **adaptive hardening** disables password auth after grace period if an SSH key is present.
- **Artifacts:** Logs under `/var/log/ctrl01_bootstrap.log` for auditability.

## References
- **How‑to:** [Provision ctrl‑01 on Proxmox](../howto/HOWTO_ctrl01_provisioner.md)
- **Runbook:** [ctrl‑01 Day‑1 bootstrap & verification](../runbooks/bootstrap/bootstrap-ctrl01-node.md)
- **Provisioner script:** [provision-ctrl01-proxmox-ubuntu.sh](../../control/tools/provision/provision-ctrl01-proxmox-ubuntu.sh)
- **ADR index:** [Architecture Decision Records](./README.md)
