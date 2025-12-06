---
title: "HOWTO: Use NetBox as Source of Truth for Ansible and Nornir"
category: "networking"
summary: "Step-by-step guide for driving Ansible and Nornir inventory from NetBox as the source of truth."
difficulty: "Intermediate"

topic: "netbox-inventory-flow"

video: "https://www.youtube.com/watch?v=VIDEO_ID_REPLACE"
source: ""

draft: false
is_template_doc: false
tags: ["netbox", "inventory", "ansible", "nornir"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# HOWTO: Use NetBox as Source of Truth for Ansible and Nornir

**Purpose:** Configure NetBox as the authoritative inventory for routers, firewalls, Proxmox, and platform nodes, and expose that data to Ansible and Nornir.  
**Difficulty:** Intermediate  
**Prerequisites:**  
- NetBox instance reachable from the control node (HTTPS).  
- API token with read access to devices, IPAM, and tags.  
- Python environment on the control node.  
- Basic familiarity with Ansible and/or Nornir.

---

## Demo

Every HOWTO in HybridOps.Studio is expected to have a short demo or walkthrough video.

- Demo: [Watch on YouTube](https://youtu.be/VIDEO_ID_REPLACE)  
- Source (optional): _add when exporter script is in GitHub_

??? info "▶ Show embedded demo"

    <iframe
      width="100%"
      height="400"
      src="https://www.youtube.com/embed/VIDEO_ID_REPLACE"
      title="HOWTO: Use NetBox as Source of Truth for Ansible and Nornir – HybridOps.Studio"
      frameborder="0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      allowfullscreen>
    </iframe>

    If the embed does not load, use the direct link:  
    [Open on YouTube](https://www.youtube.com/watch?v=VIDEO_ID_REPLACE){ target=_blank rel="noopener" }

---

## Context

HybridOps.Studio treats **NetBox as the source of truth** for networking and platform inventory (see
[ADR-0002 – Source of Truth: NetBox-Driven Inventory](../adr/ADR-0002_source-of-truth_netbox-driven-inventory.md)).  
Automation tools (Ansible, Nornir) do **not** own the inventory; they consume it.

This HOWTO shows how to:

- Model sites, devices, and tags in NetBox.  
- Export that data into **Ansible** and **Nornir** inventory files.  
- Wire those inventories into playbooks and Nornir jobs.  

Use this when you want consistent inventory for:

- Network automation (CSR, VyOS, pfSense, EVE-NG “edge” devices).  
- Platform automation (Proxmox, K3s nodes) that still needs network context.  

---

## 1. Model Authoritative Data in NetBox

### 1.1 Create Sites and Tenants

In the NetBox UI (or via API):

- Create sites such as `hos-onprem-1`, `hos-lab-1`.  
- Optionally define tenants (for example `hybridops-core`, `academy`).  

This gives you a physical/logical anchor for devices.

### 1.2 Define VLANs and Prefixes

Align IPAM with your ADRs:

- VLANs and prefixes per [ADR-0101 – VLAN Allocation Strategy](../adr/ADR-0101-vlan-allocation-strategy.md).  
- Example: `VLAN 20 / 10.20.0.0/24` for dev, `VLAN 40 / 10.40.0.0/24` for prod.  

Make sure VLANs and prefixes are associated with the correct site.

### 1.3 Register Devices and Roles

For each device class:

- Create roles: `router`, `firewall`, `proxmox-node`, `k8s-node`, `eve-ng`, etc.  
- Create platforms: `cisco_csr1000v`, `vyos`, `pfsense`, `proxmox`, `ubuntu-k3s`.  
- Create devices and link them to sites, roles, platforms, and primary IPs.

Recommended tags (examples):

- `env=dev|staging|prod`  
- `role=router|firewall|proxmox|k8s-node`  
- `site=hos-onprem-1`  

These tags are what Ansible and Nornir will filter on.

---

## 2. Build the NetBox Inventory Exporter

### 2.1 Create Exporter Directory

On the control node repository (for example in `control/tools/inventory/`):

```bash
mkdir -p control/tools/inventory
touch control/tools/inventory/netbox_export_inventory.py
touch control/tools/inventory/netbox_export_config.yaml
```

### 2.2 Configure Exporter Settings

Example `netbox_export_config.yaml`:

```yaml
netbox:
  api_url: "https://netbox.example.com"
  api_token: "!vault | NETBOX_API_TOKEN"

filters:
  tags:
    - "site=hos-onprem-1"

output:
  ansible_inventory: "infra/ansible/inventory/netbox_hosts.yaml"
  nornir_inventory: "infra/nornir/inventory/netbox_inventory.yaml"
```

### 2.3 Implement Minimal Exporter Logic

The exact implementation will evolve, but the pattern is:

- Connect to NetBox API.  
- Pull devices (and optionally interfaces, IPs) based on filters.  
- Render simple YAML documents for Ansible and Nornir.

Example Ansible inventory shape:

```yaml
all:
  hosts:
    csr-01:
      ansible_host: 10.20.0.10
      env: dev
      role: router
    pfsense-01:
      ansible_host: 10.10.0.10
      env: prod
      role: firewall
```

Example Nornir inventory shape:

```yaml
csr-01:
  hostname: 10.20.0.10
  platform: cisco_ios
  groups: ["routers", "env_dev"]
  data:
    site: hos-onprem-1

pfsense-01:
  hostname: 10.10.0.10
  platform: pfsense
  groups: ["firewalls", "env_prod"]
```

---

## 3. Wire Ansible to the NetBox Inventory

### 3.1 Point Ansible to the Generated Inventory

In `infra/ansible/ansible.cfg`:

```ini
[defaults]
inventory = inventory/netbox_hosts.yaml
```

### 3.2 Use Tags/Vars to Target Hosts

Examples:

```bash
# All dev devices (tagged env=dev in NetBox)
ansible-playbook site.yml -l env_dev

# Only firewalls (role=firewall)
ansible-playbook pfsense-flow-control.yml -l role_firewall
```

Ansible does not need to know about sites or roles directly; it relies on what NetBox rendered into the inventory.

---

## 4. Wire Nornir to the NetBox Inventory

### 4.1 Configure Nornir Inventory Source

In `infra/nornir/config.yaml`:

```yaml
inventory:
  plugin: SimpleInventory
  options:
    host_file: "inventory/netbox_inventory.yaml"
```

### 4.2 Filter and Run Tasks

Example usage:

```python
from nornir import InitNornir

nr = InitNornir(config_file="infra/nornir/config.yaml")

routers = nr.filter(role="router", env="prod")
result = routers.run(task=my_netconf_check_task)
```

Task outputs, including NETCONF snapshots and routing tables, should be written to:

- `docs/proof/networking/netconf-csr1000v/`  
- `docs/proof/networking/vrrp-tests/`  
- `docs/proof/networking/full-mesh-tests/`  

depending on the scenario.

---

## 5. Integrate with CI/CD and Environment Guard

Typical CI flow:

1. `make inventory.netbox-export` – refresh inventories from NetBox.  
2. `make ansible.validate` – lint and dry-run Ansible playbooks.  
3. `make nornir.check` – run read-only health checks via NETCONF/SSH.  

Environment Guard jobs can also:

- Verify that all “intended” devices exist in NetBox.  
- Flag orphans (devices in NetBox but missing from Proxmox/cloud and vice versa).  
- Validate tag patterns against ADRs (for example VLANs per ADR-0101, env tags per governance rules).  

---

## Validation

You have successfully wired NetBox as the source of truth when:

- `netbox_export_inventory.py` produces up-to-date `netbox_hosts.yaml` and `netbox_inventory.yaml`.  
- Ansible can target devices by environment, site, or role without changing playbooks.  
- Nornir can filter on the same metadata and save evidence under `docs/proof/...`.  
- CI jobs fail fast when NetBox or inventory exports are out of date.

Recommended checks:

```bash
# Export inventory
make inventory.netbox-export

# Inspect generated files
yq '.all.hosts | keys' infra/ansible/inventory/netbox_hosts.yaml
yq 'keys' infra/nornir/inventory/netbox_inventory.yaml
```

---

## Troubleshooting

**Symptom:** Exporter fails with authentication error.  
- Check `NETBOX_API_URL` and `NETBOX_API_TOKEN`.  
- Verify the token has correct permissions in NetBox.

**Symptom:** Devices missing from inventory.  
- Confirm their tags, site, or env match the filters in `netbox_export_config.yaml`.  
- Check that they have a primary IP address defined.

**Symptom:** Ansible/Nornir cannot reach devices.  
- Verify `ansible_host` / `hostname` fields match reachable management IPs.  
- Confirm firewall rules between control node and devices.

---

### References

- [ADR-0002 – Source of Truth: NetBox-Driven Inventory](../adr/ADR-0002_source-of-truth_netbox-driven-inventory.md)  
- [ADR-0101 – VLAN Allocation Strategy](../adr/ADR-0101-vlan-allocation-strategy.md)  
- [Network Architecture](../prerequisites/network-architecture.md)  
- [Runbook – NetBox Initial Seed & Bootstrap](../runbooks/bootstrap/netbox-seed.md)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
