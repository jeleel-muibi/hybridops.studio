---
id: ADR-0110
title: "VRRP Between Cisco IOS and Arista vEOS"
status: Proposed
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

draft: true
tags: ["vrrp", "ha", "cisco", "arista", "gateway"]
access: public
---

# VRRP Between Cisco IOS and Arista vEOS

## Status

Proposed — the platform standardizes on **VRRP interoperability** between Cisco IOS and Arista vEOS routers for seamless Layer-3 gateway failover.

## Context

HybridOps.Studio’s network stack includes both **Cisco CSR1000v** and **Arista vEOS** virtual routers to demonstrate **multi-vendor high availability** within the same hybrid topology.

Initial failover relied on:

- Static route changes, or
- BGP weight / local-preference manipulation

This introduced:

- Route learning delays during failover
- Inconsistent gateway behaviour for LAN segments
- Extra complexity for cross-vendor demonstrations

**Virtual Router Redundancy Protocol (VRRP)** provides:

- Deterministic default-gateway failover
- Vendor-neutral configuration model
- Sub-second convergence in many cases
- Clear separation between data-plane and control-plane routing

## Decision

Enable **VRRP** across all dual-homed VLAN gateways shared between Cisco IOS and Arista vEOS instances:

- Cisco CSR acts as **Master** for most lab scenarios
- Arista vEOS acts as **Backup**
- WAN and IPsec reachability are tracked to influence VRRP priority

### Configuration Summary

- **Protocol:** VRRPv3 (RFC 5798) to support IPv4 and IPv6
- **Virtual IP:** shared default gateway for LAN segments (e.g. `172.16.20.1`)
- **Tracking:** WAN interface state and IPsec tunnel health via SLA/track objects
- **Preemption:** enabled for deterministic return to Master when recovered
- **Target failover time:** < 1.5 seconds (to be validated)

Monitoring:

- SNMP traps and/or syslog events exported to Prometheus / Alertmanager
- Evidence stored under `docs/proof/networking/vrrp-tests/`

## Consequences

### Positive

- ✅ Demonstrates **multi-vendor HA** at Layer-3 (CSR + vEOS)
- ✅ Provides realistic enterprise-style gateway behaviour
- ✅ Forms a pattern later usable with pfSense and VyOS

### Negative

- ⚠ Vendor syntax differences require templating in Ansible/Nornir
- ⚠ VRRP and routing protocols must be carefully coordinated to avoid loops

### Neutral

- Implementation can be confined to specific “HA lab” VLANs initially
- Future ADRs may formalize VRRP + BGP design patterns

## References

- [ADR-0102 – Proxmox as Intra-Site Core Router](./ADR-0102-proxmox-intra-site-core-router.md)
- [ADR-0108 – Full Mesh Topology for High Availability](./ADR-0108-full-mesh-ha-topology.md)
- [Runbook: Cross-Vendor VRRP Setup](../runbooks/networking/vrrp-cross-vendor.md)  
- [Diagram: VRRP Cross-Vendor Topology](../diagrams/vrrp_cross_vendor_topology.png)  
- [Evidence: VRRP Failover Tests](../proof/networking/vrrp-tests/)

---

**Maintainer:** HybridOps.Studio
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
