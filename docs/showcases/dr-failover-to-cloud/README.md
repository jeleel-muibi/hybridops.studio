---
title: "Showcase – DR Failover to Cloud"
category: "showcase"
summary: "Hybrid DR pattern that fails workloads from on-prem to cloud with DNS-driven cutover and warm standby."
difficulty: "Intermediate"

topic: "showcase-dr-failover-to-cloud"

video: "https://www.youtube.com/watch?v=DR_FAILOVER_DEMO"
source: "https://github.com/hybridops-studio/hybridops-studio"

draft: false
is_template_doc: false
tags: ["showcase", "portfolio", "dr", "hybrid-cloud"]

audience: ["hiring-managers", "cloud-native"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""
---

# DR Failover to Cloud

## Executive summary

This showcase demonstrates a practical disaster recovery (DR) pattern where:

- Primary workloads run on-prem in a Proxmox / Kubernetes environment.
- A warm standby environment exists in the cloud.
- Controlled DNS cutover is used to switch traffic during an incident.
- Evidence is captured for both failover and failback.

The goal is to show a realistic, cost-aware DR approach suitable for SMEs and larger environments.

---

## Case study – how this was used in practice

- **Context:** Hybrid lab environment used to rehearse DR scenarios and support portfolio evidence.
- **Challenge:** Show a DR strategy that is realistic, testable and not purely theoretical.
- **Approach:** Built a minimal viable DR pattern: warm standby in cloud, DNS-based cutover, and explicit runbooks for failover/failback.
- **Outcome:** Clear, repeatable DR steps with artefacts suitable for auditors, assessors and engineering leaders.

Related decisions (for example):

- [ADR-00XX – DR Strategy and Cloud Failover](../../adr/ADR-00XX-dr-failover-strategy.md)
- [ADR-00YY – DNS as Control Plane for DR](../../adr/ADR-00YY-dns-dr-control-plane.md)

---

## Demo

### Video walkthrough

- Video: https://www.youtube.com/watch?v=DR_FAILOVER_DEMO  

The demo walks through:

1. Normal operation with on-prem environment serving traffic.
2. Simulated incident impacting on-prem services.
3. DNS cutover to the cloud environment.
4. Validation of application health and data paths in the cloud.

### Screenshots

```markdown
![DR architecture overview](./diagrams/dr-architecture-overview.png)
![DNS cutover screenshot](./screenshots/dns-cutover.png)
```

---

## Architecture

- High-level diagram:

  ```markdown
  ![DR high-level architecture](./diagrams/architecture-overview.png)
  ```

- Key components:
  - **On-prem:** Proxmox / Kubernetes cluster hosting primary workloads.
  - **Cloud:** Minimal standby environment sized for DR, not steady-state peak.
  - **Control plane:** DNS provider (and optionally load balancer) used to switch traffic.
  - **State:** Either replicated or re-hydrated from backups, depending on scenario.

Optional detailed diagrams:

- [Failover flow](./diagrams/dr-failover-flow.png)
- [Failback flow](./diagrams/dr-failback-flow.png)

---

## Implementation highlights

- Warm standby rather than always-on multi-region active/active to control cost.
- DNS-driven cutover with clear TTL and rollback considerations.
- Runbooks for both failover and failback, with evidence captured for each exercise.
- Designed to be demonstrable in a home lab while mapping to real-world DR expectations.

---

## Assets and source

- GitHub folder for this showcase:  
  https://github.com/hybridops-studio/hybridops-studio/tree/main/showcases/dr-failover-to-cloud

- Infra and scripts:
  - `infra/terraform/` – DR infrastructure definitions.
  - `core/ansible/` – configuration for DR roles.
  - `./scripts/` – helper scripts used during DR drills.

- Evidence:
  - `./evidence/` – screenshots, logs and exported dashboards from DR test runs.

---

## Academy track (if applicable)

In the Academy, this scenario can be turned into a guided DR exercise where learners:

- Execute the failover and validate application health.
- Perform a controlled failback and verify state consistency.
- Capture and review evidence to support an internal DR review.

---

## Role-based lens (optional)

- **Platform Engineer / SRE:** focuses on reliability, observability and safe procedures.
- **Infrastructure Engineer:** sees practical replication and failover mechanics.
- **Engineering Manager / Hiring Manager:** sees a realistic DR approach rather than a purely theoretical slide.

---

## Back to showcase catalogue

- [Back to all showcases](../000-INDEX.md)
