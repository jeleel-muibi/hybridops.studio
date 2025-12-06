---
id: ADR-0107
title: "VyOS as Cost-Effective Edge Router"
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
tags: ["vyos", "edge", "router", "wan", "firewall", "vpn"]
access: public
---

# VyOS as Cost-Effective Edge Router

## Status

Accepted — VyOS is standardized as the lightweight, cost-effective **edge router** for lab, test, and small-scale DR “sites”, complementing Cisco CSR1000v.

## Context

HybridOps.Studio originally used **Cisco CSR1000v** as the primary enterprise reference router for:

- Hybrid WAN and VPN connectivity
- BGP/OSPF routing scenarios
- Edge firewalling and NAT
- DR connectivity to public cloud

CSR remains the “enterprise benchmark”, but it is:

- Resource-intensive (≥ 3 GB RAM per instance)
- License-sensitive for certain features
- Less friendly for large numbers of nested/lab topologies

VyOS offers:

- Full routing and VPN stack (BGP, OSPF, IPsec, WireGuard)
- Scriptable configuration (CLI, VyConf, REST API)
- Native **cloud-init** support for Day-0 bootstrapping
- Open-source licensing and lower resource footprint

The goal is to maintain platform parity between an **enterprise-class edge** (CSR) and an **open-source edge** (VyOS) while using the same automation patterns and governance.

## Decision

Standardize **VyOS** as a cost-effective edge router alongside CSR1000v:

- Use **VyOS** for:
  - Lab and training topologies
  - Secondary “sites” and low-cost DR scenarios
  - Developer VPN / WireGuard access
- Keep **CSR1000v** as:
  - Primary reference for “big vendor” enterprise scenarios
  - Benchmark for performance and feature comparison

Automation approach:

- Shared inventory via **NetBox** (planned) and/or structured YAML
- Network automation via **Nornir + Ansible**, with device-specific playbooks but common patterns
- Shared observability patterns (Prometheus, syslog, flow logs)

### Implementation Outline

- **Proxmox template**  
  - Import `vyos-1.5.x-cloudinit.qcow2` once.  
  - Turn it into a Proxmox VM template (cloud-init enabled).  
  - Clone via Terraform modules for edge/lab routers.

- **Day-0 / Day-1 configuration**  
  - Use cloud-init for base network + SSH + management access.  
  - Apply full config via Nornir/Ansible (`vyos_config_push`, `vyos_healthcheck`).  
  - Store canonical configs under `infra/network/config/vyos/`.

- **VPN and edge roles**  
  - IPsec as primary for site-to-site and cloud DR.  
  - WireGuard for developer tunnels and lightweight DR peering.  
  - Optional NAT / firewall rules for small “edge site” patterns.

- **Observability and logging**  
  - Export metrics via node_exporter/agent or SNMP into Prometheus.  
  - Forward syslog to central log stack (Loki/ELK).  
  - Capture test evidence under `docs/proof/networking/vyos-edge-tests/`.

## Consequences

### Positive

- ✅ Dramatically reduces licensing costs and RAM footprint for DR and lab topologies.  
- ✅ Demonstrates **vendor-agnostic** automation (same pipelines, different vendors).  
- ✅ Easier to spin up multiple “sites” in EVE-NG or Proxmox for training and demos.  
- ✅ Aligns with the “enterprise blueprint” story: CSR for reference, VyOS for cost-effective roll-out.

### Negative

- ⚠ Requires explicit feature parity testing (QoS, NAT reflection, advanced VPN options).
- ⚠ Crypto performance can be lower than CSR under heavy VPN load.  
- ⚠ Some enterprise-specific features (e.g. certain IOS-XE features) are not available or behave differently.

### Neutral

- VyOS and CSR can coexist in the same topologies (mixed labs).  
- Migration between CSR and VyOS edges is a deliberate, tested exercise (not automatic).

## References

- [ADR-0102 – Proxmox as Intra-Site Core Router](./ADR-0102-proxmox-intra-site-core-router.md)
- [ADR-0106 – Dual ISP Load Balancing for Resiliency](./ADR-0106-dual-isp-load-balancing-resiliency.md)
- [ADR-0108 – Full Mesh Topology for High Availability](./ADR-0108-full-mesh-ha-topology.md)
- [ADR-0201 – EVE-NG Network Lab Architecture](./ADR-0201-eve-ng-network-lab-architecture.md)
- [Runbook: VyOS Edge Router Deployment](../runbooks/networking/vyos-edge-router.md)  
- [Diagram: VyOS Edge Architecture](../diagrams/vyos_edge_architecture.png)  
- [Evidence: VyOS Edge Test Logs](../proof/networking/vyos-edge-tests/)

---

**Maintainer:** HybridOps.Studio
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
