---
id: ADR-0201
title: "EVE-NG Network Lab Architecture"
status: Accepted
date: 2025-11-30

category: "02-platform"
supersedes: []
superseded_by: []

links:
  prs: []
  runbooks: []
  howtos: []
  evidence: []
  diagrams: []

draft: false
tags: ["eve-ng", "network-simulation", "lab", "testing"]
access: public
---

# EVE-NG Network Lab Architecture

**Status:** Accepted — Positions EVE-NG as an isolated lab in VLAN 50, enabling realistic network experiments without putting it in the production traffic path.

## Context

HybridOps.Studio includes networking scenarios that benefit from dedicated lab infrastructure:

- WAN failover testing
- Multi-site connectivity and routing protocol experiments
- Firewall rule validation
- Network automation exercises

EVE-NG is the primary network simulation platform and supports a broad range of virtual devices.

The design choice is where to position EVE-NG relative to the operational path:

- **Inline** — all production/dev traffic traverses EVE-NG virtual routers
- **Parallel** — EVE-NG is used only for isolated experiments

## Decision

Run EVE-NG as **parallel lab infrastructure** in an isolated VLAN rather than inline in the critical path.

- EVE-NG VM resides in **VLAN 50 (Lab/Testing)**, defined in ADR-0101
- Inter-VLAN firewall policy (ADR-0103) prevents lab traffic from influencing production, staging, or development environments
- Optional trunking can connect selected VLANs to EVE-NG for specific test scenarios, but is disabled by default

EVE-NG is an **experimentation surface**, not a dependency for normal operations.

## Rationale

- Keeps the lab **out of the critical path**, so experiments cannot break running services
- Mirrors typical enterprise practice where labs are separate from production routing
- Lab routing, packet captures, and automation exercises can proceed freely
- Failure or reconfiguration of EVE-NG does not affect workloads

## Consequences

### Positive

- ✅ Experiments and misconfigurations in EVE-NG do not interrupt production, staging, or dev workloads
- ✅ Network automation and failure scenarios can be explored safely
- ✅ Scaling or re-architecting the lab does not require changes to operational VLANs

### Negative

- ⚠ End-to-end behaviour of production workloads under advanced WAN scenarios must sometimes be approximated
- ⚠ Additional configuration required to attach real VLANs to EVE-NG for hybrid tests

### Neutral

- Multiple lab topologies can be defined inside EVE-NG without changing the external design
- Future migration to GNS3 or containerlab would reuse the same isolation model

## Implementation

- EVE-NG VM placed in VLAN 50 with a static IP from the lab subnet allocation
- Proxmox inter-VLAN firewall rules deny traffic between VLAN 50 and operational VLANs by default
- Optional test cases may:
  - Add a secondary NIC on EVE-NG with a tagged VLAN trunk
  - Use temporary firewall exceptions for controlled test scenarios

Validation:

- EVE-NG can reach the upstream gateway and internet via VLAN 50
- No direct connectivity exists from lab devices to production/staging/dev VMs unless explicitly allowed
- Automation tooling treats the lab as a separate context

## References

- VLAN allocation: [ADR-0101 – VLAN Allocation Strategy](./ADR-0101-vlan-allocation-strategy.md)
- Routing design: [ADR-0102 – Proxmox as Intra-Site Core Router](./ADR-0102-proxmox-intra-site-core-router.md)
- Inter-VLAN firewall: [ADR-0103 – Inter-VLAN Firewall Policy](./ADR-0103-inter-vlan-firewall-policy.md)
- Network architecture overview: [Network Architecture](../prerequisites/network-architecture.md)

---

**Maintainer:** HybridOps.Studio
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
