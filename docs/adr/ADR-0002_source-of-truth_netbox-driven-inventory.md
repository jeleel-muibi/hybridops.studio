---
id: ADR-0002
title: "Source of Truth: NetBox-Driven Inventory"
status: Accepted
date: 2025-10-06
domains: ["platform", "infra", "governance"]
supersedes: []
superseded_by: []
links:
  prs: []
  runbooks: ["../runbooks/bootstrap/netbox-seed.md"]
  evidence: ["../proof/netbox/"]
  diagrams: ["../diagrams/netbox_sot_overview.png"]
---

# Source of Truth: NetBox-Driven Inventory

## Status
Accepted — NetBox is the single source of truth (SoT) for infrastructure topology, device metadata, and automation inventory.

## Context
The automation framework needs a consistent and authoritative way to represent on-premises and cloud resources.  
Static Ansible inventories quickly diverge from reality as clusters evolve. Manual synchronization leads to drift and inconsistent DR state.

A **Source of Truth (SoT)** ensures:
- Consistency between operational state, IaC definitions, and observability.  
- Multi-environment visibility (dev, staging, prod).  
- Foundation for zero-touch provisioning and dynamic automation.

## Decision
Adopt **NetBox** as the **central SoT**, integrated into automation via its REST API and Python client.  

All inventory data (sites, devices, IPs, VLANs, services) will be **authored in NetBox** and pulled dynamically by:
- **Ansible** (via dynamic inventory plugin)  
- **Terraform** (via provider plugin for dependencies and external data)  
- **Custom tooling** (e.g., Ansible-Nornir hybrid sync jobs)

Key principles:
- **Authoritative upstream:** NetBox holds truth; code pulls from it.  
- **Bidirectional traceability:** Every Ansible play links to the corresponding NetBox object.  
- **Evidence alignment:** Provisioning logs and topology diagrams link back to NetBox records.

## Options Considered

- **Static YAML / INI inventories** — rejected due to duplication and drift risk.  
- **Custom CMDB in SQL or Git** — overly complex to maintain.  
- **NetBox** — purpose‑built, API‑driven, and widely adopted. **Chosen.**

## Consequences
- Simplifies DR and replication across clouds.  
- Reduces misconfiguration risk from outdated host definitions.  
- Adds a dependency (NetBox uptime, data model accuracy).  
- Requires discipline in modeling before provisioning.

## References
- [Runbook: NetBox Seed & Bootstrap](../runbooks/bootstrap/netbox-seed.md)  
- [Diagram: NetBox SoT Overview](../diagrams/netbox_sot_overview.png)  
- [Proof: NetBox Bootstrap Logs](../proof/netbox/)  

---

**Maintainer:** HybridOps.Studio
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
