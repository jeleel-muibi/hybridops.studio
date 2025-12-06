# Evidence 1 – Hybrid Network & Connectivity Blueprint  
**HybridOps.Studio – Enterprise‑Style Hybrid Network Core**

> **Evidence context:**  
> This document is **Evidence 1 of 5** for my Global Talent application.  
> It focuses on the **on-prem hybrid network core** (VLAN model, intra-site routing, firewall posture, observability, and validation).  
> Separate evidence packs cover **WAN & hybrid connectivity**, **infrastructure automation & NETCONF/Nornir**, **delivery platform (CI/CD, GitOps, Kubernetes)**, and **documentation / teaching / community contributions**.

---

## 1. Executive Summary

HybridOps.Studio implements an **enterprise‑style hybrid network architecture** that demonstrates:

- Segmented VLAN design for management, observability, dev, staging, prod, and lab.  
- A Proxmox‑based **intra‑site Layer 3 core**, with clear separation from edge routers and firewalls.  
- Parallel EVE‑NG lab infrastructure for safe experimentation without impacting core services.  
- Unified observability across environments (Prometheus(in a federated setup), Grafana, Loki) with strict inter‑VLAN controls.  
- Repeatable, documented procedures for change, validation, and troubleshooting.

This evidence pack shows:

- **The architecture** – how the on‑prem “site” is structured as a core + edge model.  
- **Key design decisions** – captured as ADRs and implemented in code.  
- **Validation** – connectivity checks, packet captures (Wireshark), and firewall policy tests.  
- **Operational discipline** – runbooks and HOWTOs that treat the platform as an enterprise system, not a lab.

---

## 2. Architecture Overview

### 2.1 High‑Level Topology

> **Diagram placeholder – Network core and VLANs**  
> Save as: `docs/diagrams/network-architecture.png` and embed in MkDocs.  
> Show: Internet → Edge (pfSense / CSR / VyOS) → Proxmox L3 core → VLANs (10/11/20/30/40/50) → EVE‑NG in VLAN 50.  
> Label Proxmox explicitly as **“Intra‑Site Core”**, not edge.

Key characteristics:

- **Proxmox** runs a VLAN‑aware bridge (`vmbr0`) with subinterfaces for:  
  - VLAN 10 – Management (bastion, automation controllers)  
  - VLAN 11 – Observability (Prometheus federation, Grafana, Loki)  
  - VLAN 20 – Development  
  - VLAN 30 – Staging  
  - VLAN 40 – Production  
  - VLAN 50 – Lab / Testing (EVE‑NG, experiments)
- **Edge connectivity** (dual ISP, IPsec to Azure/GCP, etc.) is handled by **pfSense, CSR1000v, and VyOS** – not by Proxmox.  
- **EVE‑NG** sits in a fully isolated lab VLAN to experiment with networking scenarios in parallel to the core.

High‑level narrative:

> Proxmox is the intra‑site “core switch + router”. Edge routers and firewalls terminate WAN/ISP links and VPNs.  
> Lab experiments live beside, not inside, the production path.

### 2.2 VLAN Model & Segmentation

- VLAN 10–19: Management plane (bastion, Ansible, Terraform state, control services).  
- VLAN 11: Dedicated observability plane.  
- VLAN 20–29: Development workloads (k3s dev clusters and services).  
- VLAN 30–39: Staging workloads.  
- VLAN 40–49: Production‑style workloads.  
- VLAN 50–59: Lab / Testing (EVE‑NG, experimental VMs).  

Intent:

- Separate **who manages the platform** (VLAN 10/11) from **what runs on the platform** (20/30/40).  
- Keep experiments (VLAN 50) completely isolated, only opted‑in for specific tests.  

### 2.3 Proxmox as Intra‑Site Core

Proxmox acts as the **intra‑site core router**:

- Terminates all VLAN gateways (`vmbr0.N`).  
- Routes between internal VLANs based on a **default‑deny inter‑VLAN firewall**.  
- Applies NAT for internal VLANs via the upstream `vmbr0` address toward the home/edge router.  

