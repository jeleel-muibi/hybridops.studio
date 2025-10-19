---
id: ADR-0008
title: "VyOS as Cost-Effective Edge Router"
status: Accepted
date: 2025-10-09
domains: ["networking", "platform"]
owners: ["jeleel"]
supersedes: []
superseded_by: []
links:
  prs: []
  runbooks: ["../runbooks/networking/vyos-edge-router.md"]
  evidence: ["../proof/networking/vyos-edge-tests/"]
  diagrams: ["../diagrams/vyos_edge_architecture.png"]
---

# ADR-0008 — VyOS as Cost-Effective Edge Router

## Status
Accepted — VyOS is standardized as the lightweight, cost-effective edge router for lab and small-scale DR deployments.

## Context
HybridOps.Studio previously relied exclusively on **Cisco CSR1000v** routers for network edge automation.  
While CSR remains the enterprise reference router, it is resource-intensive (≥3 GB RAM) and requires licenses for certain features.

VyOS provides:
- Full routing and VPN stack (BGP, OSPF, IPsec, WireGuard).  
- Scriptable configuration via **VyConf** and **REST API**.  
- Native support for **cloud-init**, simplifying Day-0 bootstrapping.  
- Open-source flexibility — ideal for low-cost DR sites and nested virtualization.

The objective is to ensure platform parity between enterprise (CSR) and open source (VyOS) edges without sacrificing governance or automation control.

## Decision
Deploy VyOS as a **complementary edge router** to CSR1000v for test, training, and secondary site operations.  
Use identical automation patterns (Nornir + Ansible + NetBox inventory) to maintain consistency across router classes.

### Implementation Outline
- **Proxmox template:** `vyos-1.5.x-cloudinit.qcow2` imported once and cloned via Terraform.  
- **Configuration management:** handled through Nornir plugins (`vyos_config_push`, `vyos_healthcheck`).  
- **VPN roles:** IPsec primary; WireGuard for developer tunnels and lightweight DR peering.  
- **Integration:** Prometheus node exporter and syslog forwarding to central ELK/Prom stack.

## Consequences
- ✅ Reduces licensing and memory footprint for DR and lab topologies.  
- ✅ Maintains feature symmetry with enterprise routers (routing, VPN, telemetry).  
- ✅ Demonstrates vendor-agnostic automation approach.  
- ⚠️ Requires additional test coverage to validate feature parity (QoS, NAT reflection).  
- ⚠️ Performance lower than CSR under heavy crypto workloads.

## References
- [Runbook: VyOS Edge Router Deployment](../runbooks/networking/vyos-edge-router.md)  
- [Diagram: VyOS Edge Architecture](../diagrams/vyos_edge_architecture.png)  
- [Evidence: VyOS Edge Test Logs](../proof/networking/vyos-edge-tests/)

---

**Author / Maintainer:** Jeleel Muibi  
**Project:** [HybridOps.Studio](https://github.com/jeleel-muibi/hybridops.studio)  
**License:** MIT-0 / CC-BY-4.0
