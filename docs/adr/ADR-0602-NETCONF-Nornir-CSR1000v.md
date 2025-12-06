---
id: ADR-0602
title: "NETCONF and Nornir Automation for CSR1000v"
status: Accepted
date: 2025-11-30

category: "06-ci-cd-automation"
supersedes: []
superseded_by: []

links:
  prs: []
  runbooks: []
  howtos: []
  evidence: []
  diagrams: []

draft: false
tags: ["netconf", "nornir", "csr1000v", "network-automation"]
access: public
---

# NETCONF and Nornir Automation for CSR1000v

## Status

Accepted — Cisco CSR1000v routers are standardized as NETCONF-capable network endpoints for programmatic management, configuration validation, and evidence collection.

## Context

HybridOps.Studio requires a reliable, auditable, and fully automated method for managing hybrid network infrastructure spanning Proxmox, pfSense, and CSR routers.  
Manual SSH-based configuration and CLI scraping are error-prone and unsuitable for evidence-based automation pipelines.

NETCONF (RFC 6241) provides:

- Structured configuration and operational state retrieval (XML/YANG).
- Transactional operations with validation and rollback.
- Consistent support across Cisco CSR, Arista vEOS, and Juniper vSRX.

Nornir’s NETCONF/SSH capabilities allow:

- Multi-device orchestration.
- Pre-/post-change validation.
- Evidence capture at scale.

This ADR complements the higher-level decision to use Nornir alongside Ansible for hybrid automation (see ADR-0601 when introduced).

## Decision

Adopt **NETCONF over SSH** as the standard interface for configuration, telemetry, and audit for all CSR1000v instances.  
Use **Nornir with Netmiko and ncclient** as the primary automation stack for:

- Pushing configuration changes.
- Validating operational state.
- Capturing structured evidence (XML/YANG) into proof artefacts.

### Implementation Highlights

- **Transport:** NETCONF over SSH on port `830`.
- **Schema:** Cisco native + OpenConfig YANG models where available.
- **Automation layer:** Nornir tasks (for example `netconf_get`, `netconf_edit_config`) wrapped in a `netconf_collector` plugin to:
  - Capture `running-config`.
  - Snapshot operational state (interfaces, BGP, IPsec).
  - Store artefacts under `docs/proof/networking/netconf-csr1000v/` with correlation IDs.
- **Pipeline integration:**  
  - Jenkins / Ansible triggers Nornir runs as part of change workflows.  
  - Pre-change snapshot, change execution, post-change snapshot, diff, and result published as evidence.

## Consequences

### Positive

- Strong compliance and audit visibility via structured, machine-parsable configuration/state.
- Enables pre-/post-change validation directly from CI/CD pipelines.
- Extensible to other vendors that support NETCONF/YANG (Arista, Juniper, VyOS with YANG).
- Reduces reliance on brittle screen-scraping and ad-hoc SSH sessions.

### Negative

- Requires maintaining compatible YANG model versions across CSR images.
- NETCONF/YANG parsing adds CPU overhead on virtual routers during heavy automation runs.
- Engineers must be familiar with YANG paths and NETCONF RPC patterns.

### Neutral

- Coexists cleanly with Ansible (declarative config push) and Nornir (state introspection).
- Can later be augmented with gNMI/RESTCONF without breaking existing pipelines.

## Planned artefacts

These paths are reserved for implementation once automation and evidence capture are in place:

- Runbook: `docs/runbooks/networking/netconf-csr1000v-setup.md`
- Diagram: `docs/diagrams/netconf_csr_architecture.mmd`
- Evidence root: `docs/proof/networking/netconf-csr1000v/`

## References

- [ADR-0102 – Proxmox as Intra-Site Core Router](../adr/ADR-0102-proxmox-intra-site-core-router.md)
- [ADR-0106 – Dual ISP Load Balancing for Resiliency](../adr/ADR-0106-dual-isp-load-balancing-resiliency.md)
- [ADR-0107 – VyOS as Cost-Effective Edge Router](../adr/ADR-0107-vyos-edge-router.md)
- [ADR-0201 – EVE-NG Network Lab Architecture](../adr/ADR-0201-eve-ng-network-lab-architecture.md)
- [ADR-0601 – Nornir + Ansible Hybrid Automation](../adr/ADR-0601-nornir-ansible-hybrid-automation.md)

---

**Maintainer:** HybridOps.Studio
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
