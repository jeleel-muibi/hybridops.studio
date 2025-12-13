# Network SDN Stack (Proxmox)

This stack wires **HybridOps.Studio** into the external Terraform module  
[`terraform-proxmox-sdn`](https://github.com/hybridops-studio/terraform-proxmox-sdn) to manage:

- SDN zone `hybzone` on `vmbr0`.
- VLAN-backed VNets for each environment (management, observability, dev, staging, prod, lab).
- Subnets with gateway IPs on VNet bridges.
- DHCP pools (`.100–.200`) via `dnsmasq` on the Proxmox host.

It implements the SDN portion of the HybridOps network design described in:

- [Network Architecture](https://docs.hybridops.studio/prerequisites/network-architecture/)
- [ADR-0101 – VLAN Allocation Strategy](https://docs.hybridops.studio/adr/ADR-0101-vlan-allocation-strategy/)
- [ADR-0102 – Proxmox as Core Router](https://docs.hybridops.studio/adr/ADR-0102-proxmox-intra-site-core-router/)
- [ADR-0104 – Static IP Allocation (Terraform IPAM)](https://docs.hybridops.studio/adr/ADR-0104-static-ip-allocation-terraform-ipam/)
- [How-to: Proxmox SDN with Terraform](https://docs.hybridops.studio/howtos/network/proxmox-sdn-terraform/)

---

## Network layout

| VLAN | VNet     | Subnet       | Gateway   | DHCP pool               | Purpose       |
|------|----------|--------------|-----------|-------------------------|---------------|
| 10   | vnetmgmt | 10.10.0.0/24 | 10.10.0.1 | 10.10.0.100–10.10.0.200 | Management    |
| 11   | vnetobs  | 10.11.0.0/24 | 10.11.0.1 | 10.11.0.100–10.11.0.200 | Observability |
| 20   | vnetdev  | 10.20.0.0/24 | 10.20.0.1 | 10.20.0.100–10.20.0.200 | Development   |
| 30   | vnetstag | 10.30.0.0/24 | 10.30.0.1 | 10.30.0.100–10.30.0.200 | Staging       |
| 40   | vnetprod | 10.40.0.0/24 | 10.40.0.1 | 10.40.0.100–10.40.0.200 | Production    |
| 50   | vnetlab  | 10.50.0.0/24 | 10.50.0.1 | 10.50.0.100–10.50.0.200 | Lab/Testing   |

Per `/24` subnet:

- `.1` – gateway (VNet bridge).
- `.2–.9` – infrastructure services.
- `.10–.99` – static IPs (NetBox IPAM).
- `.100–.200` – DHCP pool.
- `.201–.254` – reserved.

Design bands:

- `10–19` – management plane.
- `20–29` – development.
- `30–39` – staging.
- `40–49` – production.
- `50–59` – lab/testing.

---

## Stack responsibilities

**Managed by this stack**

- SDN zone `hybzone` on `vmbr0`.
- VNets and subnets in Proxmox SDN.
- DHCP configuration via `dnsmasq` on the Proxmox node.
- Gateway IP assignment on VNet bridges.

**Not managed here**

- Proxmox installation or base `vmbr0` setup.
- Inter-VLAN firewall rules (handled elsewhere via Ansible / firewall ADRs).
- VM creation and static IP assignments (other Terraform stacks + NetBox IPAM).
- NetBox population and IP allocations.

For operational procedures and troubleshooting, see:

- [`sdn_operations.md`](./sdn_operations.md)

---

## Dependencies

- Proxmox VE 8.x with SDN enabled.
- `vmbr0` configured as VLAN-aware bridge.
- Terraform 1.5+ and Terragrunt installed on the control node.
- Proxmox API token with SDN and DNS/DHCP permissions.
- SSH access to the Proxmox node as `root` (for `dnsmasq` automation).

Typical environment variables (exported before running Terragrunt):

```bash
export PROXMOX_URL="https://<PROXMOX_HOST>:8006/api2/json"
export PROXMOX_TOKEN_ID="automation@pam!infra-sdn"
export PROXMOX_TOKEN_SECRET="<SECRET>"
export PROXMOX_NODE="hybridhub"
export PROXMOX_SKIP_TLS_VERIFY="true"
```

The root Terragrunt config (`platform/infra/terraform/live-v1/root.hcl`) derives:

- `proxmox_host` from `PROXMOX_URL`.
- Common tags and environment metadata.
- Backend configuration for state.

---

## Usage

From the monorepo root:

```bash
cd infra/terraform/live-v1/onprem/proxmox/core/00-foundation/network-sdn

# Review planned changes
terragrunt plan

# Deploy or update SDN configuration
terragrunt apply

# View outputs
terragrunt output

# Destroy SDN config (lab/testing only)
terragrunt destroy
```

> **Warning:** `destroy` removes SDN VNets and DHCP configuration.  
> Only use for lab tear-down or controlled rebuilds; ensure no critical workloads depend on these networks.

---

## Module wiring

This stack uses the external module:

```hcl
terraform {
  source = "github.com/hybridops-studio/terraform-proxmox-sdn//."
}
```

Version pinning is done in `root.hcl`, for example by appending `?ref=v0.1.1` to the source when you cut a tagged release.

Inputs are passed via `inputs` in `root.hcl`, for example:

```hcl
inputs = {
  zone_name    = "hybzone"
  proxmox_node = local.proxmox_node
  proxmox_host = local.proxmox_host

  vnets = {
    vnetmgmt = {
      vlan_id     = 10
      description = "Management Network"
      subnets = {
        mgmt = {
          cidr             = "10.10.0.0/24"
          gateway          = "10.10.0.1"
          vnet             = "vnetmgmt"
          dhcp_enabled     = true
          dhcp_range_start = "10.10.0.100"
          dhcp_range_end   = "10.10.0.200"
          dhcp_dns_server  = "8.8.8.8"
        }
      }
    }
    # ...other VNets...
  }
}
```

For full module inputs and outputs, see the module-specific [`README`](https://github.com/hybridops-studio/terraform-proxmox-sdn/blob/main/README.md).

---

## Known issues

For detailed behaviour and workarounds, see:

- [`sdn_operations.md`](./sdn_operations.md) – operations and troubleshooting.
- Module-level caveats documented in `KNOWN-ISSUES-terraform-proxmox-sdn.md` in the module repository.

Key points:

- After `destroy`, VNet bridge interfaces can persist in the kernel until networking is reloaded.
- Proxmox SDN in 8.x does not always remove kernel interfaces when SDN objects are deleted via API.
- For production, prefer iterative `apply` over full destroy/recreate workflows.

---

For SDN ID constraints and DHCP design details, see the
**Design notes & Proxmox SDN constraints** section in the
[`terraform-proxmox-sdn` README](https://github.com/hybridops-studio/terraform-proxmox-sdn/blob/main/README.md).

---

### Downstream usage (NetBox IPAM and VM stacks)

This stack is the upstream producer for SDN network metadata. Other stacks consume its outputs rather than redefining networks by hand.

Typical downstream consumers:

- **NetBox IPAM population** – uses the `subnets` output from `terraform-proxmox-sdn` to create prefixes, gateways, and (optionally) DHCP ranges in NetBox.
- **VM / cluster stacks** – use the `vnets` and `subnets` outputs to attach NICs to the correct VNets and to select the right subnet CIDRs and gateways.

Conceptual example (separate stack):

```hcl
module "proxmox_sdn" {
  source = "git::https://github.com/hybridops-studio/terraform-proxmox-sdn.git//."
  # ... SDN inputs ...
}

module "netbox_ipam" {
  source = "../netbox/ipam"

  # Consume SDN outputs rather than duplicating CIDRs and gateways
  subnets = module.proxmox_sdn.subnets
}

module "vm_platform" {
  source = "../proxmox/vm-platform"

  vnets   = module.proxmox_sdn.vnets
  subnets = module.proxmox_sdn.subnets
}
```

This keeps SDN configuration (Proxmox), IPAM (NetBox), and VM wiring aligned to the same CIDRs, gateways, and VLAN tags.

---

## Key files (monorepo)

```text
platform/infra/terraform/live-v1/onprem/proxmox/core/00-foundation/network-sdn/
├── README.md          # Stack overview (this file)
├── sdn_operations.md  # Operations, validation, troubleshooting
└── terragrunt.hcl     # Stack configuration (wires into terraform-proxmox-sdn)
```

External module:

- [`terraform-proxmox-sdn`](https://github.com/hybridops-studio/terraform-proxmox-sdn) – reusable Terraform SDN module backing this stack.
- Published on the Terraform Registry as `hybridops-studio/proxmox-sdn/proxmox` for direct reuse in other projects.
