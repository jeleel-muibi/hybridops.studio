# Jenkins Controller Bootstrap (`ctrl-01`)

This directory contains the **Day-0 and Day-1 automation stack** that provisions
and configures the Jenkins control plane (`ctrl-01`).  
All stages are fully automated, Git-driven, and emit verifiable evidence for
audit and disaster-recovery validation.

---

## Purpose

Deliver a **zero-touch bootstrap workflow** that:

- Provisions a clean Ubuntu VM on Proxmox (`Day-0`)  
- Installs and configures Jenkins automatically (`Day-1`)  
- Imports Groovy initialization scripts from [`controller-init`](../../tools/jenkins/controller-init/)  
- Captures runtime artifacts under [`docs/proof/ctrl01/<timestamp>/`](../../../docs/proof/ctrl01/)
- Enforces SSH hardening after a short grace period (default 2 min)

---

## Files

| Path | Role |
|------|------|
| **bootstrap/ctrl01-bootstrap.sh** | Day-1 installer: sets up Jenkins, runs controller-init scripts, triggers evidence collection, and enforces SSH hardening. |
| **evidence/ctrl01-collect-evidence.sh** | Collector: aggregates logs, service states, Git metadata, and config proofs into `docs/proof/ctrl01/<timestamp>/`, maintaining a `latest` symlink. |
| **provision-ctrl01-proxmox-ubuntu.sh** | Day-0 provisioner: creates the VM, injects cloud-init configuration, and schedules the Day-1 bootstrap automatically. |

---

## Execution Flow

1. **Day-0 (Proxmox host)**  
   Run the [`provision-ctrl01-proxmox-ubuntu.sh`](./provision-ctrl01-proxmox-ubuntu.sh) script to create the VM and inject a cloud-init snippet that clones this repository and schedules the Day-1 bootstrap (default delay ≈ 1 minute).

2. **Day-1 (inside `ctrl-01`)**  
   [`ctrl01-bootstrap.sh`](./bootstrap/ctrl01-bootstrap.sh) installs Jenkins, executes controller-init Groovy scripts, and starts the Jenkins service on port 8080.

3. **Evidence Generation**  
   [`ctrl01-collect-evidence.sh`](./evidence/ctrl01-collect-evidence.sh) gathers runtime artifacts and writes timestamped audit bundles under [`docs/proof/ctrl01/<timestamp>/`](../../../docs/proof/ctrl01/), updating `latest → <timestamp>` for CI traceability.

---

## Design Attributes

- **Fail-fast:** aborts immediately on missing variables or required paths.  
- **Stateless:** Jenkins configuration and pipelines live entirely in Git; the VM is disposable.  
- **Auditable:** all logs stored under `/var/log/ctrl01_bootstrap.log`.  
- **Hardened:** SSH password authentication disabled automatically after ≈ 2 minutes.  
- **Evidence Integrity:** each run creates a self-describing folder with cross-linked `README.md`.

---

**Maintainer:** Jeleel Muibi  
**Component:** [`provision`](../../tools/provision/)  
**Linked Subsystem:** [`ctrl-01`](../../../docs/proof/ctrl01/) — Jenkins Controller
