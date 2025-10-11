---
# ===== Required by the ADR index generator =====
id: ADR-0009
title: "Full Mesh Topology for High Availability"
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

# ADR-0009: Full Mesh Topology for High Availability

## Context
To eliminate single points of failure and demonstrate enterprise-grade resiliency, a full mesh topology is preferred over partial or hub-and-spoke.

## Decision
Implement full mesh links between routers and switches in the on-prem lab to ensure maximum path redundancy and failover capability.

## Consequences
- Positive: Maximum resiliency, fault tolerance, and path diversity.
- Negative: Higher complexity in routing and troubleshooting.
- Neutral/unknowns: Requires careful route filtering and loop prevention.

## Alternatives considered
1. Partial mesh — simpler but less resilient.
2. Hub-and-spoke — lower cost but introduces single points of failure.

## Implementation notes
- Use OSPF or static routing with route filtering. Validate mesh paths with traceroutes and failover drills.

## Links
- PRs: <add>
- Runbooks: <add>
- Evidence: <add>
- Diagrams: <add>
