# IPAM Module - Hostname-Keyed IP Address Management

## Overview

This Terraform module implements a hostname-keyed IP Address Management (IPAM) system. It is a computation-only module that assigns IPv4 addresses based on hostname-to-VLAN-offset mappings.

## Features

- **Hostname-based allocation**: Maps hostnames to IPv4 addresses using VLAN and offset
- **Multi-VLAN support**: Manages IP allocations across multiple VLANs/subnets
- **Validation checks**: Optional validation of allocations including range checks and duplicate detection
- **State tracking**: Uses `null_resource` to record allocations in Terraform state
- **Gateway computation**: Automatically computes gateway addresses for each VLAN

## Usage

```hcl
module "ipam" {
  source = "./modules/proxmox/ipam"

  allocations = {
    "dev-k3s-01" = {
      vlan   = "20"
      offset = 10
    }
    "dev-k3s-02" = {
      vlan   = "20"
      offset = 11
    }
    "prometheus-01" = {
      vlan   = "20"
      offset = 20
    }
  }

  subnet_map = {
    "20" = "10.20.0.0/24"
  }

  offset_min        = 10
  offset_max        = 250
  validate_requests = true
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| allocations | Map of hostname to allocation details (vlan, offset) | `map(object({ vlan = string, offset = number }))` | n/a | yes |
| subnet_map | Map of VLAN string to CIDR block | `map(string)` | n/a | yes |
| offset_min | Minimum allowed offset for IP allocation | `number` | `10` | no |
| offset_max | Maximum allowed offset for IP allocation | `number` | `250` | no |
| validate_requests | Enable validation checks for allocation requests | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| ipv4_addresses | Map of hostname to IPv4 address |
| gateways | Map of VLAN string to gateway IP address |
| allocated_by_vlan | Allocations grouped by VLAN with hostnames and IPs |
| allocation_checks | Validation check results for allocations |

## Examples

### Basic allocation
```hcl
allocations = {
  "server-01" = { vlan = "20", offset = 10 }
  "server-02" = { vlan = "20", offset = 11 }
}

subnet_map = {
  "20" = "10.20.0.0/24"
}
```

This will produce:
- `server-01` → `10.20.0.10`
- `server-02` → `10.20.0.11`
- Gateway for VLAN 20 → `10.20.0.1`

### Multi-VLAN allocation
```hcl
allocations = {
  "web-01"    = { vlan = "10", offset = 10 }
  "db-01"     = { vlan = "20", offset = 10 }
  "cache-01"  = { vlan = "30", offset = 10 }
}

subnet_map = {
  "10" = "10.10.0.0/24"
  "20" = "10.20.0.0/24"
  "30" = "10.30.0.0/24"
}
```

## Validation

When `validate_requests = true`, the module performs the following checks:

1. **Offset range validation**: Ensures all offsets are within `offset_min` and `offset_max`
2. **VLAN existence**: Verifies all VLANs in allocations exist in `subnet_map`
3. **Duplicate detection**: Checks for duplicate offsets within the same VLAN

Validation failures will cause the Terraform plan/apply to fail with descriptive error messages.

## Notes

- This is a computation-only module with no cloud provider resources
- The `null_resource` is used solely for state tracking and validation
- Gateway addresses are computed as the first usable IP (offset 1) in each subnet
- Hostnames are case-sensitive and should follow your naming conventions
