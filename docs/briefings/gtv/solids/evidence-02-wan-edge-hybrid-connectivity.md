
# Evidence 2 – WAN Edge, Hybrid Connectivity & Flow Control  

**Evidence context**
This document is **Evidence 2 of 5** for my UK Global Talent application (Digital Technology – Technical).
It focuses on WAN edge design, ISP resilience, hybrid cloud connectivity (Azure/GCP), and the firewall/flow-control
layer in front of the HybridOps.Studio platform. It builds on Evidence 1 (network core & segmentation) and sets up
the foundation for later evidence on automation, NetBox, and Kubernetes workloads.

**HybridOps.Studio – Dual ISP, Vendor-Agnostic Edge, and Firewall Governance**

---

## 1. Executive Summary

This evidence pack demonstrates how HybridOps.Studio handles **WAN edge, hybrid connectivity, and flow control** in an enterprise-style way:

- **Dual ISP design** with policy-based failover on pfSense, validated through end-to-end tests.  
- **Vendor-agnostic edge routing** (Cisco CSR1000v + VyOS, with a Fortigate-variant path) using BGP and IPsec.  
- **Hybrid cloud connectivity** via an Azure hub integrated with Google Network Connectivity Center (NCC).  
- **Flow-control plane** separated from routing via pfSense, with cross-vendor VRRP for Layer 3 HA.  
- All of it backed by **ADRs, HOWTOs, runbooks, and proof artefacts** (logs, configs, pcaps).

This pack should answer: **“Can this person design and operate a multi-ISP, hybrid WAN edge with proper governance?”**

---

## 2. How This Evidence Fits Into the Whole

- **Evidence 1** focuses on the **intra-site core**: VLAN segmentation, Proxmox as L3 core, lab separation, observability.  
- **Evidence 2 (this)** focuses on the **edge and WAN**: ISPs, VPNs, cloud hubs, firewalls, VRRP, and hybrid connectivity.

Together they show:

- Inside the “site”: Proxmox core, VLANs, inter-VLAN firewall, observability.  
- At the “edge”: dual ISPs, pfSense/CSR/VyOS/Fortigate, NCC, VRRP, and WAN security.

Primary ADRs referenced here:

- ADR‑0106 – Dual ISP Load Balancing for Resiliency  
- ADR‑0107 – VyOS as Cost-Effective Edge Router  
- ADR‑0108 – Full Mesh Topology for High Availability  
- ADR‑0109 – NCC Primary Hub with Azure Spoke Connectivity  
- ADR‑0110 – VRRP Between Cisco IOS and Arista vEOS  
- ADR‑0301 – pfSense as Firewall for Flow Control  

Full ADR texts live on the docs site and in the repository; this document focuses on the overall story and evidence.

---

## 3. Dual ISP WAN Edge with pfSense & CSR

### 3.1 Design Overview

pfSense acts as the **flow-control and ISP edge**, with:

- Two ISPs (`WAN_A`, `WAN_B`) on a pfSense HA pair.  
- A **gateway group** for automatic failover based on packet loss / latency.  
- CSR1000v and/or VyOS sitting **behind pfSense** as edge routers, peering via BGP or static routes.  
- Internal VLANs and Proxmox core unchanged – WAN behaviour is abstracted behind pfSense.

Related ADRs:

- ADR‑0106 – Dual ISP Load Balancing for Resiliency  
- ADR‑0301 – pfSense as Firewall for Flow Control  

Supporting docs:

