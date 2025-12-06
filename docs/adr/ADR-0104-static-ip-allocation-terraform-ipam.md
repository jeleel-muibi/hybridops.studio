---
id: ADR-0104
title: "Static IP Allocation with Terraform IPAM"
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
tags: ["ipam", "terraform", "static-ip", "cloud-init"]
access: public
---

# Static IP Allocation with Terraform IPAM

**Status:** Accepted — Uses a Terraform IPAM module as the single source of truth for static per-VLAN IPs, feeding deterministic addresses into cloud-init.

## Context

Segmented VLANs (ADR-0101) require deterministic IP addressing for:

- Kubernetes control plane and worker nodes.
- Observability components (Prometheus, Grafana, Loki).
- Management and automation hosts (Ansible, Terraform).
- Future services such as NetBox and internal DNS.

Initial experiments attempted to rely on DHCP within Proxmox SDN. This introduced complexity, required additional services, and did not integrate cleanly with infrastructure-as-code workflows.

The IP allocation approach must:

- Avoid address conflicts across VLANs.
- Be repeatable and auditable.
- Integrate with Terraform and cloud-init.
- Remain simple for homelab scale while resembling enterprise practice.

## Decision

Implement a Terraform-based IPAM module dedicated to static IPv4 allocation across defined VLANs. The module:

- Owns IP allocation ranges per VLAN.
- Accepts a map of logical hostnames and offsets.
- Generates per-host IP addresses and gateway mappings as outputs.
- Feeds those outputs into VM modules and cloud-init configuration.

### Allocation Ranges

Per VLAN, the addressing pattern is:

| VLAN | Subnet | Gateway | Usable Pool | Reserved |
|------|--------|---------|------------|----------|
| 10 | 10.10.0.0/24 | 10.10.0.1 | 10.10.0.10–10.10.0.250 | .2–.9 for infra |
| 11 | 10.11.0.0/24 | 10.11.0.1 | 10.11.0.10–10.11.0.250 | .2–.9 for infra |
| 20 | 10.20.0.0/24 | 10.20.0.1 | 10.20.0.10–10.20.0.250 | .2–.9 for infra |
| 30 | 10.30.0.0/24 | 10.30.0.1 | 10.30.0.10–10.30.0.250 | .2–.9 for infra |
| 40 | 10.40.0.0/24 | 10.40.0.1 | 10.40.0.10–10.40.0.250 | .2–.9 for infra |
| 50 | 10.50.0.0/24 | 10.50.0.1 | 10.50.0.10–10.50.0.250 | .2–.9 for infra |

Offsets are applied within each pool (for example, offset 10 → `.10`).

### Module Pattern (Conceptual)

```hcl
module "ipam" {
  source = "../../modules/proxmox/ipam"

  allocations = {
    k3s-dev-cp-01 = { vlan = 20, offset = 10 } # 10.20.0.10
    k3s-dev-cp-02 = { vlan = 20, offset = 11 } # 10.20.0.11
    k3s-dev-cp-03 = { vlan = 20, offset = 12 } # 10.20.0.12
  }
}

module "vm" {
  source = "../../modules/proxmox/vm"

  vms = {
    k3s-dev-cp-01 = {
      ipv4_address = module.ipam.ipv4_addresses["k3s-dev-cp-01"]
      ipv4_gateway = module.ipam.gateways[20]
    }
  }
}
```

The IPAM module holds only addressing logic. VM modules consume the outputs and render concrete configuration via cloud-init or provider-specific network blocks.

## Rationale

- **Static IPs over DHCP**  
  No DHCP infrastructure is required. Critical infrastructure nodes benefit from deterministic addressing which simplifies inventory, troubleshooting, and documentation.

- **Terraform as system of record**  
  Terraform state provides a single source of truth for allocations. Conflicts are detected during planning rather than at runtime.

- **Module encapsulation**  
  Addressing rules and ranges are encapsulated in the IPAM module, avoiding repeated CIDR arithmetic across VM definitions.

- **Future extensibility**  
  The pattern can be extended later to support IPv6, external IPAM tools, or dynamic generation of DNS records.

## Consequences

### Positive

- Conflict-free static addressing enforced by Terraform.
- Clear mapping from hostname to IP and VLAN in code and state.
- Cloud-init receives consistent IP/gateway configuration at provisioning time.
- Integration point for future NetBox-based IPAM if required.

### Negative

- IP changes for existing hosts generally require Terraform apply and can trigger VM recreation or reconfiguration.
- Offsets per VLAN must be managed carefully to remain meaningful over time.
- Terraform state becomes critical evidence of address assignments and must be preserved.

### Neutral

- External IPAM (NetBox/phpIPAM) can be integrated later via data sources without redesigning consumers.
- DNS management can evolve separately, using the IPAM outputs as an upstream source.

## Alternatives Considered

- **DHCP per VLAN**  
  Rejected. Introduces additional services and state (leases) that are not easily captured in Terraform. Requires DHCP configuration management and adds failure modes.

- **Manual IP assignment per VM**  
  Rejected. Does not scale, is error-prone, and splits truth between code, documentation, and reality.

- **NetBox-backed IPAM**  
  Deferred. Valuable at larger scale but would add a database and application dependency for the homelab phase. The Terraform IPAM module keeps the design lightweight while remaining compatible with future NetBox adoption.

## Implementation

- Address ranges and reservations implemented in `infra/terraform/modules/proxmox/ipam`.
- VM modules consume `ipv4_addresses` and `gateways` outputs.
- Cloud-init templates use the IPAM outputs to render static network configuration.

Validation includes:

- `terraform plan` shows stable IP assignments for known hosts.
- No duplicate allocations exist per VLAN.
- VMs are reachable at the documented addresses and have correct gateways.

## References

- VLAN allocation: [ADR-0101 VLAN Allocation Strategy](./ADR-0101-vlan-allocation-strategy.md)
- Routing design: [ADR-0102 Proxmox as Layer 3 Router](./ADR-0102-proxmox-intra-site-core-router.md)
- Inter-VLAN firewall: [ADR-0103 Inter-VLAN Firewall Policy](./ADR-0103-inter-vlan-firewall-policy.md)
- Network architecture overview: [Network Architecture](../prerequisites/network-architecture.md)

---

**Maintainer:** HybridOps.Studio
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
