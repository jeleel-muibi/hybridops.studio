---
id: ADR-0004
title: "NCC Primary Hub: Azure as Hybrid Connectivity Core"
status: Accepted
date: 2025-10-08
domains: ["networking", "cloud", "governance"]
owners: ["jeleel"]
supersedes: []
superseded_by: []
links:
  prs: []
  runbooks: ["../runbooks/networking/ncc-hub-setup.md"]
  evidence: ["../proof/networking/ncc/"]
  diagrams: ["../diagrams/ncc_hub_architecture.png"]
---

# ADR-0004 — NCC Primary Hub: Azure as Hybrid Connectivity Core

## Status
Accepted — Azure is designated as the **primary hub** in HybridOps.Studio’s global hybrid network topology, using **Google NCC (Network Connectivity Center)** for cross-cloud federation.

## Context
HybridOps.Studio integrates multiple on-prem sites (Proxmox, pfSense HA, CSR1000v) with Azure and GCP environments.  
A reliable hub-and-spoke backbone is essential for service reachability, cross-cluster observability, and seamless DR.  

Several options were evaluated:
- Azure Virtual WAN + NCC for cross-cloud mesh.
- GCP NCC as the central hub.
- Neutral backbone via WireGuard mesh or VPN gateways.

Azure was chosen as the **primary hub** because:
- It offers consistent IPsec interoperability with on-prem Cisco CSR and pfSense firewalls.
- It integrates natively with NCC for Google-side visibility.
- Its global backbone improves latency and reliability for east-west cloud traffic.

## Decision
Designate **Azure VNet Hub** as the **primary NCC core**.  
GCP NCC remains configured as a peer (read-replica) to allow failover and observability continuity.

### Implementation details
- **Hub:** Azure VNet with VPN Gateway (Route-based, BGP enabled).  
- **Peers:** On-prem pfSense / CSR1000v → IPsec tunnels to Azure → NCC.  
- **DR Path:** GCP NCC configured for route reflection and telemetry.  
- **Monitoring:** Prometheus Federation collects metrics from both Azure and on-prem routers via exporters.

## Consequences
- ✅ Simplifies cross-cloud routing and telemetry.  
- ✅ Reduces latency for east-west traffic.  
- ⚠️ Azure hub downtime would temporarily impact NCC reachability until GCP peer promotion.  
- ⚠️ Slightly higher operational cost due to Azure VPN Gateway SKU.

## References
- [Runbook: NCC Hub Setup](../runbooks/networking/ncc-hub-setup.md)  
- [Diagram: NCC Hybrid Architecture](../diagrams/ncc_hub_architecture.png)  
- [Evidence: NCC Logs and Topology Validation](../proof/networking/ncc/)  

---

**Author / Maintainer:** Jeleel Muibi  
**Project:** [HybridOps.Studio](https://github.com/jeleel-muibi/hybridops.studio)  
**License:** MIT-0 / CC-BY-4.0
