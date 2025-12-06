---
id: ADR-0101
title: "VLAN Allocation Strategy"
status: Accepted
date: 2025-11-30
category: "01-networking"
supersedes: []
superseded_by: []
links:
  prs: []
  runbooks:
    - "../runbooks/networking/network-validation.md"
  howtos: []
  evidence: []
  diagrams:
    - "../diagrams/network-topology.md"
draft: false
tags: ["vlan", "network-segmentation", "proxmox"]
access: public
---

# VLAN Allocation Strategy

**Status:** Accepted — Defines a hierarchical VLAN scheme to isolate environments, management, observability, and lab traffic while leaving headroom for future expansion.

## Context

HybridOps.Studio requires network segmentation to:

- Isolate environments (development, staging, production)
- Separate management traffic from workload traffic
- Enable observability across all environments
- Support network testing without impacting operations
- Scale to additional environments without redesign

An initial flat network approach (single bridge, no VLANs) prevented proper isolation and made it difficult to apply environment-specific security policies.

## Decision

Implement VLAN-based segmentation with hierarchical numbering:

| VLAN | Subnet        | Purpose                      |
|------|--------------|------------------------------|
| 10   | 10.10.0.0/24 | Management (GUI, SSH, IaC)   |
| 11   | 10.11.0.0/24 | Observability (metrics, logs, dashboards) |
| 20   | 10.20.0.0/24 | Development                  |
| 30   | 10.30.0.0/24 | Staging                      |
| 40   | 10.40.0.0/24 | Production                   |
| 50   | 10.50.0.0/24 | Lab/Testing (EVE‑NG, experiments) |
| 60–99| Reserved     | Future expansion             |

Proxmox acts as a VLAN-aware bridge with Layer 3 routing (see [ADR‑0102 – Proxmox as Layer 3 Router](./ADR-0102-proxmox-intra-site-core-router.md)).

## Rationale

**Ranges vs sequential numbering**

- VLAN 10–19: Management plane (cross-environment services)
- VLAN 20–29: Development (room for dev-specific segments)
- VLAN 30–39: Staging (room for staging-specific segments)
- VLAN 40–49: Production (room for prod-specific segments)
- VLAN 50–59: Lab/Testing (isolated experiments)

**Why dedicated VLANs instead of a single shared network**

- Environment isolation can be enforced via firewall
- Blast radius of incidents is reduced
- Traffic patterns are easier to reason about and observe
- Network policies can evolve per environment without global impact

**Why a specific Lab VLAN**

- Lab traffic (EVE‑NG, simulations) is isolated from all operational workloads
- Experiments and chaos tests can be run without impacting production‑style services
- Aligns with the separation between testing and operations in real environments

## Consequences

### Positive

- Clear environment isolation with firewall enforcement (see [ADR‑0103 – Inter‑VLAN Firewall Policy](./ADR-0103-inter-vlan-firewall-policy.md))
- Management plane separation improves security posture
- Unified observability without compromising isolation (see [ADR‑0401 – Unified Observability with Prometheus](./ADR-0401-unified-observability-with-prometheus.md))
- Scales to additional environments without renumbering
- VLAN numbers are self-describing and easy to recall

### Negative

- Requires VLAN-aware switching if extended beyond a single Proxmox host
- More complex to reason about than flat networking
- Firewall rules must be maintained for inter‑VLAN communication

### Neutral

- Static IP allocation is required within each VLAN (see [ADR‑0104 – Static IP Allocation with Terraform IPAM](./ADR-0104-static-ip-allocation-terraform-ipam.md))
- DNS strategy must account for multiple subnets

## Alternatives Considered

**Flat networking (single bridge)**  
Rejected. No isolation between environments. Increases the risk of lateral movement and accidental cross‑environment access.

**By‑function VLANs (Windows/Linux/Management)**  
Rejected. Mixes development, staging, and production workloads within the same VLAN, which prevents environment-specific policy enforcement.

**Highly granular VLANs (service‑per‑VLAN)**  
Rejected for this phase. Excessive operational overhead for current scope. Reserved ranges allow for future refinement if justified.

## Implementation

- Network configuration on Proxmox: `/etc/network/interfaces`
- SDN and VLAN orchestration: `infra/terraform/modules/proxmox/sdn`
- IP allocation strategy: see [ADR‑0104 – Static IP Allocation with Terraform IPAM](./ADR-0104-static-ip-allocation-terraform-ipam.md)
- Network architecture overview: [Network Architecture](../prerequisites/network-architecture.md)

## References

- [ADR‑0102 – Proxmox as Layer 3 Router](./ADR-0102-proxmox-intra-site-core-router.md)
- [ADR‑0103 – Inter‑VLAN Firewall Policy](./ADR-0103-inter-vlan-firewall-policy.md)
- [ADR‑0104 – Static IP Allocation with Terraform IPAM](./ADR-0104-static-ip-allocation-terraform-ipam.md)
- [ADR‑0105 – Dual Uplink Design (Ethernet/WiFi Failover)](./ADR-0105-dual-uplink-ethernet-wifi-failover.md)
- [ADR‑0201 – EVE‑NG Network Lab Architecture](./ADR-0201-eve-ng-network-lab-architecture.md)
- [ADR‑0401 – Unified Observability with Prometheus](./ADR-0401-unified-observability-with-prometheus.md)

---

**Maintainer:** HybridOps.Studio
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
