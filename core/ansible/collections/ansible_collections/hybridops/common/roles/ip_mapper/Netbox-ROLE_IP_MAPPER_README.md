# IP Mapper (Bridge) — Runtime Address Resolution

[![License: MIT-0](https://img.shields.io/badge/License-MIT--0-blue.svg)](https://opensource.org/licenses/MIT-0)
[![Ansible](https://img.shields.io/badge/ansible-2.9%2B-red.svg)](https://ansible.com)

**Author:** Jeleel Muibi · **Version:** 2.2.0 · **Updated:** 2025‑09‑24

> **Status:** Bridge role. In NetBox‑first deployments, this role becomes **optional** or a **fallback**.
> It remains for environments still migrating from file/TF outputs to NetBox as the single source of truth.

---

## What it does

Resolves **placeholder** inventory addresses (e.g., `ansible_host=XX.XX.XX.00`) to **real, environment‑specific IPs** at **runtime**, without storing addresses in Git.

Resolution order (first hit wins):

1) **NetBox API** — device/interface primary IP by **name/tag/role/site**.
2) **Runtime mapping file (YAML)** — typically generated from Terraform outputs (e.g., `core/ansible/runtime/ips/<env>.yml`).
3) **Terraform output (JSON)** — optional direct parse when a YAML mapping isn’t present.

All updates occur in‑memory (hostvars) during the play; inventories on disk are not modified.

---

## Why keep this role (even with NetBox)?

- **Graceful migration** from legacy mappings to NetBox.
- **Fallback** when NetBox is temporarily unavailable.
- **Supplemental resolution** for ad‑hoc hosts not yet modeled in NetBox.

---

## Pipeline fit

This role is designed for the governed pipeline:

```mermaid
flowchart LR
  A[env_guard<br/>Governance & CID] --> B[gen_inventory<br/>Placeholders only]
  B --> C[host_selector<br/>Approved scope]
  C --> D[ip_mapper (this role)<br/>Resolve real IPs]
  D --> E[connectivity_test<br/>Reachability gate]
  E --> F[deployment<br/>Controlled rollout]
```

When using **NetBox dynamic inventory** for the whole scope, this role can be **skipped**.

---

## Inputs

### Variables (common)
- `validated_env` (string) — environment key, e.g., `dev|staging|prod`.
- `cid` (string, optional) — correlation ID for audit logs.
  Falls back to `EGF_CORR_ID` env var or is generated at runtime.

### NetBox (preferred)
- `netbox_url` (string) — e.g., `https://netbox.example.com`.
- `netbox_token` (string, **secret**) — API token (pass via Ansible Vault or env var `NB_TOKEN`).
- **Selectors (any that fits your modeling):**
  - `nb_lookup_by` (string) — one of `name|tag|role` (default: `name`)
  - `nb_device_name_key` (string) — hostvar to use as lookup key (default: `inventory_hostname`)
  - `nb_site` / `nb_role` / `nb_tag` (optional filters)

### Runtime file (fallback)
- `ip_map_file` (string) — default: `core/ansible/runtime/ips/{{ validated_env }}.yml`
  Expected shape:
  ```yaml
  environments:
    dev:
      cisco_routers:
        - { name: coreR-1-Tok, ip: 172.16.13.21 }
        - { name: coreR-2-Lag, ip: 172.16.13.20 }
      cisco_switches:
        - { name: Asw-1-Tok, ip: 172.16.13.15 }
  ```

### Terraform output (fallback of last resort)
- `tf_output_json` (string, optional) — path to a `terraform show -json` or exported outputs JSON.

---

## Outputs

- Sets `hostvars[inventory_hostname].ansible_host` for each selected host.
- Emits CID‑prefixed audit logs for unmapped hosts and resolution source.

---

## Usage

### 1) NetBox‑first (recommended)

```yaml
- name: Resolve addresses via NetBox (preferred)
  hosts: all
  gather_facts: false
  vars:
    validated_env: prod
    netbox_url: "https://netbox.example.com"
    netbox_token: "{{ lookup('env', 'NB_TOKEN') }}"
    nb_lookup_by: "name"           # or tag/role
  roles:
    - hybridops.common.ip_mapper
```

### 2) Runtime YAML map (bridge)

```yaml
- name: Resolve addresses via runtime mapping file
  hosts: all
  gather_facts: false
  vars:
    validated_env: staging
    ip_map_file: "core/ansible/runtime/ips/{{ validated_env }}.yml"
  roles:
    - hybridops.common.ip_mapper
```

### 3) Terraform outputs (last resort)

```yaml
- name: Resolve addresses from Terraform output
  hosts: all
  gather_facts: false
  vars:
    validated_env: dev
    tf_output_json: "core/terraform-infra/output/{{ validated_env }}.json"
  roles:
    - hybridops.common.ip_mapper
```

---

## Behavior & guarantees

- **Zero IPs in Git:** resolution is runtime‑only.
- **Least privilege:** NetBox token can be scoped read‑only.
- **Deterministic:** if multiple sources exist, the first defined source that yields a value wins (NetBox → YAML → TF).
- **Auditable:** all decisions are logged with `cid`.

---

## Testing (role harness)

A minimal harness is provided under `roles/common/ip_mapper/tests/`. Example:

```bash
ansible-playbook -i roles/common/ip_mapper/tests/inventory/test_inventory.ini   roles/common/ip_mapper/tests/test_role.yml -e validated_env=dev
```

- Provide either `NB_TOKEN`/`netbox_url`, or a sample `ip_map_file`.
- The harness asserts that `ansible_host` is set for targets; unmapped hosts fail the run.

---

## Deprecation & roadmap

- **Now:** Prefer NetBox dynamic inventory for full‑scope inventories.
- **Short‑term:** Keep this role as a bridge/fallback and for ad‑hoc targets.
- **Long‑term:** If the estate is fully modeled in NetBox and inventories come from the NetBox plugin, this role can be removed from the main path and retained only for edge cases.

---

**License:** MIT‑0 · © HybridOps.Studio (Jeleel Muibi)
