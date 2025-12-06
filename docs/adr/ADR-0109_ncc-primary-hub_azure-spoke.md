---
id: ADR-0109
title: "NCC Primary Hub with Azure Spoke Connectivity"
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
tags: ["azure", "hub-spoke", "ncc", "cloud-networking", "hybrid"]
access: public
---

# NCC Primary Hub: Azure as Hybrid Connectivity Core

## Status

Proposed — Azure is designated as the **primary hub** in HybridOps.Studio’s global hybrid network topology, using **Google NCC (Network Connectivity Center)** for cross-cloud federation.

## Context

HybridOps.Studio integrates multiple on-prem sites (Proxmox, pfSense HA, CSR1000v, VyOS) with Azure and GCP environments.  

A reliable hub-and-spoke backbone is essential for:

- Service reachability across sites and clouds
- Cross-cluster observability
- Seamless DR and traffic engineering experiments

Options evaluated:

- Azure Virtual WAN + NCC as the central hub
- GCP NCC as the central hub
- Neutral backbone via WireGuard mesh or vendor VPN gateways

Azure is preferred as the **primary hub** because:

- It offers consistent IPsec interoperability with CSR and pfSense
- It integrates cleanly with GCP NCC for Google-side visibility
- Its global backbone improves latency and reliability for east–west cloud traffic

## Decision

Designate an **Azure VNet hub** as the **primary hybrid connectivity core**:

- Azure VPN Gateway (route-based, BGP enabled) terminates IPsec from on-prem and lab edges
- GCP NCC peers with the Azure hub for route and topology awareness
- On-prem pfSense / CSR / VyOS appliances treat Azure as the default “cloud hub”

GCP NCC remains configured as a secondary peer to allow **failover** and **observability continuity** if the Azure hub is unavailable.

### Implementation Summary

- **Hub VNet:** Azure VNet with VPN Gateway (BGP enabled)
- **Spokes:**
  - On-prem pfSense / CSR / VyOS → IPsec to Azure hub
  - GCP NCC → interconnect / VPN to Azure hub
- **Routing:**
  - BGP sessions between hub and edge devices
  - Policy-based routing for DR paths and test scenarios
- **Monitoring:**
  - Prometheus metrics from edge routers and cloud gateways
  - Evidence of failover tests stored under `docs/proof/networking/ncc/`

## Consequences

### Positive

- ✅ Simplifies cross-cloud routing and telemetry
- ✅ Provides a clear “primary hub” story for assessors (Azure-as-core)
- ✅ Reduces latency for east–west traffic between clouds

### Negative

- ⚠ Azure hub downtime temporarily impacts NCC-based reachability until GCP promotion
- ⚠ Additional operational cost for Azure VPN Gateway SKU

### Neutral

- Hub role can be rebalanced towards GCP NCC in future ADRs if requirements change
- Design remains compatible with WireGuard or other overlay options

## References

- [ADR-0106 – Dual ISP Load Balancing for Resiliency](./ADR-0106-dual-isp-load-balancing-resiliency.md)
- [ADR-0107 – VyOS as Cost-Effective Edge Router](./ADR-0107-vyos-edge-router.md)
- [ADR-0108 – Full Mesh Topology for High Availability](./ADR-0108-full-mesh-ha-topology.md)
- [ADR-0201 – EVE-NG Network Lab Architecture](./ADR-0201-eve-ng-network-lab-architecture.md)
- [Runbook: NCC Hub Setup](../runbooks/networking/ncc-hub-setup.md)  
- [Diagram: NCC Hybrid Architecture](../diagrams/ncc_hub_architecture.png)  
- [Evidence: NCC Logs and Topology Validation](../proof/networking/ncc/)  

---

**Maintainer:** HybridOps.Studio
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
