---
id: ADR-0011
title: "pfSense as Firewall for Flow Control"
status: Accepted
date: 2025-10-09
domains: ["networking", "secops", "platform"]
owners: ["jeleel"]
supersedes: []
superseded_by: []
links:
  prs: []
  runbooks: ["../runbooks/security/pfsense-flow-control.md"]
  evidence: ["../proof/security/pfsense-ha-tests/"]
  diagrams: ["../diagrams/pfsense_firewall_architecture.png"]
---

# ADR-0011 — pfSense as Firewall for Flow Control

## Status
Accepted — pfSense CE is standardized as the primary firewall and traffic-control layer for HybridOps.Studio’s on-premise and hybrid environments.

## Context
Earlier prototypes relied solely on CSR1000v or VyOS for both routing and firewalling.  
This design blurred responsibilities — particularly around session state, NAT, and packet inspection — leading to complex troubleshooting during failover and DR simulations.

pfSense CE (and optionally pfSense Plus) introduces:
- A mature **stateful inspection** firewall engine.  
- Granular control of **inbound/outbound NAT and policy routing**.  
- Built-in support for **CARP (Common Address Redundancy Protocol)** for HA pairs.  
- **IPsec and OpenVPN integration** consistent with enterprise-grade DR models.  
- Strong compatibility with monitoring and automation (XMLRPC API, RESTCONF).

This separation of routing (handled by CSR/VyOS) from flow-control and security (pfSense) increases both clarity and auditability across hybrid boundaries.

## Decision
Adopt pfSense as the default **firewall and flow-control plane** across on-prem, nested, and DR sites.

### Design Principles
- **Layered defense:** pfSense at perimeter, routers handle inter-VLAN routing.  
- **HA Pairing:** use CARP and XMLRPC for config sync between `fw-01` and `fw-02`.  
- **Policy routing:** selective next-hop control for IPsec, internet, or DR traffic.  
- **Telemetry:** pfTop, netflow, and SNMP integration with Prometheus/ELK stack.  
- **DR support:** identical configuration exported for cloud pfSense instances (e.g., pfSense+ on Azure).

## Consequences
- ✅ Clear demarcation between routing, firewalling, and application access.  
- ✅ Native HA through CARP and automatic config synchronization.  
- ✅ Enables transparent traffic shaping and NAT tracking during DR cutover.  
- ⚠️ Adds one more VM per site for HA (acceptable trade-off).  
- ⚠️ Limited automation API; Ansible roles rely on SSH or XMLRPC for idempotency.

## References
- [Runbook: pfSense Firewall Flow Control](../runbooks/security/pfsense-flow-control.md)  
- [Diagram: pfSense Firewall Architecture](../diagrams/pfsense_firewall_architecture.png)  
- [Evidence: pfSense HA Validation Tests](../proof/security/pfsense-ha-tests/)

---

**Author / Maintainer:** Jeleel Muibi  
**Project:** [HybridOps.Studio](https://github.com/jeleel-muibi/hybridops.studio)  
**License:** MIT-0 / CC-BY-4.0
