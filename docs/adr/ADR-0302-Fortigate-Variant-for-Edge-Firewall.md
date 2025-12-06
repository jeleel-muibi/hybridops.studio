---
id: ADR-0302
title: "Fortigate Variant for Edge Firewall"
status: Proposed
date: 2025-11-30

category: "03-security"
supersedes: []
superseded_by: []

links:
  prs: []
  runbooks: []
  howtos:
    - "../howtos/networking/HOWTO_networking_fortigate-edge-firewall-variant.md"
  evidence:
    - "../proof/security/fortigate-variant-tests/"
  diagrams: []

draft: true
tags: ["fortigate", "firewall", "security", "edge", "variant"]
access: public
---

# Fortigate Variant for Edge Firewall

## Status

Proposed — Fortigate is supported as an **optional vendor variant** for the edge firewall role.  
pfSense (ADR-0301) remains the **baseline flow-control plane** for HybridOps.Studio.

## Context

HybridOps.Studio already standardises on:

- **pfSense CE** as the primary firewall and flow-control plane (ADR-0301).  
- **CSR1000v / VyOS** as routing and VPN edges (ADR-0107).  

In many enterprise environments, firewall platforms such as **Fortigate** are widely deployed for:

- Next-generation firewalling (application-aware policies, threat feeds).  
- SD-WAN and advanced VPN capabilities.  
- Tight integration with enterprise security tooling.

To demonstrate **portability of the design**, this ADR introduces **Fortigate as a drop-in vendor variant** that can implement the same core policy patterns:

- Segmented zones (mgmt, observability, dev, staging, prod, lab).  
- Policy routing for dual ISP and hybrid paths.  
- NAT and flow-control aligned with the existing ADRs.

## Decision

Introduce a **Fortigate-based edge firewall variant** that:

- Mirrors the pfSense design for:
  - External interfaces (dual ISP uplinks).  
  - Internal zones/VLANs.  
  - Policy routing and NAT patterns.  
- Reuses the same **network and security ADRs** as design constraints:
  - VLAN ranges and roles (ADR-0101).  
  - Proxmox as intra-site core (ADR-0102).  
  - Inter-VLAN firewall policy (ADR-0103).  
  - Dual ISP failover and load balancing (ADR-0106).  
  - pfSense flow-control principles (ADR-0301).

Fortigate **does not replace pfSense** as the canonical implementation but complements it:

- pfSense remains the reference for **open-source, cost-effective** deployments.  
- Fortigate showcases how the same blueprint applies to a **commercial firewall**.

## Rationale

- **Vendor-agnostic credibility**: demonstrates that the security and network architecture is expressed as patterns, not locked to a single product.  
- **Realistic enterprise flavour**: many assessors will recognise Fortigate from production environments.  
- **Reusability**: the same ADRs and runbooks constrain Fortigate policy; we avoid maintaining a completely separate “Fortigate-only” design.

## Consequences

### Positive

- Strengthens the message that **HybridOps.Studio is pattern-driven**, not product-driven.  
- Provides a concrete example of “same architecture, different vendor”.  
- Enables comparative demos (pfSense vs Fortigate) using identical test scenarios.

### Negative

- Additional configuration to maintain (Fortigate policy objects, interfaces, VPNs).  
- Potential licensing cost and platform overhead if fully implemented.

### Neutral

- If Fortigate is not available, the core architecture remains fully represented by pfSense + CSR/VyOS.  
- Evidence for this ADR can be scoped to a **small, focused scenario** (e.g. dual ISP + 2–3 VLANs), not the entire platform.

## Implementation Sketch

- Create a minimal Fortigate topology that mirrors:
  - WAN_A / WAN_B uplinks.  
  - Internal zones for management, observability, and one application VLAN.  
- Implement:
  - Basic firewall policies equivalent to pfSense rules in ADR-0301.  
  - Policy routing / SD-WAN rules equivalent to dual ISP behaviour in ADR-0106.  
- Capture:
  - Screenshots of interface and policy configuration.  
  - Route tables and session views under failover.  
  - Packet captures demonstrating policy behaviour.

Evidence will be collected under:

- `docs/proof/security/fortigate-variant-tests/`

## References

- [ADR-0101 – VLAN Allocation Strategy](./ADR-0101-vlan-allocation-strategy.md)  
- [ADR-0102 – Proxmox as Intra-Site Core Router](./ADR-0102-proxmox-intra-site-core-router.md)  
- [ADR-0103 – Inter-VLAN Firewall Policy](./ADR-0103-inter-vlan-firewall-policy.md)  
- [ADR-0106 – Dual ISP Load Balancing for Resiliency](./ADR-0106-dual-isp-load-balancing-resiliency.md)  
- [ADR-0301 – pfSense as Firewall for Flow Control](./ADR-0301-pfsense-firewall-flow-control.md)  

---

**Owner:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation
