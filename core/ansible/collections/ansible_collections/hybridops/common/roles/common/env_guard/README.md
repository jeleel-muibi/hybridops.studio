# Environment Guard Framework

**Enterprise-grade deployment governance for Ansible infrastructure**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Ansible](https://img.shields.io/badge/ansible-2.9+-red.svg)](https://ansible.com)
[![Status](https://img.shields.io/badge/status-production-brightgreen.svg)](#)

**Author:** jeleel-muibi
**Updated:** 2025-09-10 20:55 UTC
**Version:** 2.1.3

---

## Executive Summary

A **production-ready Ansible governance framework** with interactive risk assessment, correlation ID tracking, and compliance enforcement.
Prevents unauthorized deployments while enabling developer velocity and full auditability.

**Business Impact:**
- Eliminates accidental production deployments
- Provides complete traceability for audits and incident response

---

## Key Enhancements (v2.1.3)

- **Correlation ID Everywhere**: UUID-based, propagated across logs, reports, and callbacks
- **CID in Filenames**: Easy grepping and artifact traceability
- **Structured Audit Logging**: ISO8601 timestamps, justification, risk score
- **Test Suite Hardening**: Validates CID presence in logs and reports without shell dependencies
- **Dynamic Path Discovery**: Works in any project structure

---

## Features

- Interactive risk scoring and approval workflows
- Maintenance window enforcement for production
- Multi-factor scoring: environment, scope, timing, user
- Full audit trail with correlation IDs
- Organized logging under `common/logs/env_guard_logs/<timestamped_run_folder>`
- Pure Ansible—no external dependencies

---

## Risk Matrix

| Environment | Risk | Approval | Window       | Impact           |
|-------------|------|----------|--------------|------------------|
| dev         | 1/10 | Auto     | 24/7         | Development only |
| staging     | 5/10 | Auto*    | Business hrs | Pre-production   |
| prod        |10/10 | Manual   | Maint. only  | Live systems     |

*Auto unless risk ≥ 8

---

## Interactive Protection Flow

```
Environment Selection → Risk Assessment → Approval Workflow → Deployment Authorization
```

**Production Example:**
```
PRODUCTION DEPLOYMENT DETECTED
ENVIRONMENT: PROD | RISK: 10/10 | HOSTS: 12
USER: jeleel-muibi | TIME: 2025-09-10T20:55Z
MAINTENANCE WINDOW: INACTIVE

Justification Required: Critical security patch
Manual Confirmation: Type 'DEPLOY' to proceed
Correlation ID: envguard-<uuid>
```

---

## Architecture Highlights

**Dynamic Project Root Discovery:**
```yaml
_project_root: "{{ playbook_dir
  | regex_replace('/common/playbooks.*$', '')
  | regex_replace('/roles/.*$', '') }}"
```

**Logging Structure:**
```
common/logs/
└── env_guard_logs/
    └── <timestamped_run_folder>/
        ├── env_guard_audit.log
        └── env_guard_report_<timestamp>_<cid8>.md
```

**Correlation ID Generation:**
- Primary: `uuidgen`
- Fallback: `envguard-<epoch>-<12-char-hex>`

---

## Enterprise Integration

**Pipeline Example:**
```yaml
- hosts: localhost
  roles:
    - common/env_guard
    - common/gen_inventory
    - application/deploy
```

**Usage:**
```bash
# Interactive
ansible-playbook deploy.yml

# Force prod (requires approval)
ansible-playbook deploy.yml -e env=prod
```

---

## Testing & Validation

**Run Test Suite:**
```bash
cd roles/common/env_guard/tests
ansible-playbook test_env_validation.yml
```

**Validates:**
- Correlation ID format
- CID in audit log (copied to `test/output/`)
- CID-stamped report file exists (copied to `test/output/`)

---

## CI Integration

This framework supports CI pipelines using the `make ci-test` target.

**Quick usage:**
```bash
make ci-test CI_ENV=staging
```

**GitHub Actions Example:**
```yaml
name: CI Test
on:
  push:
    paths:
      - roles/common/env_guard/**
      - Makefile
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Ansible
        run: sudo apt-get update && sudo apt-get install -y ansible
      - name: Run CI Test
        run: make ci-test CI_ENV=staging
```

For full details, see [docs/ci_integration.md](docs/ci_integration.md)

---

## Metrics

- Deployment Accuracy: 100%
- Risk Assessment: <1s
- Integration Overhead: Zero
- Audit Compliance: Full correlation tracking

---

## Security Layers

1. Environment validation
2. Risk scoring (10-point scale)
3. Approval gates for high-risk
4. Maintenance window enforcement
5. Structured audit logging
6. Dynamic path security

**Audit Example:**
```
2025-09-10T20:55Z envguard-1735924673-abc123 jeleel-muibi PROD APPROVED
risk=10 hosts=12 justification="Critical security patch"
```

---

## Framework Variables

**Input:** `env` (dev/staging/prod)
**Output:**
- `validated_env`
- `env_guard_risk_score`
- `env_guard_correlation_id`

---

## Integration Ecosystem

- [gen_inventory](../gen_inventory/)
- [ip_mapper](../ip_mapper/)
- [connectivity_test](../connectivity_test/)
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

**MIT-0 License** | [hybridops.studio](https://hybridops.studio) | **jeleel-muibi**
