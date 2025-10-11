---
title: "Source of Truth (SoT) Pivot — Terraform → NetBox → Ansible"
category: dr
summary: "Switch from a bootstrap hosts.ini to NetBox-backed dynamic inventory seeded from Terraform outputs."
last_updated: 2025-10-08
severity: P2
---

# Source of Truth (SoT) Pivot — Terraform → NetBox → Ansible

**Purpose:** Switch from bootstrap inventory to NetBox‑backed dynamic inventory.

## Preconditions
- Bootstrap completed (`inventories/bootstrap/hosts.ini` used once).
- Terraform outputs are current and exported as JSON.

## Steps
1. **Export Terraform Outputs**
   ```bash
   terraform -chdir=terraform-infra/onprem/dev output -json > output/artifacts/inventories/$(date -Iseconds)_tf_out_onprem_dev.json
   ```
2. **Seed NetBox from Outputs**
   ```bash
   python deployment/netbox/seed/seed_from_tf.py \
     --tf-json output/artifacts/inventories/*_tf_out_onprem_dev.json \
     --netbox-url $NETBOX_URL --token $NETBOX_TOKEN
   ```
3. **Switch Ansible Inventory to NetBox**
   ```bash
   ansible-inventory -i deployment/inventories/netbox/netbox.yml --graph
   ```

## Validation
- Inventory graph shows expected groups/hosts.
- Playbook run succeeds using NetBox inventory.

## Evidence Capture
- `output/logs/netbox/<ts>_seed_from_tf.log`
- `docs/proof/others/assets/<ts>_ansible_inventory_graph.txt`

_Last updated: 2025-10-05 01:47 UTC_
