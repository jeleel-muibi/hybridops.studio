# IPAM Terraform Module (hostname → VLAN + offset allocator)

Purpose
- Deterministic, hostname-keyed IPv4 allocations per VLAN.
- Terraform state is the source of truth for allocations.
- Small, computation-only module suitable for use with Terragrunt stacks.

Inputs
- allocations: map(hostname => object{ vlan = number, offset = number })
  - Example:
    ```hcl
    allocations = {
      "k3s-dev-cp-01" = { vlan = 20, offset = 10 }
      "prometheus-01" = { vlan = 11, offset = 10 }
    }
    ```
- subnet_map: map(string => string) mapping VLAN (string) → CIDR
  - Example:
    ```hcl
    subnet_map = {
      "10" = "10.10.0.0/24"
      "11" = "10.11.0.0/24"
      "20" = "10.20.0.0/24"
    }
    ```
- offset_min / offset_max: integer bounds (defaults 10..250)
- validate_requests: bool (default true) — enable plan/apply-time validation

Outputs
- ipv4_addresses: map(hostname => ip) e.g. { "k3s-dev-cp-01" = "10.20.0.10" }
- gateways: map(vlan_string => gateway_ip) e.g. { "20" = "10.20.0.1" }
- allocated_by_vlan: map(vlan_string => list(hostnames))
- allocation_checks: simple booleans indicating validation results

Notes & recommendations
- This module assumes remote state + locking for the stack that instantiates it. Concurrent applies without locking risk allocation conflicts.
- Prefer this hostname-keyed module for stable per-host addresses.
- To consume IPs in VM stacks, use a separate Terragrunt stack for `ipam/` and a dependent `vm/` stack that reads dependency.<ipam>.outputs.ipv4_addresses.
- For migration: import existing IPs into Terraform state or set offsets to match current addresses and adopt this module going forward.
- This module is intentionally computation-focused (no external resources besides a null_resource to produce tracked state and surface validations).

Example Terragrunt usage:
1) ipam stack (`live/dev/ipam/terragrunt.hcl`) references this module with `allocations` and `subnet_map`.
2) vm stack (`live/dev/vm/terragrunt.hcl`) uses:
   ```
   dependency "ipam" { config_path = "../ipam" }
   inputs = {
     ipv4_address = dependency.ipam.outputs.ipv4_addresses["k3s-dev-cp-01"]
     ipv4_gateway = dependency.ipam.outputs.gateways["20"]
   }
   ```

License: MIT-0 / CC-BY-4.0 for documentation
