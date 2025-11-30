---
id: ADR-0016
title: "Adopt Packer + Cloud-Init for VM Template Standardization"
status: Accepted
date: 2025-01-09
domains: ["platform", "virtualization"]
owners: ["jeleel-muibi"]
links:
  runbooks: ["../../runbooks/platform/packer-proxmox-template-build.md"]
  howtos: ["../../howtos/HOWTO_packer_proxmox_template.md"]
  evidence: ["../proof/platform/packer-builds/"]
  related_docs:
    - "./ADR-0015-network-infrastructure-assumptions.md"
    - "../prerequisites/NETWORK_INFRASTRUCTURE.md"
---

# ADR-0016 — Adopt Packer + Cloud-Init for VM Template Standardization

## Status
**Accepted** — Packer is the standard for building immutable VM templates on Proxmox; cloud-init is the default initialization system.

## Context
Manual template builds via Proxmox UI cause configuration drift, lack auditability, and scale poorly. We require repeatable golden images that integrate with Terraform (provisioning) and Ansible (configuration management).

## Decision
Use **HashiCorp Packer** (Proxmox ISO builder) to produce **cloud-init-ready** templates for:
- **Linux:** Ubuntu 22.04/24.04 LTS, Rocky Linux 9/10
- **Windows:** Server 2022/2025, Windows 11 Enterprise (via Cloudbase-Init)

Templates are version-controlled in Git and rebuilt on a monthly cadence or when CVEs require patches.

**Prerequisite:** Enterprise network infrastructure per [ADR-0015](./ADR-0015-network-infrastructure-assumptions.md) (DHCP on management network, DNS, outbound access).

## Principles
1. **Immutable images** — Rebuild for changes; no in-place modifications
2. **Declarative** — HCL configuration in Git with review trails
3. **Separation of concerns** — Packer builds → Terraform provisions → Ansible configures
4. **Cloud-init first** — Environment specifics applied at clone time
5. **VMID auto-increment** — Conflicts resolved automatically during builds

## Scope
**In-scope:**
- Full VMs requiring bootable OS images (control nodes, RKE2 nodes, Linux/Windows servers)
- Automated builds with evidence generation
- Chain ID tracking for audit correlation

**Out-of-scope:**
- LXC containers (see ADR-0017)
- Application-layer configuration
- Runtime network design (VLANs, SDN)
- Docker/OCI images

## Consequences

### Positive
- Repeatable, auditable builds with <5% drift rate
- 80% reduction in template build time vs manual UI
- Consistent hardening baselines across all images
- Full audit trail via chain IDs and evidence artifacts

### Negative
- Team must learn Packer HCL and plugin specifics
- Build pipeline adds <10 minutes per template
- Requires template storage management and retention policies

## Implementation Notes

- Packer HCL lives in `infra/packer-multi-os/`
- Provisioning toolkit (init, wrapper, evidence, unattended rendering) lives in `control/tools/provision/packer/` (`bin/` and `remote/`)
- Proxmox API environment is written to `infra/env/.env.proxmox` via `control/tools/provision/init/init-proxmox-env.sh`
- Evidence and logs are written under:
  - `output/logs/packer/…`
  - `docs/proof/platform/packer-builds/…`
- Chain IDs from `chain-lib.sh` are used to correlate init logs, build logs and proof artifacts


## Metrics & Review Triggers
- **Success rate:** ≥95%
- **Build time:** <10min per template
- **Cloud-init success:** ≥99%
- **Review triggers:** Proxmox major upgrades, plugin API changes, failure rate >10%

## Alternatives Considered

| Option | Rejected Because |
|--------|------------------|
| Manual UI builds | Configuration drift, no audit trail, slow |
| Ansible-only provisioning | Not immutable, slower, blurs layer separation |
| Terraform-only OS installs | Not designed for OS installation phase |
| Cloud-init without golden images | Slow per-VM provisioning, inconsistent baselines |
| LXC-only architecture | Insufficient isolation for security/kernel requirements |

## References
- **Prerequisite:** [ADR-0015 — Network Infrastructure Assumptions](./ADR-0015-network-infrastructure-assumptions.md)
- **Operations:** [Runbook — Proxmox VM Template Build](../runbooks/platform/packer-proxmox-template-build.md)
- **Learning:** [HOWTO — Build Your First Packer Template](../howtos/HOWTO_packer_proxmox_template.md)
- **Toolkit:** [Packer Provisioning Toolkit README](../../control/tools/provision/packer/README.md)
- **Evidence:** [Proof Artifacts](../proof/platform/packer-builds/)

**External:**
- [HashiCorp Packer Documentation](https://developer.hashicorp.com/packer)
- [Packer Proxmox Plugin](https://github.com/hashicorp/packer-plugin-proxmox)
- [Proxmox VE API](https://pve.proxmox.com/pve-docs/api-viewer/)
- [cloud-init Documentation](https://cloudinit.readthedocs.io/)

---

**Last Updated:** 2025-11-17 20:24 UTC