- [HOWTO – Dual ISP on pfSense + CSR Lab](https://doc.hybridops.studio/howtos/networking/dual-isp-pfsense-csr-lab/)  
- [Runbook – Dual ISP Load Balancing](https://doc.hybridops.studio/runbooks/networking/dual-isp-loadbalancing/)  

Proof artefacts are stored under: ``docs/proof/networking/dual-isp-tests/``.

---

### 3.2 Lab Assumptions (Example Values)

These values are representative; the real lab uses IP ranges derived from ADR‑0101 and the Terraform IPAM module.

- **ISP A:** `198.51.100.0/24` → pfSense WAN A: `198.51.100.10`  
- **ISP B:** `203.0.113.0/24` → pfSense WAN B: `203.0.113.10`  
- **Edge segment:** e.g. `172.16.10.0/24` between pfSense and CSR/VyOS  
- **Core / LAN:** `10.40.0.0/24` (production VLAN behind edge routers)

Connectivity tests, screenshots, and pcaps from this lab are under: ``docs/proof/networking/dual-isp-tests/``.

---

### 3.3 pfSense Gateway Group Configuration (Template)

In the **pfSense WebGUI**:

```text
System ▸ Routing ▸ Gateways

  Name      Interface  Gateway         Monitor IP
  ------    ---------  --------------  ---------------
  WAN_A_GW  wan_a      198.51.100.1    8.8.8.8
  WAN_B_GW  wan_b      203.0.113.1     1.1.1.1

System ▸ Routing ▸ Gateway Groups

  Name         Tiering                 Trigger Level
  ----------   ----------------------  -------------------------
  DUAL_WAN     WAN_A_GW (Tier 1)
               WAN_B_GW (Tier 2)       Packet Loss or High Latency
```

CLI checks around failover tests:

```bash
# pfSense shell – confirm default route
netstat -rn | grep '^default'

# Check dpinger health for both ISP gateways
ps aux | grep dpinger
```

> **Screenshot placeholders:**  
> - Gateway status (WAN_A_GW / WAN_B_GW) before and after failover.  
> - Gateway group **DUAL_WAN** configuration screen.  
> - `Status ▸ System Logs ▸ Gateways` around the failover window.  

---

### 3.4 Demo / Walk-through – Dual ISP Failover

> **Video demo placeholder** – *“Dual ISP Failover – pfSense Gateway Group + CSR Traffic”*  
>
> - Suggested: unlisted YouTube video.  
> - Placeholder URL: `https://www.youtube.com/watch?v=DUAL_ISP_DEMO_ID`  
>
> Recommended artefacts in the repository:  
> - PNG thumbnail in ``docs/proof/networking/dual-isp-tests/dual-isp-demo-thumbnail.png``.  
> - Short markdown note with timestamps: ``docs/proof/networking/dual-isp-tests/demo-notes.md`` (what you are showing at each minute).  

In the PDF version for submission, show a static screenshot from the video plus the clickable URL.

---

### 3.5 Test Scenario Summary

Core test you can repeat and capture:

1. **Baseline (ISP A active)**  
   - Default route via WAN_A_GW.  
   - Long-running `ping` or `iperf3` from a host behind CSR to the internet.  
   - Wireshark capture on pfSense WAN A showing traffic egress.  

2. **Induce failure on ISP A**  
   - Simulate: disable WAN A interface, or block upstream gateway.  
   - Observe dpinger marks WAN_A_GW as down; traffic moves to WAN_B_GW.  
   - Long-running `ping` shows a small burst of packet loss followed by recovery.  

3. **Recovery**  
   - Restore ISP A; confirm traffic returns to primary after stability threshold.  

> **Evidence to include:**  
> - `ping`/`iperf3` output before, during, after failover.  
> - Screen recording / screenshots of pfSense gateway and gateway group status.  
> - Optional: Wireshark pcap files under ``docs/proof/networking/dual-isp-tests/pcap/``.

This proves that dual ISP behaviour is **intentional, tested, and documented**, not an ad-hoc lab trick.

---

## 4. Vendor-Agnostic Edge – CSR, VyOS, and Fortigate Variant

### 4.1 Design Intent

The edge layer is designed to be **vendor-agnostic** while keeping the governance model and automation patterns consistent:

- **Cisco CSR1000v** acts as the reference enterprise router for:
  - eBGP sessions (on-prem and cloud),
  - IPsec tunnels to Azure/GCP,
  - NETCONF/YANG-based automation and telemetry.
- **VyOS** is the open-source counterpart used for:
  - DR sites and low-cost footprints,
  - nested lab topologies (including EVE-NG),
  - IPsec/WireGuard-based VPN scenarios.
- A **Fortigate edge variant** (planned) captures the same patterns for organisations standardised on Fortinet for perimeter security.

The goal is to show that HybridOps.Studio does **not** depend on a single vendor appliance; the **patterns** (BGP, IPsec, HA, observability) stay the same even if the device brand changes.

Related ADRs:

- ADR-0106 – Dual ISP Load Balancing for Resiliency  
- ADR-0107 – VyOS as Cost-Effective Edge Router  
- ADR-0108 – Full Mesh Topology for High Availability  
- ADR-0109 – NCC Primary Hub with Azure Spoke Connectivity  
- ADR-0301 – pfSense as Firewall for Flow Control  
- (Planned) ADR-03xx – Fortigate as Edge Firewall Variant  

Supporting docs:

- [Runbook – Dual ISP Load Balancing](https://doc.hybridops.studio/runbooks/networking/dual-isp-loadbalancing/)  
- [HOWTO – Dual ISP Pattern (pfSense + CSR Lab)](https://doc.hybridops.studio/howtos/networking/dual-isp-pfsense-csr-lab/)  
- [Runbook – Full Mesh Topology](https://doc.hybridops.studio/runbooks/networking/full-mesh-topology/)  
- [HOWTO – Full Mesh Routing Lab](https://doc.hybridops.studio/howtos/networking/full-mesh-routing-lab/)  
- [Runbook – pfSense Firewall Flow Control](https://doc.hybridops.studio/runbooks/security/pfsense-flow-control/)  
- (Planned) HOWTO – Fortigate Edge Variant (mirroring the pfSense dual-ISP + IPsec scenarios).  

---

### 4.2 Full Mesh Topology (Edge & Firewalls)

Each edge router and firewall maintains **direct Layer 3 adjacencies** with its peers:

- CSR ↔ VyOS ↔ pfSense ↔ (future) Fortigate.  
- Transport via dedicated transit VLANs or tagged segments on Proxmox (`vmbr2`, `vmbr3`).  
- Routing via eBGP with no route reflectors (small, fully meshed node count).

> **Diagram placeholder:**  
> - `docs/diagrams/networking/full_mesh_network_topology.png`  
> - Show multiple routers and firewalls connected in a full mesh, with Proxmox core behind.

Proof artefacts:

- BGP summaries and routing tables captured under ``docs/proof/networking/full-mesh-tests/``.  
- Convergence timing notes (link flaps, VRRP master changes, etc.).  

---

### 4.3 Fortigate Variant (Planned)

To demonstrate **vendor flexibility** at the edge:

- Introduce a Fortigate VM in a small lab scenario mirroring pfSense:  
  - Dual WAN, policy routing, IPsec to CSR/VyOS.  
  - Equivalent security posture and logging.  
- Document it in a dedicated ADR (e.g. **ADR‑03xx – Fortigate Variant for Edge Firewall**) and HOWTO.

Suggested HOWTO path:

- ``docs/howtos/networking/HOWTO_networking_fortigate-edge-variant.md`` – matching structure to the pfSense HOWTOs (context, diagram, config steps, validation).

Even before the Fortigate lab is fully implemented, you can keep the ADR in **Proposed** state and reference it briefly here as a roadmap item, not as completed work.

---

## 5. Hybrid Cloud Hub with Azure & GCP NCC

### 5.1 NCC Hub-and-Spoke Design

ADR‑0109 formalises the choice of **Azure as the primary hybrid connectivity hub**, integrated with **Google Network Connectivity Center (NCC)**:

- Azure VNet hub with VPN Gateway (BGP-enabled).  
- On-prem pfSense / CSR1000v peers into Azure via IPsec.  
- GCP NCC peers into the same Azure hub, forming a cross-cloud mesh.  
- NCC provides topology visibility and unified control of cross-cloud routing.

Related ADR:

- ADR‑0109 – NCC Primary Hub with Azure Spoke Connectivity  

Runbook:

- [Runbook – NCC Hub Setup](https://doc.hybridops.studio/runbooks/networking/ncc-hub-setup/)  

Proof artefacts:

- ``docs/proof/networking/ncc/`` – NCC topology screenshots, ping tests between Azure and GCP, traceroutes.

---

### 5.2 Demo / Walk-through – Cross-Cloud Reachability

> **Video demo placeholder** – *“Hybrid Hub with Azure + GCP NCC”*  
>
> - Suggested: unlisted YouTube video with a short walk-through.  
> - Placeholder URL: `https://www.youtube.com/watch?v=NCC_HUB_DEMO_ID`  
>
> Recommended screen sequences:  
> - Azure portal showing the hub VNet and VPN connections.  
> - GCP console showing NCC topology view.  
> - Terminal panes: ping / traceroute from Azure VM → GCP VM and vice versa.  

In the repo, keep:

- PNGs from NCC and Azure/GCP consoles: ``docs/proof/networking/ncc/*.png``.  
- A short markdown note summarising the test scenario and expected results.

---

## 6. Flow-Control Plane & VRRP-Based L3 High Availability

### 6.1 pfSense as Firewall & Flow-Control Plane

ADR‑0301 captures pfSense as the **central flow-control plane**, separate from routing:

- Stateful firewall for inbound and outbound traffic.  
- NAT, policy routing, and traffic shaping rules.  
- CARP-based HA pair (`fw-01`, `fw-02`) with virtual IPs.  
- Integrated monitoring and log export into the central observability stack.

Related ADR:

- ADR‑0301 – pfSense as Firewall for Flow Control  

Runbook:

- [Runbook – pfSense Firewall Flow Control](https://doc.hybridops.studio/runbooks/security/pfsense-flow-control/)  

Proof artefacts:

- ``docs/proof/security/pfsense-ha-tests/`` – CARP state transitions, NAT/policy-routing examples, syslog extracts.

> **Suggested screenshots:**  
> - pfSense HA status page (CARP / XMLRPC sync).  
> - Firewall rule groups for WAN / LAN / IPsec.  
> - Policy routing rules for dual ISP use cases.

---

### 6.2 Cross-Vendor VRRP – CSR + Arista vEOS

ADR‑0110 focuses on **VRRP interoperability** between Cisco IOS/CSR and Arista vEOS:

- Shared virtual IP for key internal segments (e.g. transit or server VLANs).  
- CSR as VRRP master, vEOS as backup (or vice versa in some scenarios).  
- Failover triggered by WAN / IPsec state tracking.  
- Sub-second or low-second failover proven by ping timelines and pcaps.

Related ADR:

- ADR‑0110 – VRRP Between Cisco IOS and Arista vEOS  

Docs:

- [Runbook – VRRP Cross-Vendor Gateway](https://doc.hybridops.studio/runbooks/networking/vrrp-cross-vendor/)  
- [HOWTO – VRRP Cross-Vendor Gateway](https://doc.hybridops.studio/howtos/networking/vrrp-cross-vendor-gateway/)  

Proof artefacts:

- ``docs/proof/networking/vrrp-tests/`` – VRRP state logs, `show vrrp` outputs, ping continuity during failover, Wireshark captures.

> **Video demo placeholder** – *“VRRP Cross-Vendor Gateway Failover”*  
> - Placeholder URL: `https://www.youtube.com/watch?v=VRRP_DEMO_ID`  

---

## 7. Summary – What Evidence 2 Proves

By the time an assessor reaches the end of this pack, they should be able to see that you:

- Designed a **multi-ISP, hybrid-capable WAN edge** in a way that mirrors enterprise practice.  
- Kept **routing, firewalling, and flow-control concerns separated**, with clear ADRs and runbooks.  
- Demonstrated **vendor flexibility** (CSR, VyOS, pfSense, planned Fortigate) without losing governance.  
- Implemented **cross-cloud connectivity** using Azure as a hub and NCC as the federation plane.  
- Validated everything with **real tests and artefacts** – not just diagrams – including packet captures, console output, and automation-friendly runbooks / HOWTOs.

This evidence complements **Evidence 1 (Hybrid Network & Core Connectivity)** and sets the stage for:

- **Evidence 3 – Network Automation & NETCONF/Nornir**, and  
- **Evidence 4+ – Platform, CI/CD, DR, and higher-level automation.**

---

## 8. Links & Artefacts

### 8.1 Documentation (MkDocs)

- Dual ISP lab pattern:  
  - [HOWTO – Dual ISP on pfSense + CSR Lab](https://doc.hybridops.studio/howtos/networking/dual-isp-pfsense-csr-lab/)  
  - [Runbook – Dual ISP Load Balancing](https://doc.hybridops.studio/runbooks/networking/dual-isp-loadbalancing/)  

- Full mesh and edge topology:  
  - [HOWTO – Full Mesh Routing Lab](https://doc.hybridops.studio/howtos/networking/full-mesh-routing-lab/)  
  - [Runbook – Full Mesh Topology](https://doc.hybridops.studio/runbooks/networking/full-mesh-topology/)  

- Hybrid hub and NCC:  
  - [Runbook – NCC Hub Setup](https://doc.hybridops.studio/runbooks/networking/ncc-hub-setup/)  

- Flow control and security:  
  - [Runbook – pfSense Firewall Flow Control](https://doc.hybridops.studio/runbooks/security/pfsense-flow-control/)  
  - [Runbook – VRRP Cross-Vendor Gateway](https://doc.hybridops.studio/runbooks/networking/vrrp-cross-vendor/)  
  - [HOWTO – VRRP Cross-Vendor Gateway](https://doc.hybridops.studio/howtos/networking/vrrp-cross-vendor-gateway/)  

*(Adjust URLs once MkDocs routing is finalised.)*

---

### 8.2 ADRs (Docs View)

- [ADR‑0106 – Dual ISP Load Balancing for Resiliency](https://doc.hybridops.studio/adr/ADR-0106-dual-isp-load-balancing-resiliency/)  
- [ADR‑0107 – VyOS as Cost-Effective Edge Router](https://doc.hybridops.studio/adr/ADR-0107-vyos-edge-router/)  
- [ADR‑0108 – Full Mesh Topology for High Availability](https://doc.hybridops.studio/adr/ADR-0108-full-mesh-topology-ha/)  
- [ADR‑0109 – NCC Primary Hub with Azure Spoke Connectivity](https://doc.hybridops.studio/adr/ADR-0109-ncc-primary-hub-azure-spoke.md)  
- [ADR‑0110 – VRRP Between Cisco IOS and Arista vEOS](https://doc.hybridops.studio/adr/ADR-0110-vrrp-cisco-arista.md)  
- [ADR‑0301 – pfSense as Firewall for Flow Control](https://doc.hybridops.studio/adr/ADR-0301-pfsense-firewall-flow-control.md)  

(Underlying source paths live under ``docs/adr/`` in the repository.)

---

### 8.3 Repository References (Source Paths)

For assessors who want to see source layout rather than rendered docs:

- ``docs/prerequisites/network-architecture.md``  
- ``docs/adr/ADR-0106-dual-isp-load-balancing-resiliency.md``  
- ``docs/adr/ADR-0107-vyos-edge-router.md``  
- ``docs/adr/ADR-0108-full-mesh-topology-ha.md``  
- ``docs/adr/ADR-0109-ncc-primary-hub-azure-spoke.md``  
- ``docs/adr/ADR-0110-vrrp-cisco-arista.md``  
- ``docs/adr/ADR-0301-pfsense-firewall-flow-control.md``  

- ``docs/howtos/networking/HOWTO_networking_dual-isp-pfsense-csr-lab.md``  
- ``docs/howtos/networking/HOWTO_full-mesh-routing-lab.md``  
- ``docs/howtos/networking/HOWTO_networking_vrrp-cross-vendor-gateway.md``  

- ``docs/runbooks/networking/dual-isp-loadbalancing.md``  
- ``docs/runbooks/networking/full-mesh-topology.md``  
- ``docs/runbooks/networking/ncc-hub-setup.md``  
- ``docs/runbooks/security/pfsense-flow-control.md``  
- ``docs/runbooks/networking/vrrp-cross-vendor.md``  

- Proof directories (screenshots, logs, pcaps):  
  - ``docs/proof/networking/dual-isp-tests/``  
  - ``docs/proof/networking/full-mesh-tests/``  
  - ``docs/proof/networking/ncc/``  
  - ``docs/proof/networking/vrrp-tests/``  
  - ``docs/proof/security/pfsense-ha-tests/``  

---

### 8.4 Demo Videos (External)

- Dual ISP failover demo:  
  `https://www.youtube.com/watch?v=DUAL_ISP_DEMO_ID`  
- NCC hybrid hub demo:  
  `https://www.youtube.com/watch?v=NCC_HUB_DEMO_ID`  
- VRRP cross-vendor failover demo:  
  `https://www.youtube.com/watch?v=VRRP_DEMO_ID`  

(Replace placeholder IDs with real URLs when recorded; keep links mirrored in the docs site under a “Demos” or “Showcases” section.)

---

**Owner:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation
