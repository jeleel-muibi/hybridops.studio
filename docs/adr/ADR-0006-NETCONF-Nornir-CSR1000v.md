---
id: ADR-0006
title: "NETCONF-Driven Network Management Using Cisco CSR1000v and Nornir"
status: Accepted
date: 2025-10-08
domains: ["networking", "automation", "observability"]
owners: ["jeleel"]
supersedes: []
superseded_by: []
links:
  prs: []
  runbooks: ["../runbooks/networking/netconf-csr1000v-setup.md"]
  evidence: ["../proof/networking/netconf-csr1000v/"]
  diagrams: ["../diagrams/netconf_csr_architecture.png"]
---

# ADR-0006 — NETCONF-Driven Network Management Using Cisco CSR1000v and Nornir

## Status
Accepted — Cisco CSR1000v routers are standardized as NETCONF-capable network endpoints for programmatic management, configuration validation, and evidence collection.

## Context
HybridOps.Studio requires a **reliable, auditable, and fully automated method** for managing hybrid network infrastructure spanning Proxmox, pfSense, and CSR routers.  
Manual SSH-based configuration and CLI scraping are error-prone and unsuitable for evidence-based automation pipelines.

NETCONF, a standard management protocol (RFC 6241), provides:
- Structured configuration and operational state retrieval (XML or YANG models).
- Transactional operations with rollback and validation.
- Consistent support across Cisco CSR, Arista vEOS, and Juniper vSRX.

Nornir’s native NETCONF driver allows multi-device orchestration, validation, and evidence capture at scale.  
Integrating it into the HybridOps pipeline bridges the gap between **declarative configs (Ansible)** and **state introspection (Nornir + NETCONF)**.

## Decision
Adopt **NETCONF over SSH** as the standard interface for router configuration, telemetry, and audit across all CSR1000v instances.  
Use **Nornir with Netmiko and ncclient** for automation and evidence correlation.

### Implementation Highlights
- **Transport:** NETCONF over SSH (port 830).
- **Schema:** Cisco native + OpenConfig YANG modules.
- **Automation Layer:** Nornir plugin (`netconf_collector`) to capture running-config and operational state.
- **Evidence Path:** `docs/proof/networking/netconf-csr1000v/` — contains XML outputs, config diffs, and YANG snapshots.

The workflow is triggered automatically by Jenkins or Ansible jobs and outputs structured proof artifacts tied to correlation IDs.

## Consequences
- ✅ Strong compliance and audit visibility (configurations are structured, verifiable XML).  
- ✅ Enables pre-/post-change validation directly from pipelines.  
- ✅ Extensible to other vendors supporting NETCONF/YANG.  
- ⚠️ Requires maintaining YANG model consistency across router images.  
- ⚠️ Slightly higher CPU overhead on virtual routers during schema parsing.

## References
- [Runbook: NETCONF Setup on CSR1000v](../runbooks/networking/netconf-csr1000v-setup.md)  
- [Diagram: NETCONF + Nornir Architecture](../diagrams/netconf_csr_architecture.png)  
- [Evidence: NETCONF State & Config Snapshots](../proof/networking/netconf-csr1000v/)  

---

**Author / Maintainer:** Jeleel Muibi  
**Project:** [HybridOps.Studio](https://github.com/jeleel-muibi/hybridops.studio)  
**License:** MIT-0 / CC-BY-4.0
