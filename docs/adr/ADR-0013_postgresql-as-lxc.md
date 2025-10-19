---
id: ADR-0013
title: "PostgreSQL Runs in LXC (State on Host-Mounted Storage; Backups First-Class)"
status: Accepted
date: 2025-10-12
domains: ["data", "sre", "infra"]
owners: ["jeleel"]
supersedes: []
superseded_by: []
links:
  prs: []
  runbooks: ["../runbooks/data/postgresql-lxc-backup.md"]
  evidence: ["../proof/data/postgresql-lxc/"]
  diagrams: ["../diagrams/postgresql_lxc_architecture.png"]
---

# ADR-0013 — PostgreSQL Runs in LXC (State on Host-Mounted Storage; Backups First-Class)

## Status
Accepted — PostgreSQL is standardized to run inside an **LXC container** with its persistent data hosted on a **Proxmox-mounted volume**, ensuring durability and replicability across hybrid DR sites.

## Context
During initial design, PostgreSQL was deployed directly on the `ctrl-01` VM.  
While functional, this tightly coupled storage and compute layers, complicating DR and snapshot testing.

Running PostgreSQL in a **dedicated LXC container** offers several advantages:
- lightweight isolation without full VM overhead,
- controlled resource boundaries (CPU, RAM, IO),
- quick restart and replication capabilities,
- clean separation from Jenkins, Terraform, or RKE2 workloads.

However, container storage alone isn’t resilient. Therefore, the container’s `/var/lib/postgresql` directory is **mounted from a host dataset** (e.g., ZFS or ext4) so that snapshots, rsync jobs, and WAL-G backups are consistent and host-driven.

## Decision
Run PostgreSQL in a **dedicated LXC container (`db-01`)**, mounting persistent storage from the Proxmox host, with backup and promotion pipelines managed externally by Jenkins.

### Design Summary
- **Container Type:** unprivileged LXC (`db-01`) with host volume bind mount.  
- **Storage:** `/srv/db01-data` (ZFS dataset) bound to `/var/lib/postgresql/14/main`.  
- **Networking:** static IP via `vmbr6`, DNS entry `db01.lab.local`.  
- **Backups:** handled via WAL-G to cloud object storage (Azure Blob, GCP Bucket).  
- **Promotion:** DR-read-replica running in cloud, promoted manually or by Decision Service.  
- **Monitoring:** `postgres_exporter` integrated into Prometheus Federation.

### Implementation Notes
- LXC provisioned via Terraform using the Proxmox provider.  
- Initialization handled by Ansible role `postgresql_lxc`.  
- Backups scheduled via Jenkins job `db.backup.daily`.  
- Evidence for each run stored under `docs/proof/data/postgresql-lxc/<date>/`.

## Consequences
- ✅ Reduced VM footprint; lighter than running PostgreSQL in a full VM.  
- ✅ Host-managed ZFS snapshots and WAL-G integration improve RPO.  
- ✅ Portable to cloud DR via rsync + replay of WAL archives.  
- ⚠️ Requires careful UID/GID alignment between host and container.  
- ⚠️ Slightly reduced isolation compared to VM, acceptable for on-prem lab scope.

## References
- [Runbook: PostgreSQL LXC Backup & Restore](../runbooks/data/postgresql-lxc-backup.md)  
- [Diagram: PostgreSQL LXC Architecture](../diagrams/postgresql_lxc_architecture.png)  
- [Evidence: PostgreSQL LXC Proofs](../proof/data/postgresql-lxc/)

---

**Author / Maintainer:** Jeleel Muibi  
**Project:** [HybridOps.Studio](https://github.com/jeleel-muibi/hybridops.studio)  
**License:** MIT-0 / CC-BY-4.0
