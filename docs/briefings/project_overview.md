# Project Overview

This repository is organized to keep **deployable code**, **evidence**, and **documentation** cleanly separated while enabling repeatable demos.

## Structure (high‑level)
- **Deployment** — operational playbooks, manifests, and orchestration wrappers.
- **Core** — reusable Ansible roles, shared scripts, Packer templates, Terraform modules.
- **Terraform Infra** — provider‑neutral modules and environment stacks (on‑prem, Azure, GCP).
- **Docs** — diagrams, guides, Evidence Map, and Proof Archive.
- **Showcases** — self‑contained demo entrypoints (DR to cloud, migration, autoscaling, AVD, etc.).
- **output/** — centralized logs and artifacts created by runs (git‑ignored).

See the visual repo guide in [Diagrams & Guides](../README.md) and the one‑line router targets in the **root Makefile**.

## How to Navigate
- **I need the big picture** → read the [Executive Summary](./executive_summary.md) and [Diagrams & Guides](../README.md).
- **I want to validate claims** → open the [Evidence Map](../evidence_map.md) → click into any proof topic.
- **I want to run a demo** → see the [Showcase Catalog](../../showcases/README.md) and use `make showcase.<name>.demo`.
- **I’m reviewing security posture** → open the [SecOps Roadmap](../guides/secops-roadmap.md).

## Non‑Goals / Scope
- Not a turnkey product; this is a **portfolio** showing patterns with code and proof.
- Cloud SQL/Windows DR are **scenario‑based**, not blanket‑enabled.
- Cost controls and approvals are governed by the Decision Service policies (see proof topics).

## Links
- [Evidence Map](../evidence_map.md) · [Proof Archive](../proof/README.md) · [Diagrams & Guides](../README.md)

_Last updated: 2025‑10‑05_
