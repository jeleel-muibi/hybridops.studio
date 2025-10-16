---
id: 0012
title: Control node runs as a VM (cloud‑init); LXC reserved for light helpers
status: accepted
decision_date: 2025-10-12
domains: [platform, sre, infra]
tags: [proxmox, vmware, dr, cloud-init, jenkins, terraform, packer, kubernetes]
---

# ADR-0012 — Control Node as VM (`ctrl-01`)

## Context

The HybridOps Studio control plane requires a reproducible, auditable automation
hub to coordinate provisioning, CI/CD orchestration, and evidence capture.
Two architectural options were considered:

1. **LXC-based controller** — lightweight, but limited kernel isolation.  
2. **Full VM controller** — slightly heavier, but provides clean kernel boundaries,
   systemd isolation, and snapshot-grade disaster recovery.

---

## Decision

Implement the control node (`ctrl-01`) as a **dedicated Proxmox VM**.

This approach provides:

- Deterministic cloud-init provisioning independent of host state  
- Native systemd support for timers, services, and hardening  
- Full DR encapsulation (VM snapshot, replication, or cold-standby restore)  
- Realistic parity with enterprise Jenkins controller deployments

---

## Consequences

**Positive**
- VM image is portable and reproducible across hosts or clouds.  
- CI/CD and audit evidence remain self-contained.  
- Enables lifecycle automation testing under production-equivalent conditions.  

**Negative**
- Slightly higher resource footprint (~4 GiB RAM baseline).  
- Longer initial provisioning time versus LXC.

---

## Linked Artifacts

| Phase | Artifact | Path |
|--------|-----------|------|
| Day-0 | Provisioner | [`provision-ctrl01-proxmox-ubuntu.sh`](../../control/tools/provision/provision-ctrl01-proxmox-ubuntu.sh) |
| Day-1 | Bootstrap | [`ctrl01-bootstrap.sh`](../../control/tools/provision/bootstrap/ctrl01-bootstrap.sh) |
| Controller Init | Groovy scripts | [`controller-init`](../../control/tools/jenkins/controller-init/) |
| Validation | Evidence bundle | [`docs/proof/ctrl01/`](../../docs/proof/ctrl01/) |

---

## Outcome

Running the control node as a full VM ensures an **independent, snapshot-ready
control plane** that demonstrates **zero-touch provisioning**, **deterministic rebuilds**,  
and **verifiable evidence** — core tenets of HybridOps Studio.
