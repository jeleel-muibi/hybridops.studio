# Jenkins Controller Bootstrap (`ctrl-01`)

This directory contains the **Day-0 and Day-1 automation stack** for provisioning
and configuring the Jenkins control plane (`ctrl-01`).  
All stages are **self-contained, Git-driven**, and emit verifiable evidence for
audit and disaster-recovery validation.

---

## Purpose

Deliver a **zero-touch control-plane bootstrap** that:

- Provisions a fresh Ubuntu VM on Proxmox (**Day-0**)  
- Installs and configures Jenkins autonomously (**Day-1**)  
- Imports Groovy initialization scripts from [`controller-init`](../../tools/jenkins/controller-init/)  
- Captures runtime artifacts under [`docs/proof/ctrl01/<timestamp>/`](../../../docs/proof/ctrl01/)  
- Enforces SSH hardening automatically after a short grace period (default: 2 min)

---

## File Overview

| Path | Role |
|------|------|
| **bootstrap/ctrl01-bootstrap.sh** | Day-1 routine — installs Jenkins, applies controller-init scripts, triggers evidence collection, and hardens SSH. |
| **evidence/ctrl01-collect-evidence.sh** | Post-bootstrap collector — aggregates logs, service states, Git metadata, and configuration proofs under `docs/proof/ctrl01/<timestamp>/`, maintaining a `latest` symlink. |
| **provision-ctrl01-proxmox-ubuntu.sh** | Day-0 provisioner — creates the VM, injects cloud-init metadata, and schedules Day-1 bootstrap automatically. |

---

## Execution Flow

1. **Day-0 (Proxmox host)**  
   Run [`provision-ctrl01-proxmox-ubuntu.sh`](./provision-ctrl01-proxmox-ubuntu.sh) to create the VM and inject a cloud-init snippet that clones this repo and schedules the Day-1 bootstrap (default delay ≈ 1 min).

2. **Day-1 (inside `ctrl-01`)**  
   [`ctrl01-bootstrap.sh`](./bootstrap/ctrl01-bootstrap.sh) installs Jenkins, executes controller-init Groovy scripts, and starts Jenkins on port 8080.

3. **Evidence Generation**  
   [`ctrl01-collect-evidence.sh`](./evidence/ctrl01-collect-evidence.sh) gathers runtime artifacts and writes timestamped audit bundles under [`docs/proof/ctrl01/<timestamp>/`](../../../docs/proof/ctrl01/), updating `latest → <timestamp>` for CI traceability.

---

## Design Attributes

- **Fail-fast:** aborts immediately on missing variables or paths.  
- **Stateless:** Jenkins configuration and pipelines live entirely in Git — VM is disposable.  
- **Auditable:** logs captured under `/var/log/ctrl01_bootstrap.log`.  
- **Hardened:** SSH password authentication auto-disabled after ≈ 2 min.  
- **Evidence-anchored:** each run creates a self-describing folder with a linked `README.md`.

---

**Maintainer:** Jeleel Muibi  
**Component:** [`control/tools/provision`](../../tools/provision/)  
**Linked Subsystem:** [`ctrl-01`](../../../docs/proof/ctrl01/) — Jenkins Controller
