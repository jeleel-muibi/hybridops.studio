---
id: ADR-0005
title: "Hybrid Network Automation: Nornir + Ansible Integration"
status: Accepted
date: 2025-10-08
domains: ["automation", "networking", "platform"]
owners: ["jeleel"]
supersedes: []
superseded_by: []
links:
  prs: []
  runbooks: ["../runbooks/networking/nornir-ansible-integration.md"]
  evidence: ["../proof/networking/nornir-ansible-interop/"]
  diagrams: ["../diagrams/nornir_ansible_integration.png"]
---

# ADR-0005 — Hybrid Network Automation: Nornir + Ansible Integration

## Status
Accepted — Nornir and Ansible are combined as a unified automation stack for both **network** and **infrastructure orchestration**, balancing flexibility and governance.

## Context
HybridOps.Studio manages both compute (VMs, Kubernetes nodes, cloud resources) and traditional network infrastructure (Cisco CSR1000v, Arista vEOS, pfSense).  
While Ansible provides excellent orchestration and idempotency for host-level configuration, it is not ideal for concurrent, connection-aware device automation at scale.

Nornir offers:
- Python-native execution and granular concurrency.
- Low-level control over connections (SSH/Netmiko/NAPALM).
- Dynamic inventory loading compatible with Ansible’s YAML structure.

Combining both enables:
- Unified inventory (NetBox → dynamic generator → YAML).
- Seamless orchestration pipelines — Ansible drives hosts; Nornir drives network fabric.
- Evidence collection and correlation under one workflow.

## Decision
Adopt a **hybrid model** where:
- **Ansible** remains the primary orchestrator for servers, agents, and Kubernetes components.
- **Nornir** executes network-specific tasks such as configuration diff, compliance validation, and connectivity testing.
- Shared inventories and credential sources are generated from a **NetBox-backed Source of Truth**.
- Jenkins pipelines orchestrate both stacks with evidence emission and rollback capabilities.

### Integration Highlights
- Single YAML inventory structure shared between both tools.
- Nornir plugins (`env_guard`, `connectivity_test`) integrated into CI pipelines.
- Evidence logs stored in `/docs/proof/networking/nornir-ansible-interop/`.

## Consequences
- ✅ Improved parallelism for network automation workloads.  
- ✅ Unified audit trail for hybrid operations.  
- ⚠️ Slightly more complexity in CI/CD pipelines due to mixed tool orchestration.  
- ⚠️ Requires Python dependencies (Nornir, Netmiko, Napalm) to be preinstalled in the automation control plane.

## References
- [Runbook: Nornir + Ansible Integration](../runbooks/networking/nornir-ansible-integration.md)  
- [Diagram: Nornir–Ansible Interoperability](../diagrams/nornir_ansible_integration.png)  
- [Evidence: Proof Logs and Compliance Diffs](../proof/networking/nornir-ansible-interop/)  

---

**Author / Maintainer:** Jeleel Muibi  
**Project:** [HybridOps.Studio](https://github.com/jeleel-muibi/hybridops.studio)  
**License:** MIT-0 / CC-BY-4.0
