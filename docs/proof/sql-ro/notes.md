# SQL Read‑Only Replica (Azure) — Proof Pack
_Last updated: 2025-09-22 00:07 UTC_

- **What this proves:** **RO** replica of the on‑prem SQL primary is healthy in Azure; **RPO ≤ 5m** target met.
- **Capture date (UTC):** 2025-09-22 00:07 UTC
- **How to verify:** See `./links.txt` (Grafana replication lag panel; SQL dashboard/deep link).
- **Hint:** Add a short window around a test failover or heavy write burst to show lag behavior.
