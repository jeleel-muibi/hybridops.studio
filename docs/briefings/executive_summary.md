# Executive Summary

**HybridOps.Studio** is a product‑led blueprint for hybrid cloud operations: on‑prem control with Kubernetes + GitOps, and policy‑driven failover/burst to Azure or GCP. It demonstrates **enterprise‑grade** patterns that are reproducible, auditable, and backed by evidence.

## Outcomes & KPIs
- **Resilience:** **RTO ≤ 15m** and **RPO ≤ 5m** for core services.
- **Operational speed:** Packer image builds in ≤ 12m; Terraform apply in ≤ 10m.
- **Elasticity:** Kubernetes autoscaling (+2 at 70% CPU) with safe scale‑in < 40%.
- **Governance:** Policy‑driven cloud selection (Azure/GCP) using telemetry and budget signals.

> Verification is transparent. See the [Evidence Map](../evidence_map.md) and the curated [Proof Archive](../proof/README.md).

## What’s in the Portfolio
- **On‑prem control plane:** RKE2 + GitOps, PostgreSQL (authoritative, on‑prem).
- **Networking backbone:** Google Network Connectivity Center (hub) with on‑prem and cloud spokes.
- **Observability first:** Prometheus Federation + Grafana dashboards.
- **Decision Service:** Chooses DR/burst target using federation metrics, cloud monitors, and credit thresholds.
- **CI/CD:** Jenkins primary, GitHub Actions as resilient fallback.
- **Windows scope:** On‑prem (DC/SCCM/SQL) by default; cloud DR is scenario‑based.

Explore the **Showcase Catalog** for focused demos (DR to cloud, autoscaling, migration, AVD zero‑touch, and more).

## Why it matters
- **Assessor‑ready:** Evidence‑linked claims; minimal click‑ops.
- **Portable patterns:** Works across providers and on‑prem.
- **Cost‑aware:** Cloud bursting only when policy allows and credits justify.

## Where to start
- Read the [Diagrams & Guides](../README.md).
- Run `make help` at the repo root to discover entrypoints.
- Browse the [Showcases](../../showcases/README.md) for guided demos.
- Review planned hardening in the [SecOps Roadmap](../guides/secops-roadmap.md).

_Last updated: 2025‑10‑05_
