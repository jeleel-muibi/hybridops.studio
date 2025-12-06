# Evidence Slot 4 – Source of Truth & Automation (OC1)

> **Criteria:** Optional Criteria 1 (OC1) – innovation / significant technical contributions.  
> **Scope:** NetBox-based source of truth and multi-tool automation (Terraform, Ansible, Nornir) for HybridOps.Studio.  
> **Note (working copy only):** `[IMG-XX]` placeholders will be replaced with final diagrams and screenshots before submission.

---

## 1. Summary – NetBox-Driven Source of Truth & Automation Blueprint

This evidence shows how I designed and implemented a **NetBox-driven source of truth (SoT) and automation layer** for HybridOps.Studio.

The design treats NetBox as the **authoritative model** for:

- Sites, racks, devices and interfaces.  
- VLANs, prefixes and IP assignments.  
- Services, roles and tagging for automation intent.  

Terraform, Ansible and Nornir then consume this data to drive:

- Network configuration (for example, pfSense, switches).  
- Infrastructure provisioning (for example, Proxmox, RKE2 nodes).  
- Application placement and connectivity (for example, NetBox itself, observability tools).

This is documented in the **Source of Truth & NetBox Automation** evidence pack and related ADRs, HOWTOs and runbooks.

[IMG-01 – High-level diagram: NetBox at the centre, feeding Terraform/Ansible/Nornir and infra components – ~8 lines]

---

## 2. Problem & Context – From Static Configs to Data-Driven Infra

Without a source of truth, network and infrastructure configuration tends to drift:

- IP plans live in spreadsheets or people’s heads.  
- Firewall rules are copied around by hand.  
- New nodes are added without a clear view of dependencies.

For HybridOps.Studio to work as a **platform blueprint**, I needed:

- A **single place** where services, addresses and relationships are recorded.  
- A way for **automation tools to read that state** and apply changes consistently.  
- A pattern that could be adopted by **startups and engineering teams** who want to escape “spreadsheet networking”.

NetBox provides the data model; the automation stack turns it into real configuration.

---

## 3. Implementation – NetBox as the Source of Truth

### 3.1 Data model in NetBox

In HybridOps.Studio, NetBox is structured to represent:

- **Sites** – physical/logical locations (on-prem, cloud region, DR).  
- **Racks & devices** – Proxmox hosts, pfSense firewalls, switches, RKE2 nodes.  
- **Interfaces** – mapped to VLANs and IP addresses.  
- **Prefixes & IP addresses** – for management, workload, observability and edge subnets.  
- **Services & roles** – used to tag workloads (for example, “db-primary”, “dr-secondary”, “observability”, “edge-service”).

Custom fields and tags are used where needed to encode automation intent (for example, “include-in-dr”, “cost-sensitive”).

[IMG-02 – Screenshot of NetBox view showing a site with devices, interfaces and prefixes – ~6 lines]

### 3.2 Linking NetBox to automation tools

Automation tools integrate with NetBox via:

- **Terraform** – reading from NetBox to derive:
  - Addressing, VLAN assignments and interface parameters.  
  - Metadata for instances and network resources.  

- **Ansible** – using dynamic inventory from NetBox to:
  - Build host groups based on roles (for example, “rke2_controlplane”, “db_primary”, “edge_fw”).  
  - Apply playbooks to the right scope.

- **Nornir** – for network-specific tasks, using NetBox as the backend inventory.

[ART-01 – Small snippet of Terraform or Ansible code using NetBox data (redacted) – ~6 lines]

This means that when I change something in NetBox:

- The **data model** is updated first.  
- Automation then **pulls from NetBox** and applies changes, rather than making one-off edits directly to devices.

---

## 4. Examples of NetBox-Driven Automation

### 4.1 Provisioning RKE2 nodes and db-01

When provisioning RKE2 nodes and the `db-01` PostgreSQL LXC, NetBox provides:

- The IP ranges for management and workload VLANs.  
- The roles for each node (control-plane, worker, database).  
- The associations to sites and racks.

