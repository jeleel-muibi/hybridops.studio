---
id: ADR-0015
title: "Network Infrastructure Assumptions for Packer Builds"
status: Superseded
date: 2025-11-08

category: "00-governance"
supersedes: []
superseded_by: ["ADR-0101", "ADR-0201"]

links:
  runbooks:
    - "../runbooks/platform/packer-proxmox-template-build.md"
  howtos: []
  evidence: []
  diagrams: []
  related_docs:
    - "../prerequisites/network-architecture.md"
    - "./ADR-0016-packer-cloudinit-vm-templates.md"

draft: false
tags: ["packer", "networking", "assumptions"]
access: public
---

# Network Infrastructure Assumptions for Packer Builds

This ADR is retained as a **historical record** of early Packer networking assumptions.

The current source of truth for network design and build-time connectivity is:

- [ADR-0101 – VLAN Allocation Strategy](./ADR-0101-vlan-allocation-strategy.md)  
- [ADR-0102 – Proxmox as Intra-Site Core Router](./ADR-0102-proxmox-intra-site-core-router.md)  
- [Network Architecture](../prerequisites/network-architecture.md)  
- [ADR-0016 – Packer + Cloud-Init VM Templates](./ADR-0016-packer-cloudinit-vm-templates.md)  

In summary, Packer builds still **assume**:

- A management VLAN with DHCP/DNS and outbound package access.  
- Proxmox bridges already connected to that network.  
- Packer does **not** spin up ad-hoc DHCP or mutate host networking; it consumes the existing fabric.

Operational detail and current commands live in:

- [Packer multi-OS workspace](../../infra/packer-multi-os/README.md)  
- [Runbook: Proxmox Packer Template Build](../runbooks/platform/packer-proxmox-template-build.md)  

---

**Maintainer:** HybridOps.Studio
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
