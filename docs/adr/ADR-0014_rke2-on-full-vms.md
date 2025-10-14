---
id: 0014
title: RKE2 runs on full VMs (no LXC) with simple LB and storage
status: accepted
decision_date: 2025-10-12
domains: [kubernetes, platform, sre]
tags: [rke2, vm, cloud-init, cni, metallb, storage, proxmox, vmware, dr]
---

## Context

We need a small Kubernetes cluster that’s **portable** (Proxmox ⇄ VMware), **repeatable**, and **on‑prem friendly**. LXC complicates cgroups/kernel module needs for kube components and runtimes. Full VMs provide the correct primitives and easier DR.

## Decision

Run **all RKE2 nodes as VMs** (cloud‑init). Use a simple, VM‑friendly stack:  
- **LB:** MetalLB (L2 mode) with a small pool on `172.16.13.0/24`.  
- **CNI:** Cilium (or default Canal to start; revisit later).  
- **Storage:** Longhorn as default StorageClass for demos.

## Decision Drivers

- **Correct primitives:** cgroups, modules, predictable behavior.
- **Portability:** Export/import VMs as OVA/OVF.
- **Simplicity:** L2 LB and simple storage get us productive quickly.

## Options Considered

- **VMs for RKE2 nodes** — Robust and portable. **Chosen.**
- **LXC** — Fragile for k8s; troubleshooting overhead not worth it here.

## Consequences

- + Clean DR; consistent behavior across hypervisors.
- − Slightly more resource overhead per node (acceptable).

## Scope & Sizing (non‑normative)

- Control plane: 1–3 VMs (2 vCPU / 4–8 GB RAM, 40–60 GB disk).
- Workers: N VMs (2 vCPU / 4–8 GB RAM, ≥60 GB disk).
- Network: `vmbr6`, static IPs, pool for MetalLB (e.g., `172.16.13.200–172.16.13.220`).

## References (placeholders)

- Runbook: `docs/runbooks/rke2/vms_deploy.md` _(to be written)_  
- Cloud‑init template: `control/snippets/rke2-node-cloudinit.yaml` _(placeholder)_  
- Ansible playbooks: `core/ansible/rke2/` _(skeleton)_  
- Make targets: `make k8s.template`, `make k8s.provision`, `make k8s.install`, `make adr.index`
