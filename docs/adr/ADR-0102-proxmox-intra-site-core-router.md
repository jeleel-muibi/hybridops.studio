---
id: ADR-0102
title: "Proxmox as Intra-Site Core Router"
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
tags: ["routing", "proxmox", "layer3", "nat", "core"]
access: public
---

# Proxmox as Intra-Site Core Router

**Status:** Accepted — Uses Proxmox as the intra-site Layer 3 core, terminating VLAN gateways and handling inter-VLAN routing and NAT while leaving WAN edge to dedicated routers.

## Context

With VLAN-based segmentation in place (see [ADR-0101 – VLAN Allocation Strategy](./ADR-0101-vlan-allocation-strategy.md)), VMs in different VLANs require routing to communicate with each other and with the internet.

Possible Layer 3 routing options:

- External physical router
- Virtual router appliance (pfSense, VyOS)
- EVE-NG virtual routers inline
- Proxmox host acting as router

## Decision

### Scope

Proxmox acts as the **Layer 3 core for the on-prem site**: it terminates VLAN gateways, routes between internal segments, and performs NAT towards the upstream network.

Edge connectivity — dual ISP, WAN routing, and VPNs to public cloud and remote “sites” — is handled by dedicated virtual edge routers (CSR/VyOS) as defined in:

- [ADR-0106 – Dual ISP Load Balancing for Resiliency](./ADR-0106-dual-isp-load-balancing-resiliency.md)
- [ADR-0107 – VyOS as Cost-Effective Edge Router](./ADR-0107-vyos-edge-router.md)
- [ADR-0108 – Full Mesh Topology for High Availability](./ADR-0108-full-mesh-ha-topology.md)

Proxmox is **not** the internet edge; it is the intra-site core.

### Core routing role

The Proxmox host acts as the Layer 3 router for all internal VLANs:

- Each VLAN subinterface (`vmbr0.10`, `vmbr0.20`, etc.) receives an IP address used as the default gateway for that VLAN.
- NAT (masquerade) is applied for internet-bound traffic from all VLANs via the `vmbr0` uplink.
- Inter-VLAN routing is controlled using `iptables` firewall rules (see [ADR-0103 – Inter-VLAN Firewall Policy](./ADR-0103-inter-vlan-firewall-policy.md)).

## Rationale

### Simplicity

- Single point of configuration and routing for intra-site traffic.
- No additional VMs required purely for internal routing.
- Relies on the mature and well-understood Linux networking stack.

### Performance

- No extra virtualization layer for intra-site routing.
- Kernel routing runs at line speed.
- Lower latency than placing a virtual appliance in the path.

### Operational clarity

- Network configuration resides in `/etc/network/interfaces` (version-controlled).
- Firewall rules are managed via `iptables` and automated through Ansible.
- Standard Linux tooling (`ip`, `ss`, `tcpdump`) is available for diagnostics.

## Consequences

### Positive

- Clear separation of **core** (Proxmox) vs **edge** (VyOS/CSR, EVE-NG) responsibilities.
- Simple, inspectable routing configuration.
- Easy to reproduce on other Proxmox-based sites.

### Negative

- Proxmox host is a single point of failure for intra-site routing in this phase.
- Tight coupling between compute and routing on the same node.
- Migration to dedicated core routers later will require planned cutover.

### Neutral

- Edge routing and cloud connectivity decisions are captured separately in ADR-0106, ADR-0107, ADR-0108, and ADR-0201.
- This pattern mirrors many small-site enterprise deployments where hypervisors provide VLAN gateways while edge routers handle WAN.

## Implementation

- VLAN subinterfaces defined on `vmbr0` in `/etc/network/interfaces`.
- `net.ipv4.ip_forward=1` enabled for routing.
- `iptables` `POSTROUTING` rules provide NAT for each VLAN towards the upstream interface.
- Inter-VLAN policies enforced via `iptables` `FORWARD` chain (see ADR-0103).

## References

- [ADR-0101 – VLAN Allocation Strategy](./ADR-0101-vlan-allocation-strategy.md)
- [ADR-0103 – Inter-VLAN Firewall Policy](./ADR-0103-inter-vlan-firewall-policy.md)
- [ADR-0104 – Static IP Allocation with Terraform IPAM](./ADR-0104-static-ip-allocation-terraform-ipam.md)
- [ADR-0105 – Dual Uplink Design (Ethernet/WiFi Failover)](./ADR-0105-dual-uplink-ethernet-wifi-failover.md)
- [ADR-0201 – EVE-NG Network Lab Architecture](./ADR-0201-eve-ng-network-lab-architecture.md)

---

**Maintainer:** HybridOps.Studio
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
