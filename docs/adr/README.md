# Architecture Decision Records (ADRs)

Project-wide decision log. Each ADR captures context, options, decision, and consequences with links to code, diagrams, evidence, and runbooks.

> Indexes below are generated from the ADR files in this folder. For details on upkeep, see the [Maintenance Guide](../maintenance.md#adr-index-generation).

---

> **Spotlight**
> • [ADR-0100 — HPC Extension Strategy](./ADR-0100-HPC-Extension-Strategy-for-HybridOps-Studio.md): scope and approach for a Slurm-based HPC lab within HybridOps.Studio.

## Domains

<!-- ADR:DOMAINS START -->
**Domains:** [automation (2)](./by-domain/automation.md) · [cloud (1)](./by-domain/cloud.md) · [data (1)](./by-domain/data.md) · [governance (3)](./by-domain/governance.md) · [hpc (1)](./by-domain/hpc.md) · [infra (4)](./by-domain/infra.md) · [kubernetes (2)](./by-domain/kubernetes.md) · [networking (8)](./by-domain/networking.md) · [observability (1)](./by-domain/observability.md) · [platform (11)](./by-domain/platform.md) · [secops (2)](./by-domain/secops.md) · [security (1)](./by-domain/security.md) · [sre (5)](./by-domain/sre.md)
<!-- ADR:DOMAINS END -->

---

## Index

<!-- ADR:INDEX START -->
| No. | Title | Status | Date |
|:---:|:------|:------:|:----:|
| 0001 | [ADR-0001 — ADR Process & Conventions](./ADR-0001_adr-process-and-conventions.md) | Accepted | 2025-10-05 |
| 0002 | [ADR-0002 — Source of Truth: NetBox-Driven Inventory](./ADR-0002_source-of-truth_netbox-driven-inventory.md) | Accepted | 2025-10-06 |
| 0003 | [ADR-0003 — Secrets Management: Kubernetes External Secrets + KMS Integration](./ADR-0003_secrets-management_k8s-external-secrets-kms.md) | Accepted | 2025-10-07 |
| 0004 | [ADR-0004 — NCC Primary Hub: Azure as Hybrid Connectivity Core](./ADR-0004_ncc-primary-hub_azure-spoke.md) | Accepted | 2025-10-08 |
| 0005 | [ADR-0005 — Hybrid Network Automation: Nornir + Ansible Integration](./ADR-0005-Nornir-Ansible-Hybrid.md) | Accepted | 2025-10-08 |
| 0006 | [ADR-0006 — NETCONF-Driven Network Management Using Cisco CSR1000v and Nornir](./ADR-0006-NETCONF-Nornir-CSR1000v.md) | Accepted | 2025-10-08 |
| 0007 | [ADR-0007 — Dual ISP Load Balancing for Resiliency](./ADR-0007-Dual_ISP_Load_Balancing_for_Resiliency.md) | Accepted | 2025-10-09 |
| 0008 | [ADR-0008 — VyOS as Cost-Effective Edge Router](./ADR-0008-VyOS_as_Cost-Effective_Edge_Router.md) | Accepted | 2025-10-09 |
| 0009 | [ADR-0009 — Full Mesh Topology for High Availability](./ADR-0009-Full_Mesh_Topology_for_High_Availability.md) | Accepted | 2025-10-09 |
| 0010 | [ADR-0010 — VRRP Between Cisco IOS and Arista vEOS](./ADR-0010-VRRP_Between_Cisco_IOS_and_Arista_vEOS.md) | Accepted | 2025-10-09 |
| 0011 | [ADR-0011 — pfSense as Firewall for Flow Control](./ADR-0011-pfSense_as_Firewall_for_Flow_Control.md) | Accepted | 2025-10-09 |
| 0012 | [ADR-0012 — Control Node Runs as a VM (cloud-init); LXC Reserved for Light Helpers](./ADR-0012_control-node-as-vm.md) | Accepted | 2025-10-12 |
| 0013 | [ADR-0013 — PostgreSQL Runs in LXC (State on Host-Mounted Storage; Backups First-Class)](./ADR-0013_postgresql-as-lxc.md) | Accepted | 2025-10-12 |
| 0014 | [ADR-0014 — RKE2 Runs on Full VMs (Rocky Linux 9 Base) with Simple LB and Storage](./ADR-0014_rke2-on-full-vms.md) | Accepted | 2025-10-12 |
| 0100 | [ADR-0100 — HPC Extension Strategy for HybridOps.Studio](./ADR-0100-HPC-Extension-Strategy-for-HybridOps-Studio.md) | Proposed | 2025-10-10 |
<!-- ADR:INDEX END -->

---

### 📂 Related
- [HOWTOs](../howto/README.md)
- [Runbooks](../runbooks/README.md)

[Back to Docs Home](../README.md)
