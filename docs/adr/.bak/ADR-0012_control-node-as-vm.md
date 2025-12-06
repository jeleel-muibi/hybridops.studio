---
id: ADR-0012
title: "Control Node Runs as a VM (cloud-init); LXC Reserved for Light Helpers"
status: Accepted
date: 2025-10-12
domains: ["platform", "sre", "infra"]
supersedes: []
superseded_by: []
links:
  prs: []
  runbooks: ["../runbooks/bootstrap/bootstrap-ctrl01-node.md"]
  evidence: ["../proof/ctrl01-bootstrap/"]
  diagrams: ["../diagrams/control_plane_architecture.png"]
---

# Control Node Runs as a VM (Cloud-Init); LXC Reserved for Light Helpers

## Status
Accepted — The primary control plane (`ctrl-01`) is now provisioned as a **full VM** with Cloud-Init automation, while lightweight helper functions remain on LXC containers.

## Context
Early experiments used **LXC containers** for both control and execution nodes to save resources.  
However, Jenkins and Terraform processes require full virtualization primitives such as:
- predictable systemd isolation,
- persistent kernel modules for nested automation, and  
- clean device mapping for Terraform providers (e.g., Proxmox, libvirt).

Containerized control nodes introduced subtle breakages (e.g., missing cgroups, limited kernel access) that reduced reproducibility and broke pipeline jobs requiring elevated permissions.

## Decision
Migrate the primary control plane (`ctrl-01`) to a **Proxmox VM** provisioned entirely via **Cloud-Init**, keeping LXCs only for **auxiliary services** (e.g., lightweight agents, builders, or monitoring helpers).

### Key Principles
- **VM-based control:** Jenkins, Terraform, Packer, and Ansible run on a full VM.  
- **Cloud-Init first:** Day-0 bootstrap creates a ready-to-configure host within 10 minutes.  
- **Evidence-driven:** all bootstrap logs stored in `docs/proof/ctrl01-bootstrap/`.  
- **LXC reserved:** only for ephemeral or non-privileged helper roles (e.g., docs generator, log relay).  
- **Reproducibility:** exact same control plane can be rebuilt on Proxmox, VMware, or KVM.

## Implementation Summary
- VM image: Ubuntu 22.04 cloud image (Jammy).  
- Provisioning: automated via `provision-ctrl01-proxmox-ubuntu.sh`.  
- Configuration: post-bootstrap Jenkins jobs orchestrate full DR sync and evidence capture.  
- Evidence: automatically timestamped under `docs/proof/ctrl01-bootstrap/<date>/`.

## Consequences
- ✅ Predictable, reproducible control plane builds.  
- ✅ Aligns with enterprise-grade Cloud-Init and Terraform provisioning pipelines.  
- ✅ Simplifies DR testing — full VMs can be snapshotted or exported.  
- ⚠️ Slightly higher resource overhead (CPU/RAM) than LXCs.  
- ⚠️ Slower initial boot, mitigated by pre-baked Packer images.

## References
- [Provisional for ctrl-01: provision-ctrl01-proxmox-ubuntu.sh](../../control/tools/provision/provision-ctrl01-proxmox-ubuntu.sh)
- [Runbook: ctrl-01 Bootstrap / Verification](../runbooks/bootstrap/bootstrap-ctrl01-node.md)  
- [Diagram: Control Plane Architecture](../diagrams/control_plane_architecture.png)  
- [Evidence: ctrl-01 Bootstrap Logs](../proof/ctrl01-bootstrap/)

---

**Maintainer:** HybridOps.Studio
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
