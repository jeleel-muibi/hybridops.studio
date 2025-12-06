---
id: ADR-0301
title: "pfSense as Firewall for Flow Control"
status: Proposed
date: 2025-11-30

category: "03-security"
supersedes: []
superseded_by: []

links:
  prs: []
  runbooks: []
  howtos: []
  evidence: []
  diagrams: []

draft: true
tags: ["pfsense", "firewall", "security", "flow-control"]
access: public
---

# pfSense as Firewall for Flow Control

## Status

Proposed — pfSense CE is standardised as the primary firewall and traffic-control layer for HybridOps.Studio’s on-prem and hybrid environments.

## Context

Earlier prototypes relied solely on CSR1000v or VyOS for both routing and firewalling.  
This blurred responsibilities around:

- Session state tracking
- NAT and policy routing
- Deep packet inspection and logging

Troubleshooting during failover and DR simulations became more complex and less auditable.

pfSense CE (and optionally pfSense Plus) brings:

- Mature **stateful inspection** firewall engine
- Granular **inbound/outbound NAT** and **policy routing**
- Built-in **CARP** (Common Address Redundancy Protocol) for HA pairs
- Integrated **IPsec and OpenVPN** support
- Strong compatibility with monitoring and automation (XMLRPC API, emerging REST endpoints)

Separating **routing** (CSR/VyOS) from **flow-control and security** (pfSense) improves clarity and auditability across hybrid boundaries.

## Decision

Adopt pfSense as the default **firewall and flow-control plane** for on-prem, nested, and DR sites.

### Design Principles

- **Layered defence:**  
  - Proxmox / routers provide intra-site routing and VLAN gateways (ADR-0102)  
  - pfSense appliances enforce perimeter and policy controls
- **HA pairing:**  
  - Use CARP for virtual IPs and XMLRPC for configuration sync between `fw-01` and `fw-02`
- **Policy routing:**  
  - Use gateway groups for steering traffic across dual ISPs (ADR-0106)
  - Distinguish internet, IPsec, and DR paths
- **Telemetry:**  
  - pfTop, netflow, and SNMP integration with Prometheus/ELK stack
- **DR support:**  
  - Reuse configuration patterns for cloud pfSense instances (e.g., pfSense+ in Azure)

## Consequences

### Positive

- ✅ Clear demarcation between routing (CSR/VyOS), firewalling (pfSense), and applications
- ✅ Native HA through CARP and automatic config synchronisation
- ✅ Transparent traffic shaping and NAT tracking during DR cutover
- ✅ Strong story for “enterprise-style” firewalling layered onto your core/edge design

### Negative

- ⚠ Adds at least one extra VM per site for HA (acceptable trade-off)
- ⚠ Automation APIs are more limited than pure network OS; Ansible roles rely on SSH/XMLRPC

### Neutral

- pfSense can be combined with other firewalls (e.g., cloud-native firewalls) in future ADRs
- Migration to pfSense Plus or alternative firewalls remains possible without redesigning the overall pattern

## References

- [ADR-0102 – Proxmox as Intra-Site Core Router](./ADR-0102-proxmox-intra-site-core-router.md)
- [ADR-0106 – Dual ISP Load Balancing for Resiliency](./ADR-0106-dual-isp-load-balancing-resiliency.md)
- [ADR-0108 – Full Mesh Topology for High Availability](./ADR-0108-full-mesh-ha-topology.md)
- [ADR-0201 – EVE-NG Network Lab Architecture](./ADR-0201-eve-ng-network-lab-architecture.md)
- [Runbook: pfSense Firewall Flow Control](../runbooks/security/pfsense-flow-control.md)  
- [Diagram: pfSense Firewall Architecture](../diagrams/pfsense_firewall_architecture.png)  
- [Evidence: pfSense HA Validation Tests](../proof/security/pfsense-ha-tests/)

---

**Maintainer:** HybridOps.Studio
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
