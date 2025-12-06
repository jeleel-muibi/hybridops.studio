---
id: ADR-0108
title: "Full Mesh Topology for High Availability"
status: Accepted
date: 2025-11-30

category: "01-networking"
supersedes: []
superseded_by: []

links:
  prs: []
  runbooks: []
  howtos: []
  evidence: []
  diagrams: []

draft: false
tags: ["ha", "topology", "mesh", "wan", "resiliency", "routing"]
access: public
---

# Full Mesh Topology for High Availability

## Status

Accepted — the platform standardizes a **full mesh Layer-3 topology** between core edge routers and firewalls to ensure deterministic routing and fault isolation.

## Context

Earlier test environments used a **hub-and-spoke** design between CSR routers and pfSense/VyOS nodes.  
This was simple but introduced clear single points of failure:

- Hub failure affecting all spokes
- Asymmetric routing during VPN cutovers
- Complex troubleshooting when the “hub” was also running experiments

HybridOps.Studio’s networking layer now underpins:

- Dual-ISP connectivity and IPsec DR tunnels (see [ADR-0106](./ADR-0106-dual-isp-load-balancing-resiliency.md))
- Distributed monitoring agents and collectors (Prometheus, NetBox exporters)
- Cross-site automation workflows (Nornir / Ansible against multiple “sites”)

A **full mesh** topology ensures each router maintains a direct path to all other peers, enabling redundant data planes even when individual links or nodes fail.

## Decision

Adopt a **full mesh L3 topology** across all edge routers and firewalls in the WAN/edge layer:

- Each router (CSR1000v, VyOS, pfSense) forms direct adjacencies with all other peers.
- Transit uses **dedicated VLANs** over Proxmox bridges (for on-prem) and equivalent segments in EVE-NG (for simulated sites).
- An optional overlay (e.g. VXLAN) provides a management reachability plane that is independent of the underlay.

### Implementation Summary

- **Routing protocol**  
  - eBGP between all edge routers, no route reflectors (small node count).  
  - Deterministic local-preference and MED policies for primary vs secondary paths.  

- **Physical / virtual transport**  
  - Tagged VLANs on Proxmox bridges (e.g. `vmbr2`, `vmbr3`) for router-to-router transit.  
  - Equivalent VLANs / links defined in EVE-NG topologies.  

- **Overlay (optional)**  
  - VXLAN (e.g. 172.16.50.0/24) for management/control-plane reachability.  
  - Used for automation access when underlay is impaired.

- **Resiliency testing**  
  - Simulated link failures and router reboots.  
  - Target convergence time < 3 seconds for core prefixes.  
  - Test artefacts stored in `docs/proof/networking/full-mesh-tests/`.

## Consequences

### Positive

- ✅ Removes single-hub routing dependencies; multiple independent paths exist.  
- ✅ Simplifies hybrid DR link migration and cloud cutover experiments.  
- ✅ Mirrors typical enterprise designs where DC/edge devices are fully meshed at L3.  
- ✅ Ensures parity between **on-prem Proxmox topologies** and **EVE-NG simulations**.

### Negative

- ⚠ More interfaces, VLANs, and configuration blocks per device.  
- ⚠ Slightly higher control-plane chatter (BGP sessions) — acceptable at current scale.  
- ⚠ Requires disciplined IP addressing and documentation for transit networks.

### Neutral

- Topology can be collapsed back to hub-and-spoke for specific labs if needed.  
- Scaling beyond a small number of nodes may require introducing route reflectors or hierarchical designs (out of scope for this ADR).

## References

- [ADR-0102 – Proxmox as Intra-Site Core Router](./ADR-0102-proxmox-intra-site-core-router.md)
- [ADR-0106 – Dual ISP Load Balancing for Resiliency](./ADR-0106-dual-isp-load-balancing-resiliency.md)
- [ADR-0107 – VyOS as Cost-Effective Edge Router](./ADR-0107-vyos-edge-router.md)
- [ADR-0201 – EVE-NG Network Lab Architecture](./ADR-0201-eve-ng-network-lab-architecture.md)
- [Runbook: Full Mesh Topology Configuration](../runbooks/networking/full-mesh-topology.md)  
- [Diagram: Full Mesh Network Topology](../diagrams/full_mesh_network_topology.png)  
- [Evidence: Routing Convergence Tests](../proof/networking/full-mesh-tests/)  

---

**Maintainer:** HybridOps.Studio
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
