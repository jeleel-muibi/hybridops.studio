# Evidence 3 – Source of Truth & Network Automation  
**HybridOps.Studio – NetBox, Inventory Flow, NETCONF & Nornir**

---

## Evidence Context

This document is **Evidence 3 of 5** for my UK Global Talent application (digital technology).

Evidence 1 focuses on **network architecture & connectivity**.  
Evidence 2 focuses on **WAN, edge, and hybrid connectivity**.  

This third evidence shifts the lens to **governance and automation**:

- NetBox as the **single source of truth (SoT)** for network and platform inventory.  
- A controlled **CSV + Terraform bridge** that keeps NetBox in sync with reality.  
- Nornir + NETCONF used for **network device automation and evidence capture**, separate from Ansible server config.  

It shows that the platform is not “just wired up” but **governed, modelled, and driven from a SoT** with repeatable automation.

---

## 1. Executive Summary

This evidence demonstrates how HybridOps.Studio treats **source of truth and automation** as first-class concerns:

- NetBox models **sites, VLANs, prefixes, devices, and interfaces** consistently with the ADRs.  
- A **single CSV file** acts as the hand-off point between Terraform and NetBox, avoiding drift and duplication.  
- Nornir + NETCONF use NetBox as inventory to configure and verify routers (CSR, VyOS) and firewalls.  
- Ansible remains focused on **server and platform configuration**, while Nornir handles **network devices and stateful checks**.  
- All automation runs through **version-controlled playbooks**, produces **structured logs**, and writes back **proof artefacts**.

For assessors, the key takeaway is: **the network is governed by data and automation**, not by ad‑hoc SSH sessions.

---

## 2. Architecture Overview

### 2.1 Source of Truth & Inventory Flow

At a high level:

> **Insert diagram:** `sot-inventory-flow.png`  
> Show:  
> **Terraform modules** → `terraform output` → **CSV bridge** → **NetBox** → **Nornir & Ansible inventory** → **Devices & VMs**.

The flow is:

1. **Terraform** provisions infrastructure (Proxmox VMs, IP allocations, VLAN IDs) using the IPAM strategy in ADR‑0104.  
2. A small script consumes `terraform output -json`, normalises selected fields, and **updates a single CSV file**:  
   `control/tools/inventory/netbox-bootstrap.csv`.  
3. A NetBox import job (or API script) reads this CSV and **creates/updates objects** (devices, IP addresses, interfaces).  
4. **NetBox becomes the SoT**. Nornir and Ansible read inventory from NetBox (via its API) and **never from hand-written host files**.  
5. Automation runs (Nornir/Ansible) push configuration and fetch state, saving logs to `docs/proof/**` for traceability.

This ensures that:

- There is **exactly one place to update** when infrastructure changes (Terraform state → CSV).  
- NetBox always has **fresh IP and device information**, even when VMs are reprovisioned.  
- All automation is anchored on the same SoT, reducing drift.

---

### 2.2 NetBox Data Model (Aligned with ADRs)

NetBox captures:

- **Sites / Locations** – on‑prem cluster, cloud regions, lab.  
- **VLANs & Prefixes** – mirroring ADR‑0101 VLAN ranges and ADR‑0104 IP allocations.  
- **Devices** – Proxmox nodes, routers, firewalls, observability VMs, Kubernetes nodes.  
- **Interfaces & IPs** – tagged with VLANs, roles (mgmt/uplink/loopback), and `environment` tags (dev/stage/prod/lab).  

> **Insert screenshot:** NetBox UI showing a sample device with:  
> - mgmt interface in VLAN 10,  
> - workload interfaces in VLAN 20/30/40,  
> - clear tagging (`role=edge`, `environment=prod`).

This is formalised in **ADR‑0002 – Source of Truth: NetBox‑Driven Inventory**, which explains:

- Why NetBox was chosen over flat files or spreadsheets.  
- How the NetBox schema aligns with the VLAN and routing ADRs.  
- How inventory is consumed by Ansible and Nornir.

---

### 2.3 Automation Layers: Ansible vs Nornir

The automation stack is intentionally split:

- **Ansible** focuses on **servers and platform services**:  
  - OS hardening and baseline.  
  - Installing and configuring Prometheus, Grafana, Jenkins, etc.  
  - Managing Proxmox host firewall rules where appropriate.

- **Nornir + NETCONF** focus on **network devices and stateful checks** (routers, firewalls):  
  - Pushing interface, BGP, IPsec, and VRRP configuration.  
  - Gathering structured state via NETCONF (YANG-based).  
  - Producing before/after diffs and XML/JSON evidence bundles.

