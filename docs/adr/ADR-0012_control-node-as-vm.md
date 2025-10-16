---
id: 0012
title: Control node runs as a VM (cloud-init); LXC reserved for light helpers
status: accepted
decision_date: 2025-10-12
domains: [platform, sre, infra]
tags: [proxmox, vmware, dr, cloud-init, jenkins, terraform, packer, kubernetes]
---

# ADR-0012 — Control Node as VM (`ctrl-01`)

## Context

The HybridOps Studio control plane requires a reproducible, auditable automation
hub to coordinate provisioning, CI/CD orchestration, and evidence capture.  
Two architectures were evaluated:

1. **LXC-based controller** — lightweight but lacks full kernel isolation.  
2. **VM-based controller** — heavier, but provides full systemd support and
snapshot-grade disaster-recovery semantics.

---

## Decision

Implement the control node (`ctrl-01`) as a **dedicated Proxmox VM**.

This approach ensures:

- Deterministic cloud-init provisioning independent of host state  
- Native systemd timers, services, and hardening support  
- Full DR encapsulation (snapshot, replication, or cold-standby restore)  
- Parity with enterprise-grade Jenkins controller deployments

---

## Consequences

**Positive**
- Portable, snapshot-ready control-plane image  
- Self-contained CI/CD state and audit evidence  
- Enables lifecycle automation tests under production-equivalent conditions  

**Negative**
- Slightly higher resource footprint (~4 GiB RAM baseline)  
- Marginally longer initial provisioning time versus LXC  

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

Running the control node as a full VM establishes an **independent,
snapshot-ready automation plane** that demonstrates:

- **Zero-touch provisioning**
- **Deterministic rebuilds**
- **Verifiable evidence generation**

These traits are core to HybridOps Studio’s governance, DR, and
enterprise reproducibility model.
