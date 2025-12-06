
# Gen Inventory Role

**Automated Ansible Inventory Generation with Governance and Security Controls**

[![License: MIT-0](https://img.shields.io/badge/License-MIT--0-blue.svg)](https://opensource.org/licenses/MIT-0)
[![Ansible](https://img.shields.io/badge/ansible-2.9+-red.svg)](https://ansible.com)

**Maintainer:** HybridOps.Studio
**Version:** 2.1.0
**Updated:** 2025-09-01
**Compatibility:** Ansible 2.9+ | Tested on Linux and macOS

---

## Purpose
This role automates the generation of environment-specific Ansible inventories with governance, security, and compliance controls for hybrid and multi-site infrastructures.

---

## Quick Start
```bash
ansible-playbook -i localhost, tests/test_role.yml -e env=dev
```

---

## Overview
Generates dynamic inventories for multi-site infrastructure. Enforces governance, abstracts sensitive IP data, and ensures consistent host naming across environments.

**Key Outcomes**
- 80% reduction in manual inventory management
- Zero IP exposure in version control
- 18+ months of error-free deployments

---

## Features
- **Governance Integration** – Validates environment before generation
- **Consistent Hostnames** – Uniform naming across environments
- **Security Abstraction** – Placeholder IPs resolved at runtime
- **Multi-Site Support** – Handles global deployments (e.g., Tokyo, Lagos)
- **Redundancy Awareness** – Includes backup nodes automatically

---

## Security Model
```yaml
Generation: Hostnames + placeholder IPs (XX.XX.XX.00)
Runtime:    IP mapping resolved dynamically
Compliance: No real IPs stored in Git
```

**Benefits:** Zero IP leakage, audit-ready, environment isolation.

---

## Architecture
![Inventory Pipeline Diagram](90d460a37a.png)

| Environment | Scale               | IP Ranges (Runtime Only)     |
|-------------|---------------------|-------------------------------|
| dev         | 12 servers, 8 network | 172.16.10.x, 10.10.40.x       |
| staging     | 14 servers, 8 network | 172.16.30.x, 10.10.50.x       |
| prod        | 22 servers, 12 network | 172.16.50.x, 10.10.60.x       |

---

## Pipeline Integration
```yaml
env_guard → gen_inventory → host_selector → ip_mapper → connectivity_test → deploy
```

---

## Sample Output
```ini
[cisco_routers]
coreR-1-Tok ansible_host=XX.XX.XX.00
coreR-2-Lag ansible_host=XX.XX.XX.00

[linux_servers]
Web-01 ansible_host=XX.XX.XX.00
Web-02 ansible_host=XX.XX.XX.00
```

---

## Usage
```bash
# Generate inventory for production
ansible-playbook site.yml -e env=prod

# Run role test (with placeholders)
ansible-playbook -i localhost, tests/test_role.yml
```

---

## Testing
```bash
cd roles/common/gen_inventory
ansible-playbook -i localhost, tests/test_role.yml
```
**Validates:**
✔ Inventory generation
✔ Host group structure
✔ Environment-specific content

---

## Dependencies
- [env_guard](../env_guard) – Environment governance
- [ip_mapper](../ip_mapper) – Runtime IP resolution
- [host_selector](../host_selector) – Target filtering
- [connectivity_test](../connectivity_test) – Network validation

---

## Enterprise Value
- **Zero IP Exposure** – No sensitive data in Git
- **Consistency** – Eliminates configuration drift
- **Audit Compliance** – Full traceability
- **Global Scale** – Multi-region support with redundancy

---

**License:** MIT-0
**Website:** [hybridops.studio](https://hybridops.studio)

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