NetBox sits in the middle:

> **Insert diagram:** `automation-layers.png`  
> NetBox API → Nornir inventory → Router playbooks / tasks  
> NetBox API → Ansible dynamic inventory → Server roles

---

## 3. Key Design Decisions (ADRs)

Short excerpts; full texts are on the docs site and in the repository.

- **ADR‑0001 – ADR Process & Conventions**  
  Governs how all architecture decisions (including SoT and automation) are recorded, linked, and updated.

- **ADR‑0002 – Source of Truth: NetBox‑Driven Inventory**  
  NetBox is the single source of truth for network inventory; automation must read from it, not from ad‑hoc files.

- **ADR‑0101 – VLAN Allocation Strategy**  
  VLANs, prefixes, and environment ranges that NetBox enforces as the canonical model.

- **ADR‑0104 – Static IP Allocation with Terraform IPAM**  
  IPs are allocated via Terraform IPAM, then exported and synced into NetBox via the CSV bridge.

- **ADR‑0602 – NETCONF and Nornir Automation for CSR1000v**  
  CSR routers expose NETCONF; Nornir orchestration collects config/state and ties it to evidence bundles.

(Where relevant, Evidence 1 & 2 show the **network side** of these ADRs; this evidence shows the **governance and automation side**.)

---

## 4. Implementation Highlights

### 4.1 CSV Bridge Between Terraform and NetBox

> **Insert code snippet:** from the CSV generation script (e.g. `control/tools/inventory/gen_netbox_csv.py`) showing:  
> - reading `terraform output -json`,  
> - mapping VMs, IPs, VLAN IDs into rows,  
> - writing to `netbox-bootstrap.csv`.

Key properties:

- **Single CSV file** – one controlled entry point, not a folder of hand-maintained spreadsheets.  
- Script is **idempotent** – re-running after a `terraform apply` refreshes IPs and device metadata.  
- CSV columns are aligned with NetBox’s import format (name, role, site, primary IP, tags, etc.).

> **Insert screenshot:** CSV preview in VS Code / editor, with rows for core router, edge firewalls, k3s nodes.

---

### 4.2 NetBox Import / API Sync

> **Insert snippet:** from a small helper script or job configuration, e.g. `control/tools/inventory/netbox_sync.py` or an import job definition.

The sync process:

1. Validate CSV headers against expected NetBox fields.  
2. Run NetBox’s bulk import (or API calls) to **create/update**:  
   - devices,  
   - interfaces,  
   - IP addresses,  
   - device roles / tags.  
3. Tag imported objects with a **sync batch ID** (e.g. `sync_2025-02-15T1200Z`) for traceability.

> **Insert screenshot:** NetBox “Change Log” / “Custom Field” indicating latest sync batch.

This proves that NetBox is not a static diagram; it is **kept in sync with the actual deployed state**.

---

### 4.3 Nornir + NETCONF Evidence Collection

> **Insert code snippet:** from a Nornir task, e.g. `core/automation/nornir/tasks/netconf_collect.py`:

- connecting to CSR1000v using NETCONF over SSH,  
- pulling `get-config` and selected `get` RPCs (e.g. interfaces, BGP neighbours),  
- writing XML/JSON payloads into `docs/proof/networking/netconf-csr1000v/`.

> **Insert screenshot:** directory listing or VS Code view for  
> `docs/proof/networking/netconf-csr1000v/`  
> showing files such as:  
> - `csr01-running-config.xml`  
> - `csr01-interfaces.xml`  
> - `csr01-bgp-neighbors.xml`  

This shows:

- Configuration and state are captured in **structured form**, not screenshots alone.  
- Each run can be tied back to a commit, a pipeline run, and a NetBox inventory snapshot.

---

### 4.4 Ansible Server Automation (Context Only)

> **Insert short Ansible snippet:** from a role such as `infra/ansible/roles/prometheus-node` or `infra/ansible/roles/proxmox-host-baseline`.

Purpose (only briefly, since there will be a dedicated automation evidence later):

- Demonstrate that **servers are also managed as code**, with roles driven by inventory tags (`environment`, `role`).  
- Show that NetBox tags map onto Ansible group variables (e.g. dev vs prod Prometheus scrape configs).

This connects the dots: **NetBox tags → automation targets → consistent behaviour across environments**.

---

## 5. Validation & Runbooks

### 5.1 End-to-End Inventory Sanity Check

> **Insert runbook excerpt:** from  
> `docs/runbooks/networking/netbox-inventory-sanity-check.md` (planned path) – or the closest existing runbook.

