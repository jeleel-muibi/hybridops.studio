---
# ===== Required by the ADR index generator =====
id: ADR-0007
title: "Dual ISP Load Balancing for Resiliency"
status: Accepted
decision_date: 2025-10-09
domain: ["networking"]
tags: []
draft: false

# ===== Optional (kept for readers; ignored by the generator) =====
date: 2025-10-09
owners: [jeleel-dev]
supersedes: []
superseded_by: []
links:
  prs: []
  runbooks: []
  evidence: []
  diagrams: []
---

# ADR-0007: Dual ISP Load Balancing for Resiliency

## Context
HybridOps.Studio requires high availability and bandwidth optimization. A single ISP introduces risk of downtime and limited throughput. Dual ISP setup enables failover and load balancing.

## Decision
Implement dual ISP connectivity using IPsec VPN and VTI interfaces, with load balancing and failover logic handled by VyOS or IP SLA.

## Consequences
- Positive: Redundancy, improved throughput, fault tolerance.
- Negative: Increased complexity in routing and failover logic.
- Neutral/unknowns: Requires ongoing monitoring and tuning of health checks.

## Alternatives considered
1. Single ISP — simpler but less resilient.
2. SD-WAN — more advanced but costly and complex.

## Implementation notes
- Configure VyOS with health checks and weighted routes. Document failover behavior and validate with traceroutes and simulated outages.

## Links
- PRs: <add>
- Runbooks: <add>
- Evidence: <add>
- Diagrams: <add>
