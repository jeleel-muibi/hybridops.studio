# HybridOps.Studio – Terraform & Terragrunt Infrastructure

Production-style infrastructure as code for HybridOps.Studio, built around:

- **Terraform + Terragrunt** for declarative infrastructure.
- **Proxmox VE** as on-prem core and SDN anchor.
- **NetBox IPAM** for static addressing.
- A roadmap towards **Kubernetes**, **observability**, and **GitOps**.

All changes are version-controlled, repeatable, and backed by Architecture Decision Records (ADRs).

---

## Scope

This Terraform/Terragruntt layer manages:

- On-prem Proxmox resources (SDN, networks, and later compute/storage).
- Environment-scoped stacks (e.g. `live-v1`) for dev/staging/prod parity.
- Integration points for Kubernetes, observability, and GitOps workflows.

Configuration management (Ansible) and application workloads (Kubernetes manifests/Helm) live in their own trees but are designed to consume outputs from this layer.

---

## Repository Layout (Terraform/Terragruntt)

```text
infra/
└── terraform/
    ├── modules/                # Reusable Terraform modules
    │   └── proxmox/
    │       └── sdn/            # Proxmox SDN (zone, vnets, subnets, DHCP)
    └── live-v1/                # Live environment configuration (v1 baseline)
        └── onprem/
            └── proxmox/
                └── core/
                    └── 00-foundation/
                        └── network-sdn/   # SDN + DHCP foundation stack
```

Related high-level documentation:

- [Network Architecture](https://docs.hybridops.studio/prerequisites/network-architecture/)
- [Network SDN Stack – README](./live-v1/onprem/proxmox/core/00-foundation/network-sdn/README.md)
- [Network SDN Operations](./live-v1/onprem/proxmox/core/00-foundation/network-sdn/sdn_operations.md)

---

## Quick Start

### Prerequisites

- Proxmox VE 8.x with:
  - `vmbr0` configured as a VLAN-aware bridge.
  - SDN enabled.
- Terraform **1.5+**
- Terragrunt **0.45+**
- A Proxmox API token with appropriate permissions.
- NetBox instance available for IPAM (optional for first SDN tests).

### Deploy Network Foundation (SDN)

From the repository root:

```bash
cd infra/terraform/live-v1/onprem/proxmox/core/00-foundation/network-sdn

# Review planned changes
terragrunt plan

# Apply SDN and DHCP configuration
terragrunt apply
```

For operational details and troubleshooting, see the stack README:

- [Network SDN Stack – README](./live-v1/onprem/proxmox/core/00-foundation/network-sdn/README.md)

---

## Infrastructure Stacks (Roadmap)

| Stack         | Status         | Description                                     | Documentation                                                             |
|--------------|----------------|-------------------------------------------------|---------------------------------------------------------------------------|
| Network SDN  | Production   | Proxmox SDN with VLANs, VNets, and DHCP        | `live-v1/onprem/proxmox/core/00-foundation/network-sdn/README.md`        |
| Storage      | In progress  | Ceph/ZFS storage pools for VM and container disks | _Planned – Terraform module + stack to be added_                          |
| Compute VMs  | Planned      | VM templates, golden images, and provisioning  | _Planned – will consume Packer/NetBox outputs_                           |
| Kubernetes   | Planned      | Multi-cluster K8s (dev/staging/prod) on Proxmox| _Planned – integrates with SDN + storage stacks_                         |
| Observability| Planned      | Prometheus, Grafana, Loki                      | _Planned – ties into dedicated observability VLAN_                       |

---

## Key Features

### Production-Ready Automation

- **Declarative**: Infrastructure state expressed in HCL, not ad-hoc shell scripts.
- **Idempotent**: Safe to re-run applies; no manual “snowflake” configuration.
- **Environment-aware**: `live-v1` layout supports clear environment separation.
- **Documented workarounds**: Known Proxmox SDN issues and mitigations captured in stack READMEs.

### Network Architecture

- **VLAN segmentation** for management, observability, dev, staging, prod, and lab.
- **Automated DHCP**: `dnsmasq` configuration generated from SDN outputs.
- **Static IP management**: Static services allocated via **NetBox IPAM**, not hard-coded.
- **Inter-VLAN routing**: Proxmox acts as the intra-site core router.

For the full narrative view of the network, see:

- [Network Architecture](../../docs/prerequisites/network-architecture.md)

---

## Design Philosophy

- **ADR-driven**: Every significant decision has a corresponding ADR.
- **Security by default**: Network segmentation, least privilege, and default-deny routing policies.
- **Observable by design**: Observability has its own VLAN and planned dedicated stack.
- **Developer-friendly**: Clear stack boundaries, consistent naming, and readable Terragrunt layout.

---

## Architecture Decision Records

Key network and Terraform-related ADRs include:

- [ADR-0101 – VLAN Allocation Strategy](https://docs.hybridops.studio/adr/ADR-0101-vlan-allocation-strategy/)
- [ADR-0102 – Proxmox as Intra-Site Core Router](https://docs.hybridops.studio/adr/ADR-0102-proxmox-intra-site-core-router/)
- [ADR-0103 – Inter-VLAN Firewall Policy](https://docs.hybridops.studio/adr/ADR-0103-inter-vlan-firewall-policy/)
- [ADR-0104 – Static IP Allocation with NetBox IPAM](https://docs.hybridops.studio/adr/ADR-0104-static-ip-allocation-netbox-ipam/)

The full ADR catalog is published on:

- [docs.hybridops.studio – ADR index](https://docs.hybridops.studio/adr/)

---

## Documentation

Recommended reading order:

1. [Network Architecture](https://docs.hybridops.studio/prerequisites/network-architecture/) – high-level topology and VLAN/IP strategy.
2. `infra/terraform/live-v1/onprem/proxmox/core/00-foundation/network-sdn/README.md` – SDN stack specifics.
3. `infra/terraform/live-v1/onprem/proxmox/core/00-foundation/network-sdn/sdn_operations.md` – operations and troubleshooting.

Additional docs (planned):

- Getting started guide for new environments.
- Troubleshooting guide for common Terraform/Terragruntt and Proxmox SDN issues.

---

## Contributing

Contributions are welcome. Before opening a PR:

- Review existing ADRs to understand current design constraints.
- Follow the existing module + live stack layout (`modules/` vs `live-v1/`).
- Document any non-trivial change with:
  - An ADR (for design decisions).
  - Updates to relevant READMEs/runbooks.
- Test changes in a **lab environment** before applying to production-like stacks.

---

## License

Code is licensed under **MIT-0 (MIT No Attribution)** unless otherwise stated.

---

Maintainer: **HybridOps.Studio**
