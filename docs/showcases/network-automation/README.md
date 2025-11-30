---
title: "Showcase – Network Automation at Scale"
category: "showcase"
summary: "Network automation patterns combining declarative Ansible and programmatic Nornir with CI/CD and lab topologies."
difficulty: "Intermediate"

topic: "showcase-network-automation"

video: "https://www.youtube.com/watch?v=NETWORK_AUTOMATION_DEMO"
source: "https://github.com/hybridops-studio/hybridops-studio"

draft: false
is_template_doc: false
tags: ["showcase", "portfolio", "network-automation"]

audience: ["network engineers", "learners"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# Network Automation at Scale

## Executive summary

This showcase demonstrates network automation for hybrid and lab environments using:

- Declarative Ansible playbooks for repeatable changes.
- Programmatic Nornir workflows for more complex logic and testing.
- CI/CD integration for linting, dry-runs and safe rollouts.
- EVE-NG topologies for realistic but contained lab scenarios.

The focus is on patterns that transfer cleanly from lab to production networks.

---

## Case study – how this was used in practice

- **Context:** Multi-vendor network lab built on EVE-NG, with a requirement to show both breadth (many devices) and depth (safe changes, tests).

- **Challenge:** Manual CLI changes were slow, error-prone and hard to audit or repeat.

- **Approach:** Introduced a layered automation approach:
  - Ansible for standardised changes (interfaces, routing, BGP, ACLs).
  - Nornir for more advanced flows (tests, data collection, conditional logic).
  - CI/CD integration to validate changes before touching the lab.

- **Outcome:** Faster, safer iterations in the lab, repeatable demos, and patterns ready to map into real enterprise networks.

Related decisions (for example):

- [ADR-00XX – Network Automation Strategy](../../adr/ADR-00XX-network-automation-strategy.md)

---

## Demo

### Video walkthrough

- Video: https://www.youtube.com/watch?v=NETWORK_AUTOMATION_DEMO  

The demo highlights:

1. A change defined in Ansible inventory and playbooks.
2. Automated validation using Nornir tasks and tests.
3. Safe rollout across lab devices in an EVE-NG topology.
4. Evidence capture (pre/post state, diffs, logs).

### Screenshots

```markdown
![EVE-NG topology](./diagrams/eveng-topology.png)
![Ansible run](./screenshots/ansible-run.png)
```

---

## Architecture

- High-level diagram:

  ```markdown
  ![Network automation architecture](./diagrams/architecture-overview.png)
  ```

- Key components:
  - **EVE-NG** with multiple lab topologies (for example core and branch variants).
  - **Ansible** for declarative configuration.
  - **Nornir** for programmatic workflows and tests.
  - **CI/CD** for running checks on playbooks and Nornir tasks.

Optional detailed diagrams:

- [Topology – core/branch labs](./diagrams/topology-core-branch.png)
- [Automation flow](./diagrams/automation-flow.png)

---

## Implementation highlights

- Use of inventories to represent multiple labs and device roles.
- Safe patterns for pushing config, including diffs and dry-run support where possible.
- Programmatic tests (for example reachability, BGP sessions, interface state) expressed in Python via Nornir.
- Evidence captured for each run under an `evidence/` tree, suitable for later review or audits.

---

## Assets and source

- GitHub folder for this showcase:  
  https://github.com/hybridops-studio/hybridops-studio/tree/main/showcases/network-automation

- Automation code:
  - `showcases/network-automation/declarative-ansible/`
  - `showcases/network-automation/programmatic-nornir/`
  - `showcases/network-automation/jenkins-pipeline/`

- Topologies:
  - `showcases/network-automation/topologies/` – EVE-NG definitions and diagrams.

- Evidence:
  - `./evidence/` – logs, outputs and screenshots from automation runs.

---

## Academy track (if applicable)

In the Academy, this showcase can be expanded into a set of labs where learners:

- Build a simple playbook and roll it out safely.
- Implement a Nornir-based validation flow.
- Compare manual vs automated approaches in terms of time and reliability.

---

## Role-based lens (optional)

- **Network Engineer:** sees practical paths to move from manual CLI to automation.
- **Platform / SRE:** sees how network changes can be integrated into broader CI/CD practices.
- **Engineering Manager / Hiring Manager:** sees that automation is approached in a safe, testable and auditable way.

---

## Back to showcase catalogue

- [Back to all showcases](../000-INDEX.md)
