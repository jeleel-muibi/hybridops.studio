---
# ===== Required by the ADR index generator =====
id: ADR-XXXX                     # e.g., ADR-0005 (matches filename prefix)
title: "<concise-title>"         # short, action-oriented; used in indexes
status: Proposed                 # Proposed | Accepted | Deprecated | Superseded
decision_date: 2025-10-08        # ISO date; the generator reads `decision_date`
domain: []          # one or more of: platform | networking | gitops | governance | secops | database | windows | observability
tags: []                         # optional labels (e.g., [ncc, bgp, ipsec])
draft: false                     # if true, excluded from generated indexes

# ===== Optional (kept for readers; ignored by the generator) =====
date: 2025-10-08                 # alias; keep if you want both
owners: [<github-handle>]        # authors / maintainers
supersedes: []                   # prior ADR IDs this replaces
superseded_by: []                # ADR IDs that replace this one
links:
  prs: []                        # pull request URLs/IDs
  runbooks: []                   # paths like docs/runbooks/dr/dr_cutover.md
  evidence: []                   # paths into docs/proof/** or docs/evidence_map.md anchors
  diagrams: []                   # diagram assets or pages
---

# {id}: {title}

## Context
Describe the problem, constraints, and any forces (compliance, cost, operational risk).

## Decision
State the decision plainly. Include scope and the domain(s) this affects.

## Consequences
- Positive: benefits, simplifications, risk reductions
- Negative: trade‑offs, costs, added complexity
- Neutral/unknowns: open questions or items for review

## Alternatives considered
1. Option A — why rejected
2. Option B — why rejected

## Implementation notes
- Rollout plan, gating checks, migration steps
- Ownership and review cadence (e.g., quarterly)

## Links
- PRs: <add> # optional - remove line if it will not be relevant in this case
- Runbooks: <add> # optional - remove line if it will not be relevant in this case
- Evidence: <add> # optional - remove line if it will not be relevant in this case
- Diagrams: <add> # optional - remove line if it will not be relevant in this case

Put placeholder where link may be helpful.
