# IPAM Terraform Module (hostname → VLAN + offset allocator)

## Purpose
- Deterministic, hostname-keyed IPv4 allocations per VLAN.
- Terraform state is the source of truth for allocations.
- Small, computation-only module suitable for use with Terragrunt stacks.

---

## Inputs
- **`allocations`**: Map (hostname → `{ vlan = number, offset = number }`)  
  Example:
  ```hcl
  allocations = {
    "k3s-dev-cp-01" = { vlan = 20, offset = 10 }
    "prometheus-01" = { vlan = 11, offset = 10 }
  }
  ```

- **`subnet_map`**: Map (VLAN (string) → CIDR)  
  Example:
  ```hcl
  subnet_map = {
    "10" = "10.10.0.0/24"
    "11" = "10.11.0.0/24"
    "20" = "10.20.0.0/24"
  }
  ```

- **`offset_min` / `offset_max`**: Integer bounds for valid offsets (defaults 10..250).

- **`validate_requests`**: Boolean (default = `true`)  
  Enables validation of allocations during `plan` and `apply`.

---

## Outputs
- **`ipv4_addresses`**: Map (hostname → IPv4 address)  
  Example:
  ```hcl
  {
    "k3s-dev-cp-01" = "10.20.0.10"
    "prometheus-01" = "10.11.0.10"
  }
  ```

- **`gateways`**: Map (VLAN (string) → gateway IP)  
  Example:
  ```hcl
  {
    "20" = "10.20.0.1"
  }
  ```

- **`allocated_by_vlan`**: Map (VLAN (string) → list of hostnames).  
  Example:
  ```hcl
  {
    "20" = ["k3s-dev-cp-01", "k3s-dev-cp-02"]
  }
  ```

- **`allocation_checks`**: Validation booleans for:
  - **`offsets_in_range`**: Whether all offsets are valid.
  - **`vlans_exist`**: Whether all VLANs in `allocations` exist in `subnet_map`.

---

## Notes & Recommendations
- **Concurrency**: Use remote state with locking to avoid allocation conflicts. Concurrent `apply` operations without locking are **not recommended**.
- **Stability**: Prefer this hostname-keyed module for immutable, predictable IP allocations (e.g., per-host addresses that don't change across apply runs).
- **Consumption in VM Stacks**: Use the IPAM module as a separate Terragrunt stack, and have dependent stacks (e.g., VMs) read the outputs, e.g.,:
  ```hcl
  dependency "ipam" {
    config_path = "../ipam"
  }
  inputs = {
    ipv4_address = dependency.ipam.outputs.ipv4_addresses["k3s-dev-cp-01"]
  }
  ```

---

## Mock Outputs for Testing

Mock outputs allow downstream modules to simulate `ipam` outputs (e.g., `ipv4_addresses`, `gateways`) during development or testing when this module is not yet deployed.

### Usage
Enable mock outputs dynamically by setting `TERRAGRUNT_USE_MOCKS=true` and using a Terragrunt configuration like:

```hcl
dependency "ipam" {
  config_path = "../ipam"

  mock_outputs = (get_env("TERRAGRUNT_USE_MOCKS", "false") == "true" ? {
    ipv4_addresses = {
      "k3s-dev-cp-01" = "10.20.0.10"
      "k3s-dev-cp-02" = "10.20.0.11"
    }
    gateways = {
      "20" = "10.20.0.1"
    }
  } : null)

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}
```

### Best Practices
- **Development-only**: Mocks should only be enabled in lower environments (`dev`).  
- **Unset Before Production**: Always disable mocks before transitioning to production:
  ```bash
  unset TERRAGRUNT_USE_MOCKS
  ```

---

## Example Terragrunt Workflow

### IPAM Stack
The IPAM stack references this module to define `allocations` and `subnet_map` settings:
- Path: `live/dev/ipam/terragrunt.hcl`.

Example:
```hcl
inputs = {
  allocations = {
    "k3s-dev-cp-01" = { vlan = 20, offset = 10 }
    "prometheus-01" = { vlan = 11, offset = 10 }
  }
  subnet_map = {
    "20" = "10.20.0.0/24"
    "11" = "10.11.0.0/24"
  }
}
```

### VM Stack
The VM stack references the `ipam` stack to consume outputs:
```hcl
dependency "ipam" {
  config_path = "../ipam"
}

inputs = {
  static_ips  = [for name in ["k3s-dev-cp-01", "k3s-dev-cp-02"] : dependency.ipam.outputs.ipv4_addresses[name]]
  gateway     = dependency.ipam.outputs.gateways["20"]
}
```

---

## License
- **Code**: MIT-0 (MIT No Attribution)  
- **Documents**: CC-BY-4.0
