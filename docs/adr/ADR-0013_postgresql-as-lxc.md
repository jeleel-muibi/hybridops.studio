---
id: 0013
title: PostgreSQL runs in LXC (state on host‑mounted storage; backups first‑class)
status: accepted
decision_date: 2025-10-12
domains: [data, sre, infra]
tags: [proxmox, lxc, postgresql, backups, storage, security]
---

## Context

We need a reliable PostgreSQL for platform components/demos with **fast provisioning** and **clear DR**. Density favors **LXC**, but data must live beyond the container and be backed up independently.

## Decision

Run **PostgreSQL in an unprivileged LXC**. Place data and WAL on a **host‑mounted volume** so the container can be rebuilt without data loss. Schedule daily logical backups (and optional physical), stored on host storage.

## Decision Drivers

- **Simplicity & density:** LXC is lightweight and fast to rebuild.
- **Data durability:** Host‑mounted storage, independent backups.
- **Scope:** Single‑node DB for platform use; HA not required initially.

## Options Considered

- **LXC (unprivileged)** — Light; requires attention to IPC/SHM and perms. **Chosen.**
- **VM** — Heavier; reserved if we need kernel features/perf beyond LXC.
- **External managed DB** — Not always available in on‑prem demos.

## Consequences

- + Quick rebuilds; data survives container lifecycle.
- + Easy backup/restore drills.
- − Some LXC tuning (IPC/SHM, perms). Move to VM if constraints appear.

## Operational Boundaries

- Network access limited to `172.16.13.0/24` (by default).
- Credentials not stored in git; use CI secrets or `.pgpass` in the CT.

## References (placeholders)

- Runbook: `docs/runbooks/postgres/lxc_deploy.md` _(to be written)_  
- Backup/restore: `docs/runbooks/postgres/backup_restore.md` _(to be written)_  
- LXC spec: `control/snippets/pg-lxc.yaml` _(placeholder)_  
- Make targets: `make postgres.lxc.create`, `make postgres.backup`, `make runbooks.index`