Terraform and Ansible then use this to:

- Create Proxmox VMs/LXCs with the correct IPs and VLANs.  
- Install and configure RKE2.  
- Attach db-01 to the right storage and networks.

[IMG-03 – Screenshot/diagram showing NetBox objects for RKE2 nodes and db-01 – ~6 lines]

### 4.2 Network configuration via SoT

For network devices (for example, pfSense and switches):

- NetBox holds:
  - VLAN definitions and descriptions.  
  - IP addresses for router interfaces.  
  - Expected relationships between subnets and services.

Nornir and/or Ansible playbooks then:

- Generate configuration snippets based on NetBox data.  
- Push those configs to devices in a controlled manner.  
- Optionally record the changes and resulting state in evidence folders.

[IMG-04 – Screenshot of pfSense config view and related NetBox VLAN/prefix entries – ~6 lines]

This keeps the **network config tied to an explicit model**, not just CLI history.

---

## 5. Integration with Evidence, ADRs and Runbooks

### 5.1 ADRs – SoT & automation decisions

The SoT and automation approach is captured in:

- ADRs that define:
  - NetBox as the authoritative SoT for network and infra.  
  - The split of responsibilities between Terraform, Ansible and Nornir.  
  - How SoT is used in DR and cost-aware workflows.

Each ADR links to:

- Relevant HOWTOs (for example, “Populate NetBox for a new environment”).  
- Runbooks (for example, “Recover from SoT drift or incorrect entries”).  
- Evidence directories with automation logs and artefacts.

[IMG-05 – Screenshot of ADR list filtered for SoT/NetBox/automation – ~6 lines]

### 5.2 HOWTOs & runbooks

Key supporting documents include:

- HOWTOs:
  - How to onboard a new environment into NetBox.  
  - How to model new services and roles for automation.  

- Runbooks:
  - What to do when NetBox and reality diverge (SoT drift).  
  - How to safely correct SoT entries and re-run automation.

This helps turn the SoT design into **operational practice**, not just a diagram.

---

## 6. Innovation & Reusability

The SoT and automation work in HybridOps.Studio is innovative beyond basic “I installed NetBox” in several ways:

- It treats NetBox as the **centre of gravity** for network and infrastructure state, with automation tools as consumers of that model.  
- It uses a **multi-tool automation stack** (Terraform, Ansible, Nornir) that each draw from the same SoT, rather than having separate, conflicting inventories.  
- It ties SoT directly into:
  - Hybrid networking (VLANs, IPsec edges).  
  - Platform provisioning (RKE2, db-01, Proxmox).  
  - DR and cost-aware workflows (tagging which services are DR-eligible or cost-sensitive).

[IMG-06 – Optional collage: NetBox UI, Terraform/Ansible snippet, infra diagram – ~6 lines]

As a blueprint, it is reusable for:

- Teams that want to adopt NetBox as a SoT without creating an over-complicated model.  
- Startups that want a **pragmatic, automation-friendly SoT** for hybrid infrastructure.  
- Teaching labs within HybridOps Academy, where learners can see SoT-driven automation in action.

---

## 7. How This Meets Optional Criteria 1 (Innovation)

This evidence supports Optional Criteria 1 by showing that I have:

- Designed and implemented a **NetBox-based source of truth** that drives real network and infrastructure automation.  
- Integrated multiple automation tools around a single data model instead of creating fragmented inventories.  
- Documented the approach through evidence packs, ADRs, HOWTOs and runbooks so that other engineers can understand, validate and reuse it as a pattern.

It demonstrates that I can think beyond individual scripts and instead **architect and operate a reusable SoT + automation blueprint** suitable for modern platform, SRE and networking work.

---

**Context & navigation**

For easier cross-referencing, this PDF is mirrored on the [HybridOps.Studio documentation portal](https://docs.hybridops.studio) and linked from the [Tech Nation assessors’ guide](https://docs.hybridops.studio/briefings/gtv/how-to-review/). The docs site adds navigation only, not new evidence.