Checklist examples:

- “All Proxmox hosts appear in NetBox with mgmt IP in VLAN 10.”  
- “All CSR/VyOS routers have loopback addresses and correct edge tags (`role=edge`).”  
- “All k3s nodes have `environment` tags and IPs matching Terraform IPAM ranges.”  

> **Insert screenshot:** NetBox filter view for `role=edge` and `environment=prod`.

---

### 5.2 NETCONF / Nornir Health Checks

> **Insert CLI capture:** Nornir run output, showing tasks like:

- `netconf_get_config` → OK on csr01, csr02.  
- `netconf_check_bgp` → asserts neighbours are established.  

> **Insert snippet:** of XML or JSON from a NETCONF response where a BGP neighbour or interface is clearly visible and matches NetBox.

---

### 5.3 Drift Detection (Manual Demonstration)

> **Insert small scenario description + screenshots:**

1. Intentionally misconfigure an interface on a router.  
2. Run Nornir validation task; capture that the state no longer matches the desired profile.  
3. Fix via playbook, re‑run validation, and show “clean” output.

Store these artefacts under  
`docs/proof/networking/netconf-csr1000v/drift-demo/`.

This shows that the tooling is capable of **detecting and correcting drift**, not just pushing config.

---

## 6. Demo Video

> **Insert link:**  

- **Title:** “NetBox‑Driven Network Automation – Inventory to NETCONF Evidence”  
- **YouTube (or self-hosted) link:**  
  `[Video – NetBox + Nornir automation demo](https://www.youtube.com/watch?v=YOUR_VIDEO_ID)`  

The video walks through:

- Updating Terraform, regenerating the CSV, and syncing NetBox.  
- Browsing NetBox to show updated devices and IPs.  
- Running a Nornir job that pulls NETCONF state from CSR/VyOS and writes proof artifacts.  
- Briefly showing where these artefacts live in the repo and docs.

---

## 7. Links & Artefacts

### 7.1 Documentation (MkDocs)

- ADR – Source of Truth (NetBox):  
  [ADR‑0002 – Source of Truth: NetBox‑Driven Inventory](https://doc.hybridops.studio/adr/ADR-0002_source-of-truth_netbox-driven-inventory/)  

- NetBox inventory flow HOWTO:  
  [HOWTO – NetBox Inventory Flow](https://doc.hybridops.studio/howtos/networking/netbox-inventory-flow/)  

- NetBox on RKE2 with PostgreSQL LXC HOWTO:  
  [HOWTO – Deploy NetBox on RKE2 Using PostgreSQL LXC](https://doc.hybridops.studio/howtos/platform/netbox-rke2-postgresql-lxc/)  

NETCONF evidence HOWTO:  
  [HOWTO – Use Nornir to Collect NETCONF Evidence](https://doc.hybridops.studio/howtos/networking/nornir-netconf-evidence/)  

- End-to-end architecture validation HOWTO (context):  
  [HOWTO – Validate End-to-End Architecture](https://doc.hybridops.studio/howtos/networking/validate-end-to-end-architecture/)  

*(URLs are indicative; align with final MkDocs routing.)*

---

### 7.2 ADRs (Architecture Decisions)

- [ADR‑0001 – ADR Process & Conventions](https://doc.hybridops.studio/adr/ADR-0001_adr-process-and-conventions/)  
- [ADR‑0002 – Source of Truth: NetBox‑Driven Inventory](https://doc.hybridops.studio/adr/ADR-0002_source-of-truth_netbox-driven-inventory/)  
- [ADR‑0101 – VLAN Allocation Strategy](https://doc.hybridops.studio/adr/ADR-0101-vlan-allocation-strategy/)  
- [ADR‑0104 – Static IP Allocation with Terraform IPAM](https://doc.hybridops.studio/adr/ADR-0104-static-ip-allocation-terraform-ipam/)  
- [ADR‑0602 – NETCONF and Nornir Automation for CSR1000v](https://doc.hybridops.studio/adr/ADR-0602-netconf-nornir-csr1000v/)  

---

### 7.3 Repository References (Source Examples)

- CSV bridge script (example path):  
  `control/tools/inventory/gen_netbox_csv.py`  

- NetBox sync script / job:  
  `control/tools/inventory/netbox_sync.py`  

- Nornir tasks and config:  
  `core/automation/nornir/`  

- NETCONF proof artifacts:  
  `docs/proof/networking/netconf-csr1000v/`  

These are referenced descriptively in the PDF; assessors can explore the full implementation in the repository if desired.

---

**Owner:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation
