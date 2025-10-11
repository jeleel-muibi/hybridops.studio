---
# ===== Required by the ADR index generator =====
id: ADR-0010
title: "VRRP Between Cisco IOS and Arista vEOS"
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

# ADR-0010: VRRP Between Cisco IOS and Arista vEOS

## Context
Gateway redundancy is needed at the access layer. Cisco IOS and Arista vEOS support VRRP, enabling seamless failover between switches.

## Decision
Configure VRRP between Cisco IOS and Arista vEOS switches to provide high availability for default gateway services.

## Consequences
- Positive: Seamless failover, multi-vendor interoperability.
- Negative: Requires careful configuration and testing for compatibility.
- Neutral/unknowns: May need tuning of priority and preemption settings.

## Alternatives considered
1. HSRP — Cisco-only, not interoperable with Arista.
2. Static routing — no failover capability.

## Implementation notes
- Enable VRRP on both platforms and test failover scenarios. Document behavior and validate with ping tests and routing tables.

## Links
- PRs: <add>
- Runbooks: <add>
- Evidence: <add>
- Diagrams: <add>
