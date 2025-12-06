---
id: ADR-0103
title: "Inter-VLAN Firewall Policy"
status: Accepted
date: 2025-11-30

category: "01-networking"
supersedes: []
superseded_by: []

links:
  prs: []
  runbooks: []
  howtos: []
  evidence: []
  diagrams: []

draft: false
tags: ["firewall", "security", "iptables", "vlan"]
access: public
---

# Inter-VLAN Firewall Policy

**Status:** Accepted — Enforces a default-deny inter-VLAN firewall on Proxmox, only allowing explicit management and observability flows to preserve strong environment isolation.

## Context

VLAN-based segmentation is defined in ADR-0101. Proxmox provides Layer 3 routing between those VLANs as described in ADR-0102. Without an explicit firewall policy, all VLANs would be able to communicate freely, which would weaken environment isolation and increase the blast radius of any compromise.

The firewall design must:

- Enforce isolation between development, staging, production, and lab networks.
- Preserve management access patterns required for automation and maintenance.
- Allow the observability stack to collect metrics across environments.
- Remain simple enough to operate and audit in a homelab-scale environment.

## Decision

Implement an inter-VLAN firewall policy based on iptables with:

- Default **DROP** policy for the `FORWARD` chain.
- Explicit **ALLOW** rules for required traffic flows.
- Centralised enforcement on the Proxmox host, which already performs Layer 3 routing.

### Policy Matrix

| Source VLAN | Destination VLAN | Policy | Notes |
|-------------|------------------|--------|-------|
| 10 (Management) | All | ALLOW | Operational access to all environments |
| 11 (Observability) | 20, 30, 40 | ALLOW (9090-9100, 3000) | Metrics scraping and dashboards |
| 20 (Dev) | 30, 40 | DENY | Dev cannot access staging or production |
| 20 (Dev) | Internet | ALLOW | Package downloads and external APIs |
| 30 (Staging) | 40 | ALLOW (read-only ports) | Data refresh and limited validation against prod |
| 30 (Staging) | 20 | DENY | Staging cannot access dev |
| 40 (Prod) | 20, 30, 50 | DENY | Production isolated from non-prod and lab |
| 40 (Prod) | Internet | ALLOW (restricted egress) | Access to selected external APIs |
| 50 (Lab) | All | DENY | Lab isolated from all environments |
| All | 10 (Management) | ALLOW (22, 443) | Access to management plane |

### Baseline Rules (Conceptual

The following represents the intended posture; exact implementation is handled via Ansible and iptables-persistent.

```bash
# Default deny for inter-VLAN forwarding
iptables -P FORWARD DROP

# Allow established/related traffic
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Management VLAN (10) can reach all VLANs
iptables -A FORWARD -s 10.10.0.0/24 -j ACCEPT

# Observability VLAN (11) scraping VLANs 20/30/40
iptables -A FORWARD -s 10.11.0.0/24 -d 10.20.0.0/24 -p tcp -m multiport --dports 9090:9100,3000 -j ACCEPT
iptables -A FORWARD -s 10.11.0.0/24 -d 10.30.0.0/24 -p tcp -m multiport --dports 9090:9100,3000 -j ACCEPT
iptables -A FORWARD -s 10.11.0.0/24 -d 10.40.0.0/24 -p tcp -m multiport --dports 9090:9100,3000 -j ACCEPT

# All environments can reach management services (SSH/HTTPS)
iptables -A FORWARD -d 10.10.0.0/24 -p tcp -m multiport --dports 22,443 -j ACCEPT

# Lab isolation (VLAN 50)
iptables -A FORWARD -s 10.50.0.0/24 -j DROP
iptables -A FORWARD -d 10.50.0.0/24 -j DROP

# Production isolation
iptables -A FORWARD -s 10.40.0.0/24 -d 10.20.0.0/24 -j DROP
iptables -A FORWARD -s 10.40.0.0/24 -d 10.30.0.0/24 -j DROP
iptables -A FORWARD -s 10.40.0.0/24 -d 10.50.0.0/24 -j DROP

# Dev isolation from staging/prod
iptables -A FORWARD -s 10.20.0.0/24 -d 10.30.0.0/24 -j DROP
iptables -A FORWARD -s 10.20.0.0/24 -d 10.40.0.0/24 -j DROP
```

## Rationale

- **Default deny posture** ensures that any new traffic flow must be explicitly authorised.
- **Management plane exception** enables automation and remote operations without undermining isolation between dev/staging/prod.
- **Observability exception** allows Prometheus and related components to scrape all environments from VLAN 11 without granting general-purpose access.
- **Production isolation** prevents workloads in production from initiating connections into non-production or lab networks.
- **Lab isolation** ensures experiments, misconfigurations and chaos tests in VLAN 50 cannot affect operational environments.

## Consequences

### Positive

- Clear security boundaries between environments.
- Production workloads are isolated from dev/staging and lab experiments.
- Observability and management remain functional across all VLANs.
- Policy is auditable at a single enforcement point (Proxmox host).

### Negative

- iptables rule management requires discipline and version control.
- Rule ordering matters; mistakes can unintentionally widen or narrow access.
- Inter-VLAN troubleshooting must account for firewall behaviour.

### Neutral

- Rules are applied at the host routing layer rather than per-VM.
- Logging via iptables `LOG` target can be added as needed for investigation.
- The policy can be automated using Ansible roles (for example, `proxmox-firewall`).

## Alternatives Considered

- **Proxmox VM Firewall only**  
  Rejected. Proxmox firewall is primarily VM-focused and not ideal for enforcing inter-VLAN routing policy at the host level.

- **No firewall (rely on VLAN segmentation only)**  
  Rejected. Routing without firewall enforcement would allow unrestricted traffic between VLANs, which conflicts with the isolation objectives.

- **Per-VM host firewalls**  
  Rejected. Does not scale and complicates policy audits. Environment-level boundaries are better expressed at the routing/firewall layer.

- **nftables instead of iptables**  
  Deferred. iptables is sufficient for current requirements and has wide tooling support. Migration to nftables remains an option for future phases.

## Implementation

- Proxmox host applies rules via iptables and iptables-persistent.
- Ansible role (for example, `proxmox-firewall`) manages the rule-set.
- Rules are stored in version control alongside infrastructure code.

Validation includes:

- Dev VM cannot reach production or staging subnets.
- Management hosts can reach all VLANs as expected.
- Observability components can scrape metrics from dev/staging/prod.
- Lab VMs in VLAN 50 cannot initiate or receive inter-VLAN traffic.

## References

- VLAN allocation: [ADR-0101 VLAN Allocation Strategy](./ADR-0101-vlan-allocation-strategy.md)
- Routing design: [ADR-0102 Proxmox as Layer 3 Router](./ADR-0102-proxmox-intra-site-core-router.md)
- Network architecture overview: [Network Architecture](../prerequisites/network-architecture.md)

---

**Maintainer:** HybridOps.Studio
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
