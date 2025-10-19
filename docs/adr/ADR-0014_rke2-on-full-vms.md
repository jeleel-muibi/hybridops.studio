---
id: ADR-0014
title: "RKE2 Runs on Full VMs (Rocky Linux 9 Base) with Simple LB and Storage"
status: Accepted
date: 2025-10-12
domains: ["kubernetes", "platform", "sre"]
owners: ["jeleel"]
supersedes: []
superseded_by: []
links:
  prs: []
  runbooks: ["../runbooks/kubernetes/rke2-vm-deploy.md"]
  evidence: ["../proof/kubernetes/rke2-vm/"]
  diagrams: ["../diagrams/rke2_vm_architecture.png"]
---

# ADR-0014 — RKE2 Runs on Full VMs (Rocky Linux 9 Base) with Simple LB and Storage

## Status
Accepted — All RKE2 nodes now run as full VMs on **Rocky Linux 9.x** for production and DR consistency.

## Context
Earlier prototypes deployed RKE2 on LXC containers or Ubuntu VMs.  
While lightweight, these approaches introduced issues:
- **Kernel and cgroup limits** inside LXCs impacted Kubernetes components.  
- **Inconsistent SELinux /AppArmor behavior** on Ubuntu affected Longhorn and Cilium.  
- **Snapshot and export incompatibilities** across Proxmox and VMware during DR.

To achieve a realistic enterprise baseline without RHEL subscription costs,  
**Rocky Linux 9.x** offers the right balance — binary compatibility with RHEL,  
long-term stability, and seamless integration with Terraform, Packer, and Ansible.

## Decision
Use **Rocky Linux 9.x** as the base image for all RKE2 control-plane and worker VMs.  
VMs are built via **Packer** templates and provisioned through **Terraform** with Cloud-Init.

### Core Stack
- **Load Balancer:** MetalLB (L2 mode) IP pool `172.16.13.200–172.16.13.220`  
- **CNI:** Cilium (default), Canal fallback  
- **Storage:** Longhorn (default StorageClass)  
- **Provisioning:** Terraform + Ansible roles under `core/ansible/rke2`  
- **Observability:** Prometheus + Grafana federated from ctrl-01

## Decision Drivers
- **Enterprise Familiarity:** RHEL-compatible stack for assessors and training.  
- **Portability:** VMs exportable as OVA/OVF for VMware or cloud replication.  
- **Predictability:** Stable SELinux, systemd, and kernel interfaces.  
- **Governance:** Matches security controls in ITIL/ISO aligned orgs.  

## Implementation
- **Control Plane:** 1–3 VMs (2 vCPU / 4–8 GB RAM / 40–60 GB disk)  
- **Workers:** N VMs (2 vCPU / 4–8 GB RAM / ≥60 GB disk)  
- **Network:** `vmbr6` (prod), static IPs, DNS `rke2-cp-*`, `rke2-wk-*`  
- **Automation:** `make k8s.template → k8s.provision → k8s.install → k8s.validate`  
- **Base Image:** `rocky-9-rke2-base.qcow2` built with Packer (`packer/rke2-rocky9.json`)

## Consequences
- ✅ Predictable enterprise-grade behavior across on-prem and cloud  
- ✅ Improved resilience and snapshot compatibility  
- ✅ Lower licensing costs than RHEL  
- ⚠️ Slightly larger base image and longer build time  
- ⚠️ Needs occasional yum mirror refresh to pin kernel version for Longhorn  

## References
- [Runbook: RKE2 VM Deployment](../runbooks/kubernetes/rke2-vm-deploy.md)  
- [Diagram: RKE2 VM Architecture](../diagrams/rke2_vm_architecture.png)  
- [Evidence: RKE2 VM Proofs](../proof/kubernetes/rke2-vm/)

---

**Author / Maintainer:** Jeleel Muibi  
**Project:** [HybridOps.Studio](https://github.com/jeleel-muibi/hybridops.studio)  
**License:** MIT-0 / CC-BY-4.0
