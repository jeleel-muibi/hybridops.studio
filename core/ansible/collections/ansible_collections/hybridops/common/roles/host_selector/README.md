# Host Selector Role

**Enterprise host targeting with governance integration**

[![License: MIT-0](https://img.shields.io/badge/License-MIT--0-blue.svg)](https://opensource.org/licenses/MIT-0)
[![Ansible](https://img.shields.io/badge/ansible-2.9%2B-red.svg)](https://ansible.com)

**Maintainer:** HybridOps.Studio

---

## Overview

Production-grade host selection role for enterprise automation. Provides secure, auditable targeting with four selection methods and mandatory governance integration.

**Highlights:**
- Validated reduction in selection errors
- Governance-enforced environment isolation
- Pipeline-ready dynamic grouping

---

## Features

- **4 Selection Methods** — Manual, group-based, hierarchical, bulk
- **Governance Integration** — `env_guard` sets `validated_env` and `correlation_id`
- **Pipeline Ready** — Creates `targets_to_ping` group for downstream processing
- **Enterprise Validation** — Input validation with clear failure routes
- **Traceability** — Logs and summaries include `correlation_id`

---

## New in v2.3.0
- **Method B UX:** Columnized group listing for better readability
- **Method C:** Consistent 1-based menus and improved validation

---

### Method B Example Prompt
```
Available groups:
arista_switches       cisco_routers          cisco_switches
docker_hosts          grafana_servers        k8s_pods
linux_servers         monitoring             nas_storage
pfsense_firewalls     prometheus_servers     routers
servers               switches               tokyo_devices
vyos_routers          windows_servers

Enter group name(s), comma-separated:
```

---

## Pipeline Integration

```text
env_guard → gen_inventory → host_selector → ip_mapper → connectivity_test → deployment
#           (sets env + ID)     (targeting)     (IP mapping)     (reachability)
```

---

## Selection Methods

| Method | Use Case         | Example Input                  |
|--------|------------------|--------------------------------|
| **A**  | Emergency/Ad-hoc | `172.16.10.10,server01.local` |
| **B**  | Group Operations | `cisco_routers,Tokyo`         |
| **C**  | Discovery/Browse | Navigate categories → select  |
| **D**  | Bulk Operations  | All infrastructure hosts      |

---

## Infrastructure Categories

```yaml
Network: cisco_routers, arista_switches, vyos_routers, pfsense_firewalls
Compute: linux_servers, windows_servers, docker_hosts, k8s_pods
Monitoring: prometheus_servers, grafana_servers, nas_storage
Geographic: Tokyo, Lagos
```

---

## Correlation ID (CID)

- Source order: `correlation_id` / `egf_correlation_id` (from `env_guard`) → `EGF_CORR_ID` → generated.
- Logging-only; no propagation to hosts or extra-vars.
- Disable via `host_selector_use_cid: false`.

### Example
```bash
# Integrated run (env_guard seeds correlation_id)
ansible-playbook site.yml

# Standalone with environment-provided CID
EGF_CORR_ID=$(uuidgen) ansible-playbook site.yml
```

---

## Usage

```yaml
- hosts: localhost
  gather_facts: yes
  roles:
    - role: host_selector
```

### Variables
| Variable | Type | Default | Purpose |
|---|---|---|---|
| `host_selector_use_cid` | bool | `true` | Toggle CID logging. |
| `host_selector_inherited_cid` | str | _empty_ | CID from `env_guard` (`correlation_id`/`egf_correlation_id`). |
| `host_selector_env_cid` | str | _empty_ | CID from environment `EGF_CORR_ID`. |
| `host_selector_cid_pre` | str | _empty_ | First non-empty candidate; generation occurs in tasks if empty. |

---

## Testing

```bash
# Interactive (prompts for method; env via env_guard)
ansible-playbook -i tests/inventory/test_inventory.ini tests/test_role.yml

# CI/CD (non-interactive)
ansible-playbook -i tests/inventory/test_inventory.ini tests/test_role.yml   -e "validated_env=staging correlation_id=ci-run-12345 method=D"
```

---

## Dependencies

- **env_guard** — Sets `validated_env` and `correlation_id`
- **gen_inventory** — Creates placeholder hosts
- **ip_mapper** — Runtime IP resolution
- **connectivity_test** — Reachability validation

---

## Enterprise Value

- **Risk Mitigation** — Governance-enforced environment isolation
- **Operational Efficiency** — Four targeting methods for varied workflows
- **Audit Compliance** — Traceable executions via correlation ID
- **Team Enablement** — Hierarchical browsing for infrastructure discovery
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

**MIT-0 License** · [hybridops.studio](https://hybridops.studio) · **jeleel-muibi**
