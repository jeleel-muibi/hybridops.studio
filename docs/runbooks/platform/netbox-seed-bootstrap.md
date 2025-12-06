---
title: "NetBox Initial Seed & Bootstrap"
category: "bootstrap"
summary: "Bring a fresh NetBox instance to a minimal, usable source-of-truth state for HybridOps.Studio."
severity: "P2"

topic: "netbox-bootstrap"

draft: false
tags: ["netbox", "source-of-truth", "inventory", "bootstrap"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# NetBox Initial Seed & Bootstrap

**Purpose:** Initialise a new NetBox instance with the minimum objects required to act as the source of truth for HybridOps.Studio (sites, VLANs, prefixes, device roles, core devices, and an API token for automation).  
**Owner:** Platform / Network Engineering  
**Trigger:** Fresh NetBox deployment or destructive reset of the NetBox database.  
**Impact:** Until this runbook completes, Ansible / Nornir inventories that depend on NetBox are incomplete or unusable.  
**Severity:** P2  
**Pre-reqs:** NetBox deployed and reachable over HTTPS, admin credentials available, ADR-0002 agreed as baseline, network architecture documented.  
**Rollback strategy:** Delete seeded objects (sites, VLANs, prefixes, devices) or restore NetBox database from snapshot.

---

## Quick Checklist

- [ ] Confirm NetBox is reachable and admin login works.  
- [ ] Create core “HybridOps” tenant and primary site.  
- [ ] Create VLANs and prefixes as per ADR-0101.  
- [ ] Create core device roles (hypervisor, router, firewall, k8s-node).  
- [ ] Onboard Proxmox host, pfSense, CSR/VyOS and EVE-NG as devices.  
- [ ] Generate API token for automation and store it in secrets backend.  
- [ ] Run inventory export job and verify Ansible / Nornir inventories.

---

## Preconditions & Safety Checks

- NetBox version is supported by your NetBox plugins / exporters.  
- You can log in with an admin account.  
- Database and Redis are healthy (no errors in NetBox admin UI or logs).  
- You have the current IP plan and VLAN map (see ADR-0101 and network-architecture doc).

**Sanity check – reachability:**

```bash
curl -k https://netbox.example.local/health
# Expect: HTTP 200 with health JSON or NetBox login redirect
```

If NetBox is not reachable, fix deployment issues before continuing.

---

## Step 1 – Create Tenant and Site

**Goal:** Give all objects a consistent tenancy and physical/site context.

1. Log in to NetBox with an admin account.
2. Navigate: **Organization → Tenants → Add** and create:

   - **Name:** `HybridOps.Studio`  
   - **Slug:** `hybridops`  

3. Navigate: **Organization → Sites → Add** and create:

   - **Name:** `HOS-Onprem-1`  
   - **Slug:** `hos-onprem-1`  
   - **Tenant:** `HybridOps.Studio`  
   - **Status:** `Active`

Minimal verification:

- Tenant `HybridOps.Studio` exists.  
- Site `HOS-Onprem-1` exists and is linked to that tenant.

---

## Step 2 – Seed VLANs

**Goal:** Mirror ADR-0101 so VLAN IDs and purposes are consistent everywhere.

Navigate to **IPAM → VLANs → Add** and create:

| VLAN ID | Name          | Role         |
|--------:|---------------|--------------|
| 10      | mgmt          | Management   |
| 11      | observability | Observability|
| 20      | dev           | Development  |
| 30      | staging       | Staging      |
| 40      | prod          | Production   |
| 50      | lab           | Lab/Testing  |

For each VLAN:

- **Site:** `HOS-Onprem-1`  
- **Tenant:** `HybridOps.Studio`  
- **Status:** `Active`  

Verification:

- IPAM → VLANs shows IDs 10, 11, 20, 30, 40, 50 with correct names and site.

---

## Step 3 – Seed Prefixes (Subnets)

**Goal:** Define the Layer-3 space per VLAN so NetBox becomes the IPAM of record.

Navigate to **IPAM → Prefixes → Add** and create:

| Prefix        | Role          | VLAN |
|---------------|---------------|------|
| 10.10.0.0/24  | mgmt          | 10   |
| 10.11.0.0/24  | observability | 11   |
| 10.20.0.0/24  | dev           | 20   |
| 10.30.0.0/24  | staging       | 30   |
| 10.40.0.0/24  | prod          | 40   |
| 10.50.0.0/24  | lab           | 50   |

For each prefix:

- **Status:** `Active`  
- **Tenant:** `HybridOps.Studio`  
- **Site:** `HOS-Onprem-1`  
- **VLAN:** link to corresponding VLAN (10, 11, 20, 30, 40, 50).  

Optional but recommended:

- Mark `.1` addresses (10.x.0.1) as “Gateway” IPs.

---

## Step 4 – Define Core Device Roles and Platforms

**Goal:** Allow consistent filtering and automation by role/platform.

Navigate to **Devices → Device Roles → Add**:

Create roles such as:

- `hypervisor` (color: any)  
- `router`  
- `firewall`  
- `k8s-node`  
- `netlab` (EVE-NG, lab appliances)

Then navigate to **Devices → Platforms → Add**:

- `proxmox-ve`  
- `pfsense`  
- `csr1000v`  
- `vyos`  
- `eve-ng`  

Ensure:

- Each role is marked **VM Role** or **Device Role** as appropriate.  
- Each platform has a sensible **Slug** (`proxmox-ve`, `csr1000v`, etc.).

---

## Step 5 – Onboard Core Devices

**Goal:** Create device records for the critical infrastructure nodes.

Navigate to **Devices → Devices → Add** and create, for example:

1. **Proxmox Host**

   - **Name:** `pve-01`  
   - **Device Role:** `hypervisor`  
   - **Platform:** `proxmox-ve`  
   - **Site:** `HOS-Onprem-1`  
   - **Status:** `Active`  

2. **Firewall (pfSense)**

   - **Name:** `fw-01`  
   - **Device Role:** `firewall`  
   - **Platform:** `pfsense`  
   - **Site:** `HOS-Onprem-1`  

3. **Edge Router (CSR1000v)**

   - **Name:** `edge-csr-01`  
   - **Device Role:** `router`  
   - **Platform:** `csr1000v`  
   - **Site:** `HOS-Onprem-1`  

4. **Lab Router (VyOS)**

   - **Name:** `edge-vyos-01`  
   - **Device Role:** `router`  
   - **Platform:** `vyos`  
   - **Site:** `HOS-Onprem-1`  

5. **EVE-NG**

   - **Name:** `eve-ng-01`  
   - **Device Role:** `netlab`  
   - **Platform:** `eve-ng`  
   - **Site:** `HOS-Onprem-1`  

(Adapt the exact names to your real lab.)

Minimal verification:

- All devices appear under the correct site and tenant.  
- Roles and platforms are correctly assigned.

---

## Step 6 – Create Automation User and API Token

**Goal:** Allow export tools (Ansible / Nornir inventory jobs) to query NetBox.

1. In NetBox: **Admin → Users → Add**:

   - **Username:** `svc-netbox-automation`  
   - **Is staff:** enabled (if needed for API access)  
   - **Is superuser:** *avoid if possible*; instead grant appropriate permissions (view objects).  

2. Assign this user a “read-only inventory” permission set (or group) covering:

   - Tenants, sites, VLANs, prefixes  
   - Devices, device roles, platforms, IP addresses  

3. Navigate: **User → API Tokens → Add Token**:

   - **User:** `svc-netbox-automation`  
   - **Key:** auto-generated  
   - **Write-enabled:** only if you expect automation to write; otherwise read-only.  

4. Copy the token value once and store it in your secrets system:

   - Azure Key Vault / SOPS / `.env` (if in homelab only, never committed).  

Example `.env` entry (for local dev only):

```bash
NETBOX_API_URL="https://netbox.example.local"
NETBOX_API_TOKEN="***REDACTED***"
```

---

## Step 7 – Trigger Inventory Export

**Goal:** Prove NetBox can drive inventories for Ansible / Nornir.

From your control node (e.g. `ctrl-01`):

```bash
cd /path/to/hybridops-studio/control/tools/inventory

# Example: export NetBox → Ansible/Nornir inventory
./netbox_export_inventory.sh   --url "$NETBOX_API_URL"   --token "$NETBOX_API_TOKEN"   --out-ansible "../../infra/ansible/inventory/netbox_hosts.yaml"   --out-nornir "../../infra/nornir/inventory/netbox_inventory.yaml"
```

(Adapt to your actual script / Make target when those are in place.)

Verification:

- Ansible inventory file exists and contains your devices.  
- Nornir inventory file exists and contains your devices.  

Spot-check:

```bash
ansible-inventory -i infra/ansible/inventory/netbox_hosts.yaml --graph
```

and/or:

```bash
python -c 'from nornir import InitNornir; n=InitNornir(config_file="infra/nornir/config.yaml"); print(n.inventory.hosts.keys())'
```

---

## Verification

Run this mini checklist at the end:

- [ ] VLANs and prefixes in NetBox match ADR-0101 and `network-architecture.md`.  
- [ ] Core devices (Proxmox, firewall, edge routers, EVE-NG) are present in NetBox with correct roles/platforms.  
- [ ] Automation service account and token exist, and are stored in secrets.  
- [ ] At least one Ansible / Nornir inventory export from NetBox has succeeded.  
- [ ] Subsequent changes (e.g. adding a device) flow from NetBox into exported inventories.

If any of these fail, **stop** and correct NetBox before allowing pipelines to rely on it.

---

## References

- [ADR-0002 – Source of Truth: NetBox-Driven Inventory](../../adr/ADR-0002_source-of-truth_netbox-driven-inventory.md)  
- [ADR-0101 – VLAN Allocation Strategy](../../adr/ADR-0101-vlan-allocation-strategy.md)  
- [Network Architecture](../../prerequisites/network-architecture.md)  
- [Evidence](docs/proof/platform/netbox-bootstrap)

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
