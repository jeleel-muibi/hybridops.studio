---
id: ADR-008
title: "Use NETCONF with Nornir for CSR1000v Network Automation"
status: Accepted
date: 2025-10-08
domains: ["networking"]
owners: [jeleel-dev]
supersedes: []
superseded_by: []
links:
  prs: []
  runbooks: []
  evidence: []
  diagrams: []
---

# Use NETCONF with Nornir for CSR1000v Network Automation

## Context
HybridOps.Studio includes automation of network devices such as CSR1000v. While CLI-based automation via SSH is common, CSR1000v supports NETCONF natively, enabling structured, model-driven configuration using YANG models. Nornir is a Python-native automation framework that integrates well with NETCONF libraries like `scrapli_netconf` and `ncclient`. This ADR evaluates the decision to use NETCONF with Nornir for CSR1000v automation.

## Decision
We will use NETCONF with Nornir to automate CSR1000v devices. This approach leverages CSR1000v's native NETCONF support and Nornir's Pythonic orchestration capabilities. It enables structured configuration, better error handling, and integration with NetBox as a source of truth. The scope is limited to CSR1000v devices within the lab and staging environments.

## Consequences
- Positive impacts:
  - Enables structured, model-driven automation using YANG.
  - Improves performance and control via Python-native orchestration.
  - Aligns with enterprise-grade practices for network automation.
- Risks and mitigations:
  - Requires enabling NETCONF on CSR1000v (`netconf-yang` command).
  - Requires installation and testing of NETCONF libraries (`scrapli_netconf`, `ncclient`).
- Ops/cost considerations:
  - Minimal operational overhead; libraries are lightweight and open-source.
- Rollback strategy:
  - Fall back to CLI-based automation via SSH if NETCONF fails or is unsupported.

## Alternatives Considered
- **Ansible NETCONF modules**
  - Pros: Familiar syntax, existing playbooks.
  - Cons: Less flexible, slower execution, limited error handling.
- **CLI-based SSH automation**
  - Pros: Simple and widely supported.
  - Cons: Unstructured, harder to validate, less scalable.

## Verification / Test Matrix (optional)
- CSR1000v responds to NETCONF queries using `scrapli_netconf`.
- Configuration changes applied via NETCONF are reflected in device state.
- NetBox inventory is used to dynamically target CSR1000v devices via Nornir.

## References
- https://developer.cisco.com/docs/ios-xe/#!netconf/overview
- https://nornir.readthedocs.io
- https://github.com/carlmontanari/scrapli_netconf
