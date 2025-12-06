---
id: ADR-0106
title: "Dual ISP Load Balancing for Resiliency"
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
tags: ["networking", "wan", "isp", "resiliency", "load-balancing"]
access: public
---

# Dual ISP Load Balancing for Resiliency

## Status

Accepted — the platform adopts a **dual-ISP configuration** with **policy-based routing** and **automatic failover** for sustained uptime and route diversity.

## Context

HybridOps.Studio’s on-prem infrastructure depends on external internet reachability for:

- Remote Git repository access and CI/CD workflows
- DR connectivity to public cloud (Azure, GCP)
- External observability federation and notifications

A single ISP introduces risk: outages, maintenance windows, or degraded routes can stall automation and replication.

Dual ISPs with health-checked routing policies significantly improve resiliency and provide a more realistic enterprise-style WAN scenario for the HybridOps.Studio blueprint.

## Decision

Implement a **dual-WAN design** at the edge using the network stack defined in:

- [ADR-0107 – VyOS as Cost-Effective Edge Router](./ADR-0107-vyos-edge-router.md)
- [ADR-0108 – Full Mesh Topology for High Availability](./ADR-0108-full-mesh-ha-topology.md)
- [ADR-0201 – EVE-NG Network Lab Architecture](./ADR-0201-eve-ng-network-lab-architecture.md)

Key elements:

- **Primary ISP:** `wan_a` (tier 1, higher bandwidth).
- **Secondary ISP:** `wan_b` (tier 2, lower-cost / backup path).
- **Gateway / path selection:**
  - Health checks per ISP (ICMP and/or HTTP probes).
  - Policy-based routing and/or gateway groups to steer traffic.
- **Hybrid cloud integration:**
  - Dual IPsec/BGP paths to cloud via both ISPs.
  - Preferred path via `wan_a` with automatic failover to `wan_b`.
- **Observability:**
  - Prometheus monitors RTT, packet loss, and flap events on each uplink.

### Failover Behaviour (High-Level)

1. Health probe detects packet loss or latency above a defined threshold on `wan_a`.
2. Edge routing stack:
   - Switches default route to `wan_b`.
   - Moves IPsec/BGP sessions to use `wan_b` as source.
3. Alerts are raised via Prometheus / Alertmanager.
4. When `wan_a` is stable for a sustained window (for example ≥ 3 minutes), traffic is failed back in a controlled way.

Exact thresholds and timers are defined in the associated runbook and configuration.

## Consequences

### Positive

- Provides realistic **enterprise-grade resiliency** for WAN connectivity.
- Protects CI/CD, DR replication, and monitoring from single-ISP failures.
- Demonstrates clear separation between **core routing** (Proxmox, ADR-0102) and **edge/WAN** routing (VyOS/CSR stack).
- Enables controlled testing of failure scenarios (pulling one ISP, simulating brownouts).

### Negative

- Increases complexity at the edge (more routes, more health checks, more moving parts).
- Requires careful NAT and port-forwarding design for inbound services to behave correctly across ISPs.
- More involved troubleshooting when issues arise (must distinguish ISP failure vs. local misconfiguration).

### Neutral

- Additional cost for second ISP link, but acceptable for the blueprint’s learning and showcase value.
- Implementation can start with lab-only simulation (EVE-NG) and later be extended to physical links.

## References

- [ADR-0102 – Proxmox as Intra-Site Core Router](./ADR-0102-proxmox-intra-site-core-router.md)
- [ADR-0107 – VyOS as Cost-Effective Edge Router](./ADR-0107-vyos-edge-router.md)
- [ADR-0108 – Full Mesh Topology for High Availability](./ADR-0108-full-mesh-ha-topology.md)
- [ADR-0201 – EVE-NG Network Lab Architecture](./ADR-0201-eve-ng-network-lab-architecture.md)
- [Runbook: Dual ISP Load Balancing](../runbooks/networking/dual-isp-loadbalancing.md)  
- [Diagram: Dual ISP Architecture](../diagrams/dual_isp_load_balancing.png)  
- [Evidence: Gateway Failover Logs](../proof/networking/dual-isp-tests/)
  - Health-check logs
  - BGP / IPsec session logs
  - Ping / traceroute before/after failover

---

**Maintainer:** HybridOps.Studio
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
