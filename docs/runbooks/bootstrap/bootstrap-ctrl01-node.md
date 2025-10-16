---
title: "ctrl-01 Day-1 bootstrap & verification"
category: "bootstrap"
summary: "Validate that the control node self-bootstraps and is ready for CI/CD and platform tooling."
severity: "P2"
draft: false
template: false
tags: ["proxmox", "cloud-init", "jenkins", "terraform", "packer", "kubernetes"]
---

# Bootstrap Validation — `ctrl-01` (Jenkins Controller)

> **Context:** Validation report for the Day-1 bootstrap stage defined in  
> [`control/tools/provision`](../../control/tools/provision/README.md).

---

## Purpose

Validate that the automated Day-1 workflow successfully installs, configures,
and secures the Jenkins controller (`ctrl-01`) created by the Day-0 provisioner.

---

## Validation Summary

| Checkpoint | Status | Description |
|-------------|---------|-------------|
| Cloud-init executed | ✅ | Systemd timer `ctrl01-bootstrap.timer` started automatically. |
| Jenkins installation | ✅ | Jenkins 2.x with OpenJDK 17 installed from official Debian repo. |
| Controller-init scripts | ✅ | All Groovy files (`01-admin`, `02-security`, `03-seed-mbp`) executed in sequence. |
| Seed job creation | ✅ | `ctrl01-bootstrap` multibranch job discovered pipelines under [`core/ci-cd/jenkins`](../../core/ci-cd/jenkins/). |
| Evidence collector | ✅ | Proofs written to `docs/proof/ctrl01/<timestamp>/`. |
| SSH hardening | ✅ | Password login disabled automatically after 2 minutes. |

---

## Evidence Snapshot

- `/var/log/ctrl01_bootstrap.log` — bootstrap transcript  
- `/var/lib/ctrl01/status.json` — runtime metadata (IP, port, timestamp)  
- `docs/proof/ctrl01/<timestamp>/` — structured audit bundle with `latest` link  

---

## Observations

- End-to-end bootstrap completed with no manual input.  
- Cloud-init and systemd orchestration verified stable.  
- Jenkins became reachable on port 8080 within ~3 minutes.  
- Evidence collector executed in soft-strict mode, producing full audit output.  

---

## Conclusion

The `ctrl-01` bootstrap satisfies HybridOps Studio standards for  
**zero-touch automation**, **auditability**, and **DR readiness**.
