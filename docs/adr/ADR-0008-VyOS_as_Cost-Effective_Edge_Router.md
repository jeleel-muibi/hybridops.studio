---
# ===== Required by the ADR index generator =====
id: ADR-0008
title: "VyOS as Cost-Effective Edge Router"
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

# ADR-0008: VyOS as Cost-Effective Edge Router

## Context
CSR1000v requires a license and has limited forwarding capabilities without it. VyOS is open-source, flexible, and supports IPsec, BGP, and load balancing.

## Decision
Use VyOS as the primary edge router for ISP termination and routing, with CSR1000v retained for protocol demonstration and limited forwarding.

## Consequences
- Positive: Cost savings, open-source flexibility, full feature access.
- Negative: Less enterprise recognition compared to Cisco.
- Neutral/unknowns: May require additional testing for protocol interoperability.

## Alternatives considered
1. CSR1000v only — costly and license-restricted.
2. pfSense — capable but less suited for BGP and routing logic.

## Implementation notes
- Deploy VyOS in EVE-NG and configure IPsec tunnels and BGP. Use CSR1000v for protocol showcase only.

## Links
- PRs: <add>
- Runbooks: <add>
- Evidence: <add>
- Diagrams: <add>
