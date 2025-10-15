## Jenkins Controller Bootstrap (ctrl-01)

This directory contains the **Day-1 automation scripts** that transform a fresh
Ubuntu VM into a fully configured Jenkins controller (`ctrl-01`).  
These scripts are executed automatically by the **Day-0 provisioner** running on Proxmox.

All logic is deterministic and auditable, ensuring that every controller build
is identical, version-controlled, and evidence-producing.

---

### Purpose

To provide a **zero-touch bootstrap path** that:

- Installs and configures Jenkins from Git
- Imports controller-initialization Groovy scripts from  
  `control/tools/jenkins/controller-init`
- Captures runtime evidence under `docs/proof/ctrl01/<timestamp>/`
- Enforces SSH hardening automatically after bootstrap

---

### Files

| File | Description |
|-------|-------------|
| **ctrl01-bootstrap.sh** | Primary Day-1 script. Installs Jenkins, imports Groovy controller-init files, hardens SSH, and produces system evidence. |
| **ctrl01-collect-evidence.sh** | Post-bootstrap collector. Gathers logs, service state, repo metadata, and configuration proofs into a timestamped folder under `docs/proof/ctrl01/`. Includes a `latest` symlink for CI automation. |
| **provision-ctrl01-proxmox-ubuntu.sh** *(Day-0, sibling script)* | Proxmox-side provisioner. Creates the ctrl-01 VM, injects cloud-init metadata, and wires in the Day-1 launcher for fully unattended bootstrap. |

---

### Execution Flow

1. **Day-0 (Proxmox host)**
   - Run `provision-ctrl01-proxmox-ubuntu.sh` to create the VM.
   - The script injects a cloud-init snippet that clones this repository and starts the Day-1 bootstrap after a short delay (default: 1 minute).

2. **Day-1 (inside ctrl-01 VM)**
   - `ctrl01-bootstrap.sh` installs Jenkins, imports controller-init Groovy scripts, and enables the seed pipeline.
   - Jenkins starts, runs initialization scripts, and begins serving on port 8080.

3. **Evidence generation**
   - `ctrl01-collect-evidence.sh` runs automatically to produce audit-grade artifacts under `docs/proof/ctrl01/<timestamp>/` and updates  
     a symlink `docs/proof/ctrl01/latest` → `<timestamp>` for the most recent run.

---

### Design Notes

- **Fail-fast:** Bootstrap aborts immediately if essential environment variables or paths are missing.  
- **Stateless:** Jenkins configuration and jobs live entirely in Git; the VM is disposable.  
- **Auditable:** Every run logs to `/var/log/ctrl01_bootstrap.log` and emits structured evidence (system, service, repo, SSH, version).  
- **Hardened:** SSH password authentication is disabled automatically after a configurable grace period (default 10 minutes).  
- **Evidence Integrity:** Each run produces a self-contained folder with a linked `README.md` showing both its static location and `latest` symlink reference.  

---

**Maintainer:** Jeleel Muibi  
**Component:** `control/tools/provision/bootstrap`  
**Linked subsystem:** `ctrl-01` (Jenkins controller)