Edge routers and pfSense:

- Handle dual‑ISP routing and failover.  
- Terminate IPsec / WireGuard tunnels to Azure, GCP, and DR/demo “sites”.  
- Expose a small, controlled surface back into the Proxmox core.

### 2.4 Edge & Lab Separation

Edge decisions (dual ISP, edge routing, VRRP, etc.) are captured in ADRs and implemented on CSR/VyOS/pfSense. EVE‑NG is used to **rehearse** those designs without touching the production path.

Principles:

- **Core vs Edge separation** – Proxmox is the intra‑site core; edge routers and pfSense handle WAN and VPN.  
- **Parallel lab** – EVE‑NG is not in the production path; it’s used to simulate, validate, and rehearse designs before applying them.  

> **Diagram placeholder – EVE‑NG lab topology**  
> Save as: `docs/diagrams/eve-ng-lab-architecture.png` and embed into the docs site.

---

## 3. Demo Video (Walk‑Through)

This evidence is paired with a short video walkthrough that shows the architecture in action.

> **Video placeholder** – “HybridOps.Studio – Hybrid Network Core & Connectivity Walkthrough”  
> Upload to YouTube (unlisted) and embed in MkDocs via an `??? info` block.  

Suggested links:

- Docs embed:  
  `https://doc.hybridops.studio/evidence/networking/hybrid-network-core-demo/` *(example route)*  
- Direct YouTube link (for PDF):  
  `https://www.youtube.com/watch?v=YOUR_VIDEO_ID`  

In the video, highlight:

- Logical topology and VLANs.  
- Proxmox as intra‑site core vs edge routers.  
- Example flows (dev → internet, observability → workloads, blocked dev → prod).  
- A quick Wireshark capture showing VLAN tags or scraped metrics.

---

## 4. Key Design Decisions (ADRs)

Short excerpts (1–2 lines). Full texts live in the ADR section of the docs site and in the repository.

- **ADR‑0101 – VLAN Allocation Strategy** – Defines VLAN ranges, subnets, and purposes (management, observability, dev, staging, prod, lab) and reserves address ranges for infrastructure services and VM allocations.  
- **ADR‑0102 – Proxmox as Intra‑Site Core Router** – Positions Proxmox as intra‑site L3 core while edge routers remain responsible for WAN, ISP, and VPN. VLAN gateways terminate on Proxmox with inter‑VLAN routing and NAT via kernel + iptables.  
- **ADR‑0103 – Inter‑VLAN Firewall Policy** – Establishes a default‑DROP posture between VLANs, with explicit allow‑rules for management, observability, and tightly‑controlled cross‑environment flows. Lab VLAN is fully isolated by default.  
- **ADR‑0104 – Static IP Allocation with Terraform IPAM** – Uses a Terraform IPAM module to allocate static IPs from per‑VLAN ranges, ensuring conflict‑free addressing aligned with cloud‑init and VM modules.  
- **ADR‑0201 – EVE‑NG Network Lab Architecture** – Positions EVE‑NG as parallel lab infrastructure in an isolated VLAN, with clear rules for when real VLANs may be trunked in for testing.  
- **ADR‑0401 – Unified Observability with Prometheus** – Runs Prometheus(in a federated setup) + Grafana + Loki stack in VLAN 11, scraping metrics from all environments with strong labelling for environment and workload.  

These ADRs show that the design is **intentional, versioned, and explained**, not just an ad‑hoc lab.

---

## 5. Implementation Highlights

### 5.1 Proxmox Networking Configuration

> **Code snippet placeholder – `/etc/network/interfaces`**  
> Include the `vmbr0` stanza and a subset of `vmbr0.N` gateways, matching ADR‑0101 ranges.  

Emphasise:

