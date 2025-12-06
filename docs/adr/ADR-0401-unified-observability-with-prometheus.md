---
id: ADR-0401
title: "Unified Observability with Prometheus"
status: Accepted
date: 2025-11-30

category: "04-observability"
supersedes: []
superseded_by: []

links:
  prs: []
  runbooks: []
  howtos: []
  evidence: []
  diagrams: []

draft: false
tags: ["prometheus", "monitoring", "grafana", "observability"]
access: public
---

# Unified Observability with Prometheus

**Status:** Accepted — Centralises observability with a single Prometheus/Grafana/Loki stack in VLAN 11 scraping all environments, simplifying cross-env views and alerts.

## Context

HybridOps Studio spans multiple VLANs and environments (dev, staging, production) as defined in ADR-0101. Observability must:

- Provide a unified view across all environments.
- Support environment-specific dashboards.
- Enable cross-environment comparisons.
- Drive alerts with environment-aware routing.

Several architectures were considered:

- Prometheus per environment with federation.
- A single central Prometheus instance scraping all environments.
- Third-party SaaS observability platforms.

## Decision

Deploy a **single Prometheus instance** in the observability VLAN (VLAN 11) that scrapes metrics from all environments.

- Prometheus, Grafana, and Loki are hosted in VLAN 11.
- Exporters (for example, node_exporter, kube-state-metrics) run on nodes in VLANs 20/30/40.
- The inter-VLAN firewall policy (ADR-0103) allows Prometheus to scrape metrics from dev, staging, and production and exposes Grafana to authorised clients.

Labels such as `environment` and `cluster` are attached to metrics at scrape time to distinguish sources.

## Rationale

- A single Prometheus provides **one query surface** for metrics across all environments.
- Cross-environment queries and SLO comparisons are straightforward.
- Operational overhead remains low compared to per-environment Prometheus + federation.
- The design aligns with the scale and goals of a homelab blueprint while remaining close to patterns used in smaller production deployments.

## Consequences

### Positive

- Unified metrics view across dev, staging, and production.
- Centralised alerting with environment-aware routing.
- Reduced complexity and resource usage compared to multiple Prometheus instances.
- Observability components are separated from workloads in their own VLAN.

### Negative

- The observability stack becomes a single point for metric ingestion; its availability affects visibility for all environments.
- Capacity planning must consider the aggregate metric volume.

### Neutral

- The architecture can be evolved to a federated or Thanos-based design once scale justifies the additional complexity.
- Access to Grafana can be restricted via RBAC if different audiences require different views.

## Implementation

- Prometheus, Grafana, and Loki are deployed on dedicated VMs in VLAN 11.
- Firewall rules allow Prometheus in VLAN 11 to scrape exporters in VLANs 20/30/40 on the required ports.
- Scrape configurations use static targets or service discovery mechanisms appropriate to each environment.
- Dashboards are grouped by environment, with variables that enable filtering and comparison.

Validation:

- Targets in all environments appear as `UP` in the Prometheus UI.
- Dashboards display metrics for each environment and cross-environment views.
- Alerting rules trigger as expected and route based on environment labels.

## References

- VLAN allocation: [ADR-0101 VLAN Allocation Strategy](./ADR-0101-vlan-allocation-strategy.md)
- Inter-VLAN firewall: [ADR-0103 Inter-VLAN Firewall Policy](./ADR-0103-inter-vlan-firewall-policy.md)
- Network architecture overview: [Network Architecture](../prerequisites/network-architecture.md)

---

**Maintainer:** HybridOps.Studio
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
