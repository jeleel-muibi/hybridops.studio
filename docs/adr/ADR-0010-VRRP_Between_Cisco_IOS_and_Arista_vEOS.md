---
id: ADR-0010
title: "VRRP Between Cisco IOS and Arista vEOS"
status: Accepted
date: 2025-10-09
domains: ["networking", "platform", "sre"]
owners: ["jeleel"]
supersedes: []
superseded_by: []
links:
  prs: []
  runbooks: ["../runbooks/networking/vrrp-cross-vendor.md"]
  evidence: ["../proof/networking/vrrp-tests/"]
  diagrams: ["../diagrams/vrrp_cross_vendor_topology.png"]
---

# ADR-0010 — VRRP Between Cisco IOS and Arista vEOS

## Status
Accepted — The platform standardizes on **VRRP interoperability** between Cisco IOS and Arista vEOS routers for seamless Layer-3 gateway failover.

## Context
HybridOps.Studio’s network stack includes both **Cisco CSR1000v** and **Arista vEOS** virtual routers to demonstrate multi-vendor high-availability within the same hybrid topology.  

Initially, failover between vendors relied on static routes or BGP weight adjustment.  
This introduced route learning delays and failed to guarantee low-latency switchover in the event of upstream loss.

**Virtual Router Redundancy Protocol (VRRP)** offers deterministic failover with minimal configuration overhead, vendor neutrality, and state synchronization suitable for lab, DR, and enterprise scenarios.

## Decision
Enable VRRP across all dual-homed VLAN gateways shared between Cisco IOS and Arista vEOS instances.  
Cisco CSR acts as **Master**, Arista as **Backup**, with tracking for WAN and IPsec reachability.

### Configuration Summary
- **Protocol:** VRRPv3 (RFC 5798) to support IPv4 + IPv6.  
- **Virtual IP:** shared default gateway for LAN segments (e.g., `172.16.20.1`).  
- **Tracking:** WAN interface state and IPsec tunnel health via SLA probes.  
- **Preemption:** enabled for deterministic return to Master when recovered.  
- **Failover time:** typically < 1.5 seconds (verified in tests).

Monitoring integration is achieved via SNMP traps to Prometheus Alertmanager and log capture in `docs/proof/networking/vrrp-tests/`.

## Consequences
- ✅ Enables multi-vendor high availability at Layer-3.  
- ✅ Demonstrates enterprise parity between CSR and Arista platforms.  
- ✅ Serves as a foundation for pfSense HA pair integration.  
- ⚠️ Slight vendor syntax differences; playbooks must abstract configuration templates.  
- ⚠️ Requires synchronized interface MTUs to avoid asymmetric routing during transitions.

## References
- [Runbook: Cross-Vendor VRRP Setup](../runbooks/networking/vrrp-cross-vendor.md)  
- [Diagram: VRRP Cross-Vendor Topology](../diagrams/vrrp_cross_vendor_topology.png)  
- [Evidence: VRRP Failover Tests](../proof/networking/vrrp-tests/)

---

**Author / Maintainer:** Jeleel Muibi  
**Project:** [HybridOps.Studio](https://github.com/jeleel-muibi/hybridops.studio)  
**License:** MIT-0 / CC-BY-4.0
