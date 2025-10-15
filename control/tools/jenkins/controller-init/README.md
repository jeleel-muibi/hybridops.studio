# Jenkins Controller Init (ctrl-01)

This directory defines the **controller-level Groovy initialization scripts** for the HybridOps Studio Jenkins environment.  
All files in this folder are automatically copied into `/var/lib/jenkins/init.groovy.d/` by the **Day-1 bootstrap script** (`ctrl01-bootstrap.sh`) during the first startup of the `ctrl-01` VM.

These scripts run **once at Jenkins startup**, before any jobs or agents launch, making the controller completely reproducible and aligned with the Infrastructure-as-Code model.

---

### Purpose

To enable a **zero-touch Jenkins controller** that:

- Is fully configured from Git on first boot  
- Enforces secure defaults (admin account, CSRF policy, agent port, content security)  
- Seeds pipelines automatically from [`core/ci-cd/jenkins`](../../../core/ci-cd/jenkins)  
- Produces repeatable, verifiable states for disaster recovery and audit evidence  

---

### Files

| File | Description |
|------|--------------|
| **01-admin.groovy** | Creates the initial admin user if none exists (using `JENKINS_ADMIN_PASS` from environment). Enforces logged-in-only access. |
| **02-security.groovy** | Applies security defaults: CSRF protection, agent port policy, limited executors, and hardened content security rules. |
| **03-seed-mbp.groovy** | Defines the multibranch seed job (`ctrl01-bootstrap`) that discovers pipelines under [`core/ci-cd/jenkins`](../../../core/ci-cd/jenkins/). |

---

### Execution Flow

1. **Day-0:** [`provision-ctrl01-proxmox-ubuntu.sh`](../bootstrap/provision-ctrl01-proxmox-ubuntu.sh)  
   creates the VM and injects the Day-1 launcher.

2. **Day-1:** [`ctrl01-bootstrap.sh`](../bootstrap/ctrl01-bootstrap.sh)  
   installs Jenkins and copies these Groovy scripts into `/var/lib/jenkins/init.groovy.d/`.

3. **Jenkins startup:**  
   executes the scripts in lexicographic order (`01-*`, `02-*`, `03-*`) to configure the controller, create the seed job, and enable Git-based pipelines.

4. **Evidence:**  
   post-bootstrap, [`ctrl01-collect-evidence.sh`](../bootstrap/ctrl01-collect-evidence.sh)  
   captures operational proofs in `docs/proof/ctrl01/<timestamp>/`.

---

### Design Principles

- **Fail-fast:** bootstrap aborts if this directory or its files are missing.  
- **Immutable:** no manual configuration; all state is version-controlled.  
- **Auditable:** every run logs to `/var/log/ctrl01_bootstrap.log` and emits evidence.  
- **Portable:** identical controller rebuilds are possible on any Proxmox or cloud target.  

---

**Maintainer:** Jeleel Muibi  
**Component:** `control/tools/jenkins/controller-init`  
**Linked subsystems:**  
→ [`ctrl01-bootstrap.sh`](../bootstrap/ctrl01-bootstrap.sh)  
→ `/var/lib/jenkins/init.groovy.d/` (runtime target)
