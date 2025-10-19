---
id: ADR-XXXX
title: "<Concise, action-oriented title — e.g., 'Adopt Rocky Linux 9 for RKE2 Base Image'>"
status: Proposed            # Proposed | Accepted | Deprecated | Superseded
date: 2025-10-15            # ISO format; used by index generator
domains: ["platform"]       # e.g., ["networking", "platform", "sre"]
owners: ["jeleel"]
supersedes: []              # e.g., ["ADR-0007"]
superseded_by: []
links:
  prs: []                   # e.g., ["https://github.com/jeleel-muibi/hybridops.studio/pull/42"]
  runbooks: ["../runbooks/..."]
  evidence: ["../proof/..."]
  diagrams: ["../diagrams/..."]
---

# ADR-XXXX — <Human-Readable Title (Expanded)>

## Status
Proposed — pending validation or demonstration in the HybridOps.Studio lab.

## Context
Briefly describe the situation that led to this decision:
- What challenge, limitation, or design gap existed?
- Why now?
- Which alternatives or prior ADRs informed this one?

*(Example)*  
Earlier prototypes deployed RKE2 on Ubuntu LXCs, which caused kernel and storage inconsistencies.  
The team now seeks an enterprise-aligned OS that provides reproducibility, portability, and DR reliability.

## Decision
Summarize the final choice and its scope.  
Include the **chosen technologies**, **configuration model**, and any **IaC references**.

*(Example)*  
Adopt **Rocky Linux 9.x** as the standard base image for all RKE2 nodes.  
Provision via Terraform + Cloud-Init, and automate bootstrap with Ansible.

### Key Components
- **Base OS:** Rocky Linux 9.x  
- **Provisioning:** Terraform + Packer + Ansible  
- **Storage:** Longhorn  
- **CNI:** Cilium (default)  
- **Load Balancer:** MetalLB (L2 mode)

## Decision Drivers
List the major factors that influenced this decision:
- Compliance / Governance requirements  
- Ease of automation and reproducibility  
- Performance or interoperability considerations  
- Cost, licensing, or open-source viability

## Consequences
Summarize the outcomes — both **positive** and **negative** — of this decision.

**Positive**
- Predictable behavior across on-prem and cloud  
- Alignment with RHEL-grade enterprise norms  
- Easier DR replication (VM-based portability)

**Negative**
- Slightly higher resource footprint than LXC  
- Slower provisioning time for full VMs

## Implementation Notes
Provide relevant implementation details, file paths, and Make targets — without using naked links.

*(Example)*  
- Terraform module: `control/terraform/rke2/`  
- Packer template: `control/packer/rke2-rocky9.json`  
- Ansible roles: `core/ansible/rke2/`  
- Make targets: `make k8s.template → k8s.provision → k8s.install`

## References
- Runbook: [RKE2 VM Deployment](../runbooks/kubernetes/rke2-vm-deploy.md)  
- Diagram: [RKE2 VM Architecture](../diagrams/rke2_vm_architecture.png)  
- Evidence: [RKE2 Proofs](../proof/kubernetes/rke2-vm/)  
- Internal: [Maintenance Guide](../maintenance.md#adr-index-generation)

---

**Author / Maintainer:** Jeleel Muibi  
**Project:** [HybridOps.Studio](https://github.com/jeleel-muibi/hybridops.studio)  
**License:** MIT-0 / CC-BY-4.0
