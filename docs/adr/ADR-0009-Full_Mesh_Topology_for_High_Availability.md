---
id: ADR-0009
title: "Full Mesh Topology for High Availability"
status: Accepted
date: 2025-10-09
domains: ["networking", "platform", "sre"]
owners: ["jeleel"]
supersedes: []
superseded_by: []
links:
  prs: []
  runbooks: ["../runbooks/networking/full-mesh-topology.md"]
  evidence: ["../proof/networking/full-mesh-tests/"]
  diagrams: ["../diagrams/full_mesh_network_topology.png"]
---

# ADR-0009 — Full Mesh Topology for High Availability

## Status
Accepted — The platform standardizes a **full mesh Layer-3 topology** between core routers and firewalls to guarantee deterministic routing and fault isolation.

## Context
In prior test environments, routing relied on **hub-and-spoke** links between CSR routers and pfSense nodes.  
While simpler, this approach created single points of failure — especially during hybrid VPN cutovers or inter-site migrations.

HybridOps.Studio’s networking layer now serves as the foundation for:
- Dual-ISP connectivity and IPsec DR tunnels (see [ADR-0007](./ADR-0007-Dual_ISP_Load_Balancing_for_Resiliency.md)),
- Distributed monitoring and configuration agents (Prometheus, NetBox collectors),
- Cross-site automation workflows (Nornir, Ansible pull).

A full mesh topology ensures that **each node maintains a direct path** to every other peer, allowing redundant data planes even under partial failure.

## Decision
Adopt a **full mesh topology** across all core routers and firewalls.  
Each router (CSR1000v, VyOS, or pfSense) peers directly with its counterparts over isolated transit VLANs or VXLAN segments.

### Implementation Summary
- **Routing protocol:** eBGP with route reflectors disabled for simplicity.  
- **Redundancy model:** direct L3 adjacencies across all nodes.  
- **Transport:** tagged VLANs over Proxmox bridges (`vmbr2`, `vmbr3`).  
- **Management overlay:** VXLAN tunnels (172.16.50.0/24) provide auxiliary reachability.  
- **Failover testing:** Simulated link failures confirm convergence < 3 seconds.

Routing convergence and state synchronization are continuously monitored via Prometheus and logged to `docs/proof/networking/full-mesh-tests/`.

## Consequences
- ✅ No single-point routing dependencies.  
- ✅ Simplifies hybrid DR link migration and cloud cutover testing.  
- ✅ Ensures topology parity between on-prem and nested EVE-NG simulations.  
- ⚠️ More interfaces and configuration blocks per device.  
- ⚠️ Slightly higher control-plane chatter (manageable for small clusters).

## References
- [Runbook: Full Mesh Topology Configuration](../runbooks/networking/full-mesh-topology.md)  
- [Diagram: Full Mesh Network Topology](../diagrams/full_mesh_network_topology.png)  
- [Evidence: Routing Convergence Tests](../proof/networking/full-mesh-tests/)  

---

**Author / Maintainer:** Jeleel Muibi  
**Project:** [HybridOps.Studio](https://github.com/jeleel-muibi/hybridops.studio)  
**License:** MIT-0 / CC-BY-4.0
