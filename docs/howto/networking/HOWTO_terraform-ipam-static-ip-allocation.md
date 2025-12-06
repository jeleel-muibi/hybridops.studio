---
title: "Static IP Allocation with Terraform IPAM (Proxmox)"
category: "networking"
summary: "Use Terraform as a simple IPAM layer to allocate static IPs per VLAN for Proxmox VMs."
difficulty: "Intermediate"

topic: "terraform-ipam-proxmox"

video: ""
source: ""

draft: false
tags: ["terraform", "ipam", "proxmox", "static-ip", "cloud-init"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# HOWTO: Static IP Allocation with Terraform IPAM (Proxmox)

**Purpose:** Implement a lightweight, Terraform-based IPAM pattern that allocates static IPv4 addresses from predefined VLAN subnets and exposes them to the Proxmox VM module and cloud-init.  
**Difficulty:** Intermediate  
**Scope:** Single-site homelab with Proxmox as router and Terraform provisioning VMs.

---

## Demo / Walk-through

??? info "▶ Watch the demo"

    <iframe
      width="800"
      height="450"
      src="https://www.youtube.com/embed/YOUR_VIDEO_ID"
      title="HybridOps.Studio HOWTO Demo"
      frameborder="0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      allowfullscreen>
    </iframe>

    If the embed does not load, use the direct link:  
    [Open on YouTube](https://www.youtube.com/watch?v=YOUR_VIDEO_ID){ target=_blank rel="noopener" }

## 1. Prerequisites

- VLAN and subnet layout defined (ADR-0101).
- Proxmox VM module consuming per-VM network attributes (IPv4 address and gateway).
- Terraform 1.5+ and Terragrunt layout in `infra/terraform/live-v1`.
- One or more Proxmox VM templates already available for cloning.

---

## 2. Define IPAM Module Interface

Create a module skeleton at `infra/terraform/modules/proxmox/ipam`.

**`variables.tf`:**

```hcl
variable "allocations" {
  description = "Map of hostname to VLAN and offset"
  type = map(object({
    vlan   = number
    offset = number
  }))
}

variable "subnets" {
  description = "Map of VLAN ID to base subnet CIDR"
  type = map(object({
    cidr = string
  }))
}
```

**`main.tf`:**

```hcl
locals {
  # Expand CIDR and offsets into concrete IP addresses
  ipv4_map = {
    for name, cfg in var.allocations : name => {
      vlan      = cfg.vlan
      cidr      = var.subnets[cfg.vlan].cidr
      ip_offset = cfg.offset
    }
  }
}
```

This module is intentionally simple; it plays the role of a central map where allocations are declared once.

**`outputs.tf`:**

```hcl
output "ipv4_addresses" {
  description = "Map of hostname to IPv4 address string"
  value = {
    for name, cfg in local.ipv4_map :
    name => cidrhost(cfg.cidr, cfg.ip_offset)
  }
}

output "gateways" {
  description = "Map of VLAN ID to gateway IP"
  value = {
    for vlan, subnet in var.subnets :
    vlan => cidrhost(subnet.cidr, 1)
  }
}
```

The `cidrhost` function uses the base subnet and offset to compute final addresses.

---

## 3. Define Subnet Map in Environment Stack

In the appropriate Terragrunt stack (for example, `dev/10-platform/proxmox/vm/terragrunt.hcl`), define the VLAN subnets that IPAM should manage.

```hcl
locals {
  subnets = {
    10 = { cidr = "10.10.0.0/24" } # Management
    11 = { cidr = "10.11.0.0/24" } # Observability
    20 = { cidr = "10.20.0.0/24" } # Dev
    30 = { cidr = "10.30.0.0/24" } # Staging
    40 = { cidr = "10.40.0.0/24" } # Prod
    50 = { cidr = "10.50.0.0/24" } # Lab
  }
}
```

This local map is passed into the IPAM module as `var.subnets`.

---

## 4. Wire IPAM Module into the Stack

In the same Terraform stack (or a child module), call the IPAM module before the VM module.

```hcl
module "ipam" {
  source = "../../../../../modules/proxmox/ipam"

  subnets = local.subnets

  allocations = {
    "k3s-dev-cp-01" = { vlan = 20, offset = 10 } # 10.20.0.10
    "k3s-dev-cp-02" = { vlan = 20, offset = 11 } # 10.20.0.11
    "k3s-dev-cp-03" = { vlan = 20, offset = 12 } # 10.20.0.12

    "k3s-dev-wk-01" = { vlan = 20, offset = 20 } # 10.20.0.20
    "k3s-dev-wk-02" = { vlan = 20, offset = 21 } # 10.20.0.21
    "k3s-dev-wk-03" = { vlan = 20, offset = 22 } # 10.20.0.22
  }
}
```

This declares all IP allocations for the dev k3s cluster in one place.

---

## 5. Consume IPAM from Proxmox VM Module

Assume the Proxmox VM module accepts a map of VM definitions. One simple pattern is to build a map keyed by hostname.

In the same stack, call the VM module and reference IPAM outputs:

```hcl
module "vm" {
  source = "../../../../../modules/proxmox/vm"

  vms = {
    for name, attrs in module.ipam.ipv4_addresses :
    name => {
      ipv4_address = attrs
      ipv4_gateway = module.ipam.gateways[20] # For VLAN 20
      vlan_id      = 20
      role         = "k3s-node"
      environment  = "dev"
    }
  }
}
```

If the VM module uses a flat variable set instead of a `vms` map, the same pattern can be applied with `tolist()` or by indexing a subset.

---

## 6. Cloud-Init Integration

The VM template must be cloud-init capable. The Proxmox VM module can pass static IPs via cloud-init network configuration.

Example fragment inside the VM module (pseudo-code):

```hcl
resource "proxmox_virtual_environment_vm" "vm" {
  # ... cloning and sizing config ...

  # Example: inject static IP via cloud-init user data
  initialization {
    ip_config = [
      {
        ipv4 = {
          address = "${each.value.ipv4_address}/24"
          gateway = each.value.ipv4_gateway
        }
      }
    ]
  }
}
```

Align this with the actual provider schema used (`telmate/proxmox` vs `bpg/proxmox`). The core idea is that the IPAM module provides deterministic addresses and gateways as inputs.

---

## 7. Validation

Plan and apply the stack:

```bash
terragrunt init
terragrunt plan
terragrunt apply
```

After VMs are created:

- Verify IP addresses in Proxmox UI match the intended `10.X.0.Y` assignments.
- SSH into one VM and check:
  ```bash
  ip addr show
  ip route show
  ping -c3 8.8.8.8
  ```
- Confirm that no two VMs share the same address (Terraform state ensures uniqueness).

---

## 8. Operational Guidelines

- Reserve `.1` in each subnet for the gateway, `.2-.9` for infrastructure services (DNS, monitoring, future use).
- Use offsets `10-250` for general-purpose VMs.
- When decommissioning a VM, retain its allocation in `allocations` map until cleanup is confirmed, to avoid accidental IP reuse during rollback.
- Any change to IP allocations should go through code review, as it can trigger VM recreation depending on module design.

---

## 9. Troubleshooting

**Symptom:** `cidrhost` errors in Terraform plan.

- Check that the `offset` value is within the subnet host range (for `/24`, avoid `0`, `255`).
- Confirm that every `allocations[*].vlan` exists in `var.subnets`.

**Symptom:** VM has no IP, or cloud-init uses DHCP instead.

- Verify the VM template is cloud-init enabled.
- Inspect cloud-init logs inside the VM (`/var/log/cloud-init.log`).
- Confirm the VM module is wiring `ipv4_address` and `ipv4_gateway` into the provider correctly.

---

## 10. References

- [ADR-0101: VLAN Allocation Strategy](../adr/ADR-0101-vlan-allocation-strategy.md)
- [ADR-0104: Static IP Allocation with Terraform IPAM](../adr/ADR-0104-static-ip-allocation-terraform-ipam.md)
- [Network Architecture](../architecture/network-architecture.md)

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
