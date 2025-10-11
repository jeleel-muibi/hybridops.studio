---
# ===== Required by the ADR index generator =====
id: ADR-0011
title: "pfSense as Firewall for Flow Control"
status: Accepted
decision_date: 2025-10-09
domain: ["networking", "secops"]
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

# ADR-0011: pfSense as Firewall for Flow Control

## Context
Security and traffic control are essential in the lab. pfSense provides advanced filtering, NAT, and VPN capabilities in an open-source package.

## Decision
Deploy pfSense as the primary firewall between internal lab segments and external networks, handling NAT, filtering, and VPN.

## Consequences
- Positive: Advanced security features, open-source, flexible configuration.
- Negative: Limited performance compared to hardware firewalls.
- Neutral/unknowns: May require tuning for throughput and rule optimization.

## Alternatives considered
1. Cisco ASA — enterprise-grade but costly and complex.
2. Cloud-native firewalls — not suitable for on-prem lab.

## Implementation notes
- Install pfSense in EVE-NG and configure interfaces, rules, and VPN. Validate with traffic flows and firewall logs.

## Links
- PRs: <add>
- Runbooks: <add>
- Evidence: <add>
- Diagrams: <add>
