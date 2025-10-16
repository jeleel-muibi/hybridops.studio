# Jenkins Controller Init (`ctrl-01`)

This folder defines the **Groovy initialization scripts** executed during the
Day-1 bootstrap of the Jenkins controller (`ctrl-01`).  
They are automatically copied into `/var/lib/jenkins/init.groovy.d/`
by [`ctrl01-bootstrap.sh`](../../provision/bootstrap/ctrl01-bootstrap.sh).

Each script runs once at Jenkins startup, before any jobs or agents are launched,
ensuring a consistent, version-controlled configuration.

---

## Purpose

Provide a **secure, repeatable Jenkins baseline** that:

- Creates the initial admin user from the environment secret  
- Applies security and CSRF protection defaults  
- Defines executor limits, agent port, and CSP policy  
- Seeds the `ctrl01-bootstrap` multibranch pipeline from  
  [`core/ci-cd/jenkins`](../../../core/ci-cd/jenkins/)

---

## Files

| Script | Function |
|---------|-----------|
| **01-admin.groovy** | Creates admin user if none exists; enforces login-required access. |
| **02-security.groovy** | Configures CSRF, executors, and agent port. |
| **03-seed-mbp.groovy** | Registers the multibranch seed job pointing to the Git repo. |

---

## Execution Order

1. **Day-0:** VM created and launcher injected by  
   [`provision-ctrl01-proxmox-ubuntu.sh`](../../provision/provision-ctrl01-proxmox-ubuntu.sh)  
2. **Day-1:** [`ctrl01-bootstrap.sh`](../../provision/bootstrap/ctrl01-bootstrap.sh) installs Jenkins and copies these scripts.  
3. **Startup:** Jenkins executes them sequentially (`01-*`, `02-*`, `03-*`).  
4. **Evidence:** Output captured under [`docs/proof/ctrl01/<timestamp>/`](../../../docs/proof/ctrl01/).

---

## Design Attributes

- **Immutable:** configuration managed entirely in Git.  
- **Fail-fast:** bootstrap aborts if any script is missing.  
- **Auditable:** full logs in VM `/var/log/ctrl01_bootstrap.log`.  
- **Portable:** controller rebuildable across Proxmox or cloud clusters.

---

**Maintainer:** Jeleel Muibi  
**Component:** [`controller-init`](../../tools/jenkins/controller-init/)  
**Linked Subsystem:** [`ctrl-01`](../../../docs/proof/ctrl01/) — Jenkins Controller