- `bridge-vlan-aware yes` and explicit `bridge-vids`.  
- IPs for VLAN 10/11/20/30/40/50 aligned with the ADR table.  
- Sysctl for `net.ipv4.ip_forward=1` and basic NAT rules applied via `iptables` / `nftables`.

### 5.2 Terraform & IPAM Integration

> **HCL snippet placeholder – IPAM and VM modules**  

Show how:

- IP blocks per VLAN are defined in a Terraform IPAM module.  
- VM modules consume IPAM outputs (`ipv4_address`, `ipv4_gateway`, `dns_servers`) to render cloud‑init configs.  
- The same Terraform logic can later extend to cloud environments (Azure/GCP) so addressing remains coherent across on‑prem and cloud.

This proves that **addressing and VM wiring are code‑driven**, not configured manually via GUI.

### 5.3 Inter‑VLAN Firewall Rules

> **Ansible / firewall snippet placeholder** – from a `proxmox-firewall` role or shell provisioning script.  

Key points to bring out:

- Default policy is DROP on the `FORWARD` chain.  
- Allow rules are specific (e.g. observability → workloads scrape ports, management → SSH/HTTPS to infrastructure only).  
- Lab VLAN (50) has explicit denies to production and staging by default.  

You can then point to the runbook that walks through the “baseline firewall validation”.

### 5.4 Observability Placement

> **Screenshot placeholder – Grafana dashboard** showing:  
> - An environment selector (dev/stage/prod).  
> - Metrics sourced from different VLANs.  

Describe briefly:

- Prometheus lives in VLAN 11, scraping exporters in VLAN 20/30/40.  
- Logs from critical components are shipped to Loki in the same VLAN.  
- Inter‑VLAN rules allow observability to reach workloads, not the other way round.  

This shows that **visibility and SLO thinking** are built into the platform from the start.

---

## 6. Validation & Evidence

### 6.1 Connectivity Checks

> **CLI screenshot placeholders** (terminal captures) from:  
> - `ping` tests in each VLAN to:  
>   - Its gateway.  
>   - Internet (e.g. `8.8.8.8`).  
>   - Other VLANs (show allowed vs denied combinations).  
> - `ip route`, `ip addr`, `iptables -t nat -L`, `iptables -L FORWARD`.  

Narrate the key outcomes:

- Dev cannot initiate connections to prod directly.  
- Lab cannot reach operational VLANs unless explicitly permitted for a demo.  
- Observability can scrape workloads but workloads cannot reach observability back.  

### 6.2 Wireshark / Packet Captures

> **Wireshark screenshot placeholders** from capture files stored under a path such as:  
> `docs/proof/networking/wireshark/`  

Examples worth showing:

- Tagged VLAN traffic on a Proxmox trunk interface (802.1Q headers).  
- Prometheus scrape traffic from VLAN 11 to workloads in VLAN 20/30/40.  
- Blocked flows that match the firewall policy (e.g. `dev → prod DB` refused).  

Explain briefly in captions:

- Filters used (`vlan and ip.addr == …`).  
- Scenario being validated (“dev cannot talk to prod DB”, “observability can reach prod metrics endpoint but not admin APIs”).  

### 6.3 Runbook‑Driven Tests

> **Runbook excerpt placeholders** from:  
> - `docs/runbooks/networking/inter-vlan-firewall-baseline.md`  
> - `docs/runbooks/networking/ethernet-wifi-failover.md`  
> - `docs/runbooks/networking/full-mesh-topology.md` (once in use)  

Show that:

- Platform changes and checks follow documented runbooks, not ad‑hoc commands.  
- The same runbooks can be used by another SRE / engineer without relying on your implicit knowledge.  

---

## 7. Links & Artefacts

> In the PDF upload, these links act as the bridge from narrative → live artefacts (docs site + GitHub).  
> You can keep or trim this list depending on the final word limit.

### 7.1 Documentation (MkDocs)

