# Evidence Slot 3 – Hybrid Network & WAN Edge (OC1)

> **Criteria:** Optional Criteria 1 (OC1) – innovation / significant technical contributions.  
> **Scope:** Design and implementation of a dual-ISP, pfSense-based hybrid network and WAN edge, integrated with VLAN segmentation, IPsec and NetBox as source of truth.  
> **Note (working copy only):** `[IMG-XX]` placeholders will be replaced with final diagrams and screenshots before submission.

---

## 1. Summary – Enterprise-Style Hybrid Network in a Blueprint

This evidence shows how I designed and implemented the **hybrid network and WAN edge** that underpin HybridOps.Studio as a platform blueprint.

The design combines:

- **Dual ISP connectivity** for resilience.  
- **pfSense-based WAN edge** with clear segmentation and firewalling.  
- **IPsec-based hybrid connectivity** to cloud environments.  
- A structured **VLAN and subnet model** aligned to management, workloads and observability.  

It is captured in dedicated networking evidence packs and ADRs, and forms the foundation on which the platform, DR and academy layers are built.

[IMG-01 – High-level network diagram: dual ISP, pfSense, VLANs, tunnels to cloud – ~8 lines]

---

## 2. Problem & Context – Reliable, Segmentable Hybrid Connectivity

Most of the work in HybridOps.Studio assumes:

- On-premises compute (Proxmox, RKE2, db-01).  
- Cloud capacity for DR/burst.  
- A clear separation between management, workloads and observability traffic.

To make that viable, the network must:

- Survive **ISP failures** without taking the whole platform down.  
- Provide **secure, segmented access** between components (pfSense, Proxmox, RKE2 nodes, db-01, jump hosts).  
- Maintain **predictable addressing** so that Terraform, Ansible and Kubernetes can reason about the environment.

The hybrid network and WAN edge address these needs and are documented in:

- `evidence-01-hybrid-network-connectivity.md`  
- `evidence-02-wan-edge-hybrid-connectivity.md`  

as well as networking ADRs in the `ADR-01xx` range.

---

## 3. Implementation – Dual ISP, pfSense and VLAN Model

### 3.1 Dual ISP and WAN edge

At the edge, HybridOps.Studio uses **pfSense firewalls** with **dual ISP** connections:

- ISP-A is treated as the **primary** path.  
- ISP-B serves as the **secondary/failover** path.  

pfSense is configured to:

- Monitor upstream reachability.  
- Fail over outbound traffic from ISP-A to ISP-B when the primary path is considered down.  
- Maintain appropriate NAT and firewall rules for both providers.

[IMG-02 – Screenshot of pfSense gateway status / dual WAN configuration – ~6 lines]

This means that if the primary ISP fails, the platform retains external connectivity and IPsec tunnels can still be established via the secondary provider.

### 3.2 VLANs and subnet layout

Internally, the network is segmented using **VLANs** with dedicated subnets for:

- **Management** – Proxmox, RKE2 control plane, db-01, jump hosts.  
- **Workloads** – Kubernetes worker nodes and applications.
- **Observability** – Prometheus, Grafana, Loki and other monitoring/logging tools.  
- **DMZ / edge** – services that are explicitly exposed.

Each VLAN and subnet is:

- Documented in NetBox as part of the source of truth.  
- Used by Terraform/Ansible automation to place nodes correctly.  
- Protected via pfSense rules that enforce least privilege between segments.

[IMG-03 – Screenshot of VLAN/subnet view in NetBox or a diagram showing segments – ~6 lines]

This segmentation is crucial later when introducing DR, cost-aware automation and multi-tenant teaching scenarios under the academy.

---

## 4. Hybrid Connectivity – IPsec Tunnels to Cloud

To enable DR and cloud bursting, the WAN edge establishes **IPsec site-to-site tunnels** from pfSense to cloud networks.

- Tunnels are configured with:
  - Clear local and remote subnets.  
  - Strong encryption and authentication settings.  
