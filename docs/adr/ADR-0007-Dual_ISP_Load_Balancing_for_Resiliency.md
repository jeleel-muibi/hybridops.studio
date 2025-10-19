---
id: ADR-0007
title: "Dual ISP Load Balancing for Resiliency"
status: Accepted
date: 2025-10-09
domains: ["networking", "secops", "platform"]
owners: ["jeleel"]
supersedes: []
superseded_by: []
links:
  prs: []
  runbooks: ["../runbooks/networking/dual-isp-loadbalancing.md"]
  evidence: ["../proof/networking/dual-isp-tests/"]
  diagrams: ["../diagrams/dual_isp_load_balancing.png"]
---

# ADR-0007 — Dual ISP Load Balancing for Resiliency

## Status
Accepted — The platform adopts a **dual-ISP configuration** with **policy-based routing** and **automatic failover** for sustained uptime and route diversity.

## Context
HybridOps.Studio’s on-prem infrastructure (Proxmox cluster, pfSense HA, CSR1000v routers) depends on external internet reachability for:
- Remote Git repository synchronization,
- Cloud DR connectivity (Azure + GCP),
- External observability federation.

A single ISP introduces risk: outages, maintenance windows, or degraded routes can stall automation and replication pipelines.  
Dual ISPs, configured with intelligent routing policies and health checks, ensure continuous connectivity without manual intervention.

## Decision
Implement **dual-WAN configuration** on pfSense HA nodes, using **gateway groups** and **failover tiers**.  
Cisco CSR1000v edge routers will also maintain **dual IPsec tunnels** (one per ISP) for hybrid cloud reachability.

### Configuration Summary
- **Primary ISP:** `wan_a` (tier 1, 1 Gbps).  
- **Secondary ISP:** `wan_b` (tier 2, 500 Mbps).  
- **Gateway Group:** triggers automatic failover if primary gateway health checks fail (ICMP or HTTP).  
- **CSR1000v Integration:** BGP and IPsec route preferences adjusted dynamically to match pfSense failover.  
- **Monitoring:** Prometheus node exporter tracks RTT and packet loss on both uplinks.

### Failover Logic
1. Detect packet loss or latency above 300 ms on `wan_a`.  
2. Switch default route and IPsec source interface to `wan_b`.  
3. Notify Prometheus Alertmanager and log event to `docs/proof/networking/dual-isp-tests/alerts.json`.  
4. Restore to `wan_a` when stability is observed for ≥ 3 minutes.

## Consequences
- ✅ Provides continuous uptime and route redundancy.  
- ✅ Enables real-time monitoring and alert correlation.  
- ✅ Demonstrates enterprise-grade resilience for assessors and audits.  
- ⚠️ Slightly more complex routing policy set.  
- ⚠️ Requires NAT reflection adjustments for inbound services.

## References
- [Runbook: Dual ISP Load Balancing](../runbooks/networking/dual-isp-loadbalancing.md)  
- [Diagram: Dual ISP Architecture](../diagrams/dual_isp_load_balancing.png)  
- [Evidence: Gateway Failover Logs](../proof/networking/dual-isp-tests/)

---

**Author / Maintainer:** Jeleel Muibi  
**Project:** [HybridOps.Studio](https://github.com/jeleel-muibi/hybridops.studio)  
**License:** MIT-0 / CC-BY-4.0