- [Network Architecture](https://doc.hybridops.studio/prerequisites/network-architecture/)  
- [HOWTO: Proxmox VLAN Bridge](https://doc.hybridops.studio/howtos/networking/proxmox-vlan-bridge/)  
- [HOWTO: Inter‑VLAN Firewall Baseline](https://doc.hybridops.studio/howtos/networking/inter-vlan-firewall-iptables/)  
- [HOWTO: Terraform IPAM – Static IP Allocation](https://doc.hybridops.studio/howtos/networking/terraform-ipam-static-ip-allocation/)  
- [HOWTO: Validate End‑to‑End Architecture](https://doc.hybridops.studio/howtos/networking/validate-end-to-end-architecture/)  
- [HOWTO: EVE‑NG Parallel Lab Scenarios](https://doc.hybridops.studio/howtos/networking/eve-ng-parallel-lab-scenarios/)  

- [Runbook: Ethernet ↔ WiFi Failover](https://doc.hybridops.studio/runbooks/networking/ethernet-wifi-failover/)  
- [Runbook: Inter‑VLAN Firewall Baseline](https://doc.hybridops.studio/runbooks/networking/inter-vlan-firewall-baseline/)  
- [Runbook: Full Mesh Topology](https://doc.hybridops.studio/runbooks/networking/full-mesh-topology/)  
- [Runbook: NCC Hub Setup](https://doc.hybridops.studio/runbooks/networking/ncc-hub-setup/)  

*(Adjust paths once your MkDocs navigation is final.)*

### 7.2 ADRs (MkDocs)

- [ADR‑0101 – VLAN Allocation Strategy](https://doc.hybridops.studio/adr/ADR-0101-vlan-allocation-strategy/)  
- [ADR‑0102 – Proxmox as Intra‑Site Core Router](https://doc.hybridops.studio/adr/ADR-0102-proxmox-intra-site-core-router/)  
- [ADR‑0103 – Inter‑VLAN Firewall Policy](https://doc.hybridops.studio/adr/ADR-0103-inter-vlan-firewall-policy/)  
- [ADR‑0104 – Static IP Allocation with Terraform IPAM](https://doc.hybridops.studio/adr/ADR-0104-static-ip-allocation-terraform-ipam/)  
- [ADR‑0105 – Dual Uplink Design (Ethernet/WiFi Failover)](https://doc.hybridops.studio/adr/ADR-0105-dual-uplink-ethernet-wifi-failover/)  
- [ADR‑0106 – Dual ISP Load Balancing for Resiliency](https://doc.hybridops.studio/adr/ADR-0106-dual-isp-load-balancing-resiliency/)  
- [ADR‑0107 – VyOS as Cost‑Effective Edge Router](https://doc.hybridops.studio/adr/ADR-0107-vyos-edge-router/)  
- [ADR‑0108 – Full Mesh Topology for High Availability](https://doc.hybridops.studio/adr/ADR-0108-full-mesh-topology-ha/)  
- [ADR‑0201 – EVE-NG Network Lab Architecture](https://doc.hybridops.studio/adr/ADR-0201-eve-ng-network-lab-architecture/)  
- [ADR‑0301 – pfSense as Firewall for Flow Control](https://doc.hybridops.studio/adr/ADR-0301-pfsense-firewall-flow-control/)  
- [ADR‑0401 – Unified Observability with Prometheus federation](https://doc.hybridops.studio/adr/ADR-0401-unified-observability-prometheus/)  

### 7.3 GitHub – Repository Entry Point

For assessors who want to inspect raw artefacts and IaC, the main entry point is:

- [HybridOps.Studio – Root README (GitHub)](https://github.com/jeleel-muibi/hybridops.studio)  

From there, the README describes:

- Repository layout (networking, infrastructure, CI/CD, academy).  
- Where to find the ADRs, HOWTOs, runbooks, and proof artefacts referenced in this evidence pack.  

---

**Owner:** HybridOps.Studio  
**License:** MIT‑0 for code, CC‑BY‑4.0 for documentation