- Routing and firewall rules ensure:
  - Management traffic (for example, to cloud-based DR clusters) can traverse the tunnel.  
  - Only expected subnets and ports are reachable from each side.  

[IMG-04 – Screenshot of pfSense IPsec tunnel status page – ~6 lines]

This allows HybridOps.Studio to:

- Treat cloud environments as extensions of the on-prem network for DR/burst workloads.  
- Keep **control-plane and data-plane** flows explicit and auditable.

The IPsec and hybrid connectivity design is described in detail in:

- `evidence-02-wan-edge-hybrid-connectivity.md`  
- Networking ADRs that define accepted patterns for WAN edge and tunnels.

---

## 5. Automation & Failure Scenarios

### 5.1 Using NetBox as a source of truth

The network design is not only manually documented; it is **codified in NetBox**:

- Sites, devices, interfaces, VLANs and prefixes are represented as objects.  
- Terraform and Ansible automation read from NetBox to derive:
  - Interface/VLAN assignments.  
  - Addressing plans.  
  - Firewall and routing intent (via tags and custom fields).

This allows:

- Network and infrastructure state to be changed **declaratively** via NetBox.  
- Automation to roll out updates consistently across pfSense, Proxmox and other devices.

[ART-01 – Small snippet of Terraform/Ansible code reading from NetBox (redacted) – ~6 lines]

### 5.2 ISP failover scenario

A key scenario implemented and documented is **primary ISP failure**:

1. ISP-A becomes unavailable.  
2. pfSense detects gateway failure and marks ISP-A as down.  
3. Traffic is automatically shifted to ISP-B.  
4. IPsec tunnels are re-established or continue via ISP-B, depending on configuration.  
5. The platform remains reachable for:
   - Management access.  
   - DR or troubleshooting.  

This scenario is captured in:

- Hybrid network evidence pack (Evidence 1).  
- Networking HOWTOs (running failover tests).  
- Runbooks (what to check, how to validate, when to escalate).

[IMG-05 – Screenshot or diagram of failover state: ISP-A down, ISP-B active – ~6 lines]

---

## 6. Innovation & Reusability

The hybrid network and WAN edge work is more than “I wired some routers together”:

- It is an **opinionated, documented blueprint** for:
  - Dual-ISP pfSense-based WAN edge.  
  - VLAN-based segmentation aligned to platform roles.  
  - IPsec hybrid connectivity to cloud environments.  
- It is integrated with a **source of truth (NetBox)** and **automation tooling**, so it can be managed as code, not just manual configuration.  
- It is tied into **DR and cost-aware designs**:
  - DR workflows rely on these tunnels and segments to be predictable.  
  - Observability VLANs ensure Prometheus and other tools can see the right signals.

[IMG-06 – Optional collage: network diagram + pfSense screens + NetBox view – ~6 lines]

This design is reusable as a **starting point for startups and engineering teams** who want:

- A realistic, segmented hybrid network without over-engineering.  
- Clear patterns they can adapt to their own ISPs, cloud providers and VLAN plans.  
- Teaching material for junior engineers to understand how a hybrid WAN edge is built in practice.

---

## 7. How This Meets Optional Criteria 1 (Innovation)

This evidence supports Optional Criteria 1 by showing that I have:

- Designed and implemented a **hybrid network and WAN edge** that supports the rest of the platform blueprint (RKE2, DR, cost control, academy).  
- Integrated **pfSense, dual ISP, VLAN segmentation, IPsec and NetBox** into a coherent, automated design rather than ad-hoc configuration.  
- Documented the system through dedicated evidence packs, ADRs, HOWTOs and runbooks so that others can understand, validate and reuse it.  

It demonstrates that my contributions go beyond basic connectivity and into **architecting a reusable hybrid network baseline** suitable for modern platform and SRE work.

---

**Context & navigation**

For easier cross-referencing, this PDF is mirrored on the [HybridOps.Studio documentation portal](https://docs.hybridops.studio) and linked from the [Tech Nation assessors’ guide](https://docs.hybridops.studio/briefings/gtv/how-to-review/). The docs site adds navigation only, not new evidence.
