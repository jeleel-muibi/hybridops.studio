---
id: ADR-0015
title: "Assume Pre-Existing Network Infrastructure for Packer Builds"
status: Accepted
date: 2025-11-08
domains: ["platform", "networking"]
owners: ["jeleel-muibi"]
supersedes: []
superseded_by: []
links:
  prs: []
  runbooks: ["../runbooks/platform/packer-proxmox-template-build.md"]
  evidence: []
  diagrams: []
  related_docs: ["../prerequisites/NETWORK_INFRASTRUCTURE.md", "./ADR-0016-packer-cloudinit-vm-templates.md"]
---

# ADR-0015 — Network Infrastructure Assumptions for Packer Builds

## Status
Accepted — implemented in Packer workflows; aligns with enterprise operational patterns.

## Context
Packer builds VM templates by booting installation media and running unattended installers (Ubuntu autoinstall, Kickstart, Autounattend). During a build, temporary VMs must have basic network connectivity to:

- Fetch autoinstall `user-data`/`meta-data` (NoCloud over HTTP)
- Download OS packages and security updates (apt/dnf)
- Install and enable QEMU Guest Agent

**Decision to make:** Should the Packer toolchain set up its own ephemeral DHCP/HTTP on the Proxmox host (e.g., via dnsmasq), or should it assume enterprise-standard networking already exists?

**Prior work:**
- Early prototypes included ad-hoc dnsmasq scripts (`builder-network-*.sh`) to provide temporary DHCP
- This approach was evaluated against industry patterns (AWS, Azure, VMware)

## Decision
The platform **assumes pre-existing enterprise network infrastructure**:

- A **management network** (e.g., VLAN) with **DHCP enabled** for build-time addressing
- **DNS** resolution and outbound **Internet access** (or corporate mirrors)
- Proxmox attaches build VMs to a **bridge** (e.g., `vmbr0`) connected to that network

Packer **does not** provision ad-hoc DHCP or alter host networking as part of the build.

### Key Components
- **Network Team Responsibility:** Physical/virtual switches, VLANs, routing, DHCP/DNS
- **Platform Team Responsibility:** VM templates, provisioning orchestration
- **Packer Bridge Configuration:** Defaults to first available `vmbr*` without VLAN tagging during build
- **Fallback Option:** Static IP configuration in cloud-init `user-data` (documented for no-DHCP environments)

## Decision Drivers
1. **Separation of Concerns**
   - Network infrastructure is stable, long-lived
   - Packer builds are ephemeral, repeatable
   - Mixing concerns increases fragility and complicates ownership

2. **Operational Safety**
   - Mutating host networking (dnsmasq on hypervisor) introduces risk
   - Cleanup failures can leave stray DHCP services
   - Blast radius reduced by keeping networking separate

3. **Repeatability & Scale**
   - Configure DHCP/DNS **once** (Phase 0)
   - Run Packer **many times** (Phase 1-N) without changing network state
   - Works across dev/staging/prod by pointing at different bridges/subnets

4. **Industry Pattern Alignment**
   - AWS: Assumes VPC/subnets exist before EC2 instances
   - Azure: Assumes VNets exist before VMs
   - VMware: Assumes distributed virtual switches exist
   - **Proxmox should be treated no differently**

## Consequences

### Positive
- ✅ Clear team boundaries; simpler failure domains
- ✅ Maintainable, auditable, and consistent builds
- ✅ Easier to scale to multiple Proxmox nodes/clusters
- ✅ No host state mutation (aligns with immutable infrastructure principles)
- ✅ Works with existing corporate network policies

### Negative
- ⚠️ Requires coordination with network team to ensure DHCP on build network
- ⚠️ Packer cannot run on completely isolated hardware without manual DHCP setup
- ⚠️ Adds prerequisite validation step before first Packer run

### Neutral
- In rare no-DHCP environments, a **static-IP autoinstall** fallback is documented and supported
- Manual DHCP configuration is a one-time setup per environment

## Alternatives Considered

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| **Assume corporate DHCP** | Industry-standard, simple, maintainable, scalable | Requires cross-team coordination | ✅ **Accepted** |
| Ephemeral dnsmasq on host | Works on totally isolated hardware | Host state mutation, cleanup risk, non-standard, fragile | ❌ **Rejected** |
| Static IPs only | No DHCP dependency | Manual IP management; doesn't scale well | ❌ **Rejected** (documented as fallback only) |
| Cloud-init DHCP retry | Tolerates transient DHCP outages | Builds fail if DHCP persistently down | ⚠️ Already built-in to Ubuntu/Rocky installers |

## Implementation Notes

### Packer Configuration
- **Template location:** `infra/packer-multi-os/linux/`
- **Bridge detection:** `init-packer-remote.sh` auto-detects first `vmbr*` bridge
- **No VLAN tagging during build:** Maximizes DHCP reliability; VLANs applied post-template in Terraform
- **HTTP server:** Packer's built-in ephemeral HTTP serves `user-data`/`meta-data` (not a host service)

### Verification Steps
```bash
# Check bridge exists
ssh root@<proxmox-ip> 'ip link show vmbr0'

# Verify DHCP available (optional pre-flight)
# See docs/prerequisites/NETWORK_INFRASTRUCTURE.md for detailed tests
```

## References
- **Prerequisites:** [Network Infrastructure](../prerequisites/NETWORK_INFRASTRUCTURE.md)
- **Related ADR:** [ADR‑0016 — Packer + Cloud‑Init VM Templates](./ADR-0016-packer-cloudinit-vm-templates.md)
- **Runbook:** [Build Proxmox VM Templates with Packer](../runbooks/platform/packer-proxmox-template-build.md)
