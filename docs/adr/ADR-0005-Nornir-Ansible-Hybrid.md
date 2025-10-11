---
id: ADR-0005
title: "Use Nornir for Network Automation and Ansible for Server Automation"
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

# Use Nornir for Network Automation and Ansible for Server Automation

## Context
HybridOps.Studio requires automation for both network devices (CSR1000v, VyOS, pfSense, Arista vEOS) and servers (Windows, Linux). A single tool could simplify the stack, but network automation often demands protocol-level control and high concurrency, while server automation benefits from mature ecosystems and orchestration features.

## Decision
Adopt a hybrid approach:
- **Nornir** for network automation tasks (configuration, validation, inventory sync).
- **Ansible** for server provisioning and configuration (Windows roles, clustering, SCCM).

## Consequences
- Positive impacts:
  - Each tool is used where it excels.
  - Demonstrates enterprise realism and tool specialization.
- Risks and mitigations:
  - Two automation stacks increase complexity; mitigated by clear documentation and CI/CD integration.
- Ops/cost considerations:
  - Both tools are open-source; minimal cost impact.
- Rollback strategy:
  - If complexity is too high, fallback to Ansible-only approach for all automation.

## Alternatives Considered
- **Ansible for all automation**:
  - Pros: Single tool, simpler learning curve.
  - Cons: Slower for network tasks, less flexible for CLI parsing.
- **Nornir for all automation**:
  - Pros: Python-native, fast.
  - Cons: Limited ecosystem for Windows automation.

## Verification / Test Matrix
- Nornir successfully configures switches, routers, firewall via NETCONF/SSH.
- Ansible provisions Windows servers and applies roles via playbooks.
- NetBox inventory feeds both tools dynamically.

## References
- https://nornir.readthedocs.io
- https://docs.ansible.com
