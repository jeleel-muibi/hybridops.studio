---
title: "Ops: PostgreSQL — WAL-G Restore/Promote"
category: dr
summary: "Restore from WAL-G archives and promote a new primary; validate application writes."
last_updated: 2025-10-08
severity: P1
---

# Ops: PostgreSQL — WAL-G Restore/Promote

**Purpose:** Restore from WAL-G archive and promote a new primary.
**Owner:** Database SRE · **When:** DR promotion or point-in-time recovery (PITR).

## Pre-requisites
- WAL-G configured with storage creds (on-prem object storage/cloud bucket).
- Target instance reachable; maintenance/DR window approved.

## Rollback
If recovery invalid, stop service, re-run restore from earlier base + WALs, or fail back to prior primary.

## Steps

1) **Run controlled restore/promote**
```bash
deployment/common/scripts/dr_restore_promote.sh azure   | tee "output/logs/db/$(date -Iseconds)_walg_restore_promote.log"
```
**Expected:** Restore completes; `pg_is_in_recovery()` returns `false`.

2) **Sanity checks**
```sql
-- Run via psql
SELECT pg_is_in_recovery();        -- should be false
SELECT now() - pg_last_xact_replay_timestamp();  -- NULL on primary
```

3) **Application connectivity**
- NetBox/other apps connect; write small test and verify read.

## Evidence
- Restore/promote log: `output/logs/db/<ts>_walg_restore_promote.log`
- DB screenshots/queries in `docs/proof/sql-ro/images/`
