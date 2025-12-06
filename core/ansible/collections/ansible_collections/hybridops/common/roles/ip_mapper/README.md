# IP Mapper Role

**Enterprise IP address resolution with governance integration**

[![License: MIT-0](https://img.shields.io/badge/License-MIT--0-blue.svg)](https://opensource.org/licenses/MIT-0)
[![Ansible](https://img.shields.io/badge/ansible-2.9+-red.svg)](https://ansible.com)

**Maintainer:** HybridOps.Studio

---

## Overview

Production-grade IP address resolution for enterprise infrastructure automation. Resolves placeholder IPs from gen_inventory to environment-specific addresses with governance integration.

**Impact:** 100% dynamic addressing, zero hardcoded IPs, environment-aware deployments.

## Features

- **Dynamic IP Resolution** - Maps placeholder IPs to real environment addresses
- **Governance Integration** - env_guard framework dependency
- **Security Architecture** - Runtime resolution eliminates IP exposure in repos
- **Enterprise Validation** - Comprehensive error handling and audit compliance

## Pipeline Integration

```yaml
env_guard → gen_inventory → host_selector → ip_mapper → connectivity_test → deployment
#           (placeholders)                   (real IPs)
```

## Input/Output

**Before (gen_inventory):**
```ini
[cisco_routers]
test-router-01 ansible_host=XX.XX.XX.00    # Security placeholder
```

**After (ip_mapper staging):**
```ini
[cisco_routers]
test-router-01 ansible_host=10.0.1.1       # Runtime resolution
```

## Environment Structure

```yaml
environments:
  staging:
    cisco_routers:
      - { name: test-router-01, ip: 10.0.1.1 }
    cisco_switches:
      - { name: test-switch-01, ip: 10.0.1.10 }
```

## Testing

The role includes an isolated test harness under `roles/common/ip_mapper/tests/`:

```bash
# Run interactive test (prompts for environment)
ansible-playbook -i roles/common/ip_mapper/tests/inventory/test_inventory.ini   roles/common/ip_mapper/tests/test_role.yml

# Or specify environment via CLI
ansible-playbook -i roles/common/ip_mapper/tests/inventory/test_inventory.ini   roles/common/ip_mapper/tests/test_role.yml -e validated_env=dev
```

> **Note:** The test harness uses `tests/inventory/group_vars/all.yml` for environment data, ensuring isolation from production inventories.

### Prompt Mode (for isolated tests)

The test playbook uses `vars_prompt` to request the environment interactively:

```
Enter validated environment (dev/staging/prod): dev
```

### Test Coverage

✅ Environment prompt or CLI override
✅ Placeholder replacement → real IP mapping
✅ Assertion that `ansible_host` is set and valid

## Usage

```bash
ansible-playbook site.yml -e env=staging    # Environment-specific resolution
ansible-playbook -i tests/inventory/test_inventory.ini tests/test_role.yml    # Testing IP mapping
```

## Dependencies

- **[env_guard](../env_guard/)** - Environment governance
- **[gen_inventory](../gen_inventory/)** - Creates placeholder hosts
- **[host_selector](../host_selector/)** - Target selection
- **[connectivity_test](../connectivity_test/)** - Validates resolved IPs

## Enterprise Value

- **Environment Isolation** - Same hostnames, different IPs per environment
- **Zero IP Exposure** - No hardcoded addresses in version control
- **Audit Compliance** - Full traceability with correlation IDs
- **Deployment Consistency** - Identical playbooks across environments

## Metrics

**Resolution:** 100% dynamic | **Security:** Zero IP exposure | **Environments:** 3 tiers

## CID Logging Behavior

The IP Mapper role supports dynamic Correlation ID (CID) tagging for traceability across automation pipelines.

When enabled, all debug and failure messages include a CID prefix:

```yaml
- name: Report unmapped hosts
  debug:
    msg: "[cid={{ cid }}] Unmapped hosts in {{ validated_env }}: {{ unmapped_hosts | join(', ') }}"

- name: Fail on complete mapping failure
  fail:
    msg: "[cid={{ cid }}] No IP mappings found for any hosts in environment {{ validated_env }}"
```

This ensures every log entry is traceable to a specific execution context, supporting audit compliance and multi-run debugging.

CID is inherited from:
- `correlation_id` (passed in playbook)
- `EGF_CORR_ID` (environment variable)
- Or generated at runtime if missing
---

## Pipeline Context

This role is part of the Environment Guard Framework (EGF) pipeline.

For full pipeline flow and visuals, see:
- [docs/egf_pipeline.md](../../../../docs/egf_pipeline.md)

Related roles:
- [env_guard](../env_guard/) – Governance, risk scoring, CID generation
- [host_selector](../host_selector/) – Secure host targeting
- [ip_mapper](../ip_mapper/) – Runtime IP resolution

> Updated: 2025-09-10 11:10:00 UTC

---

**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
