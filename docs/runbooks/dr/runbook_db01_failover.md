---
title: "PostgreSQL LXC (db-01) Failure and Promotion"
category: "dr"               # bootstrap | dr | burst | ops | platform | networking | tooling.
summary: "Handle failure of the primary PostgreSQL LXC (db-01), promote a replica or alternate instance, and safely repoint dependent workloads with full evidence capture."
severity: "P1"               # P1 = critical, P2 = high, P3 = normal.

topic: "db01-failover"

draft: false
is_template_doc: false
tags: ["postgresql", "lxc", "dr", "netbox", "rke2", "state"]

access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""

---

# PostgreSQL LXC (db-01) Failure and Promotion

**Purpose:** Provide a clear procedure for handling failure of the primary **PostgreSQL LXC (db-01)**, promoting a replica or alternate instance, and safely repointing dependent workloads (for example, NetBox on RKE2) while capturing evidence.  
**Owner:** Platform / SRE team (HybridOps.Studio)  
**Trigger:** db-01 is unavailable, failing health checks, or deemed unsafe to continue as primary.  
**Impact:** Services that depend on PostgreSQL (for example, NetBox as Source of Truth) may be degraded or unavailable. Data integrity and recovery point objective (RPO) must be considered.  
**Severity:** P1 – database primary outage.

This runbook aligns with:

- [ADR-0013 – PostgreSQL Runs in LXC (State on Host-Mounted Storage; Backups First-Class)](../adr/ADR-0013_postgresql-as-lxc.md)  
- [ADR-0202 – Adopt RKE2 as Primary Runtime for Platform and Applications](../adr/ADR-0202-rke2-primary-runtime-for-platform-and-apps.md)  
- [ADR-0701 – Use GitHub Actions as Stateless DR Orchestrator](../adr/ADR-0701-github-actions-stateless-dr-orchestrator.md)  
- [ADR-0801 – Treat Cost as a First-Class Signal for DR and Cloud Bursting](../adr/ADR-0801-cost-first-class-signal-dr-bursting.md)  

---

## 1. Scenario overview

PostgreSQL is hosted primarily in an **LXC container** (db-01) on Proxmox, with:

- Host-mounted storage to make state visible and backup-friendly.  
- Regular backups (for example, WAL-G, snapshot-based backups, or both).  
- Optionally one of:
  - A **standby/replica LXC** (db-02) on another Proxmox node, and/or
  - A **cloud PostgreSQL replica** used for DR.

This runbook covers:

1. Rapid triage of db-01 failure.  
2. Promotion of a replica or restoration to an alternate instance.  
3. Repointing workloads that depend on PostgreSQL (for example, NetBox on RKE2).  
4. Verification and evidence capture.

> Note: If the failure is part of a **wider on-prem outage**, coordinate with the DR cutover runbook:  
> [Runbook – DR Cutover: On-Prem RKE2 to Cloud Cluster](../runbooks/dr/runbook_dr_cutover_onprem_to_cloud.md)

Evidence for this runbook should be stored under:

- [`docs/proof/data/postgresql/`](../../docs/proof/data/postgresql/)  
- Application-specific proof folders (for example, [`docs/proof/apps/netbox/`](../../docs/proof/apps/netbox/))

---

## 2. Preconditions and safety checks

Before making changes, establish:

1. **Confirm the nature of the failure**

   - Is db-01:
     - Completely unreachable (LXC not running / Proxmox node down)?  
     - Running but PostgreSQL service unhealthy?  
     - Experiencing data corruption or disk issues?

   - From the Proxmox node that should host db-01:

     ```bash
     pct status <db01-ctid>
     ```

   - If the Proxmox node itself is down or unstable, treat this as broader infra failure and consider DR as well as this runbook.

2. **Confirm backup and replica status**

   - Identify last successful backup:
     - Time, size, and method (WAL-G, snapshot, etc.).
   - Identify available replicas:
     - On-prem standby LXC (db-02) or
     - Cloud PostgreSQL replica.

3. **Identify critical dependent services**

   - At minimum:
     - NetBox (running on RKE2 or Docker, depending on current state).
   - Confirm which workloads are allowed to operate in **read-only** mode vs must remain offline until promotion completes.

4. **Declare incident and freeze risky changes**

   - Open or update the incident ticket.
   - Pause non-essential schema changes and database migrations.
   - Communicate potential downtime / degraded mode to stakeholders.

5. **Create evidence folder**

   - Choose an event-specific folder under:

     ```bash
     mkdir -p docs/proof/data/postgresql/db01-failover-<date>/
     ```

   - Replace `<date>` with a timestamp (for example, `2025-12-02T193000Z`).

---

## 3. Phase 1 – Triage db-01

> Goal: Quickly decide if db-01 can be recovered in place or if you must switch to a replica/restore.

1. **Check LXC container state**

   ```bash
   # From Proxmox host
   pct status <db01-ctid>
   pct console <db01-ctid>
   ```

   - If the LXC is stopped and can be safely started:
     ```bash
     pct start <db01-ctid>
     ```
   - Capture any errors to:
     - `docs/proof/data/postgresql/db01-failover-<date>/db01-pct-status.txt`

2. **Check PostgreSQL service state**

   Inside db-01 (if reachable):

   ```bash
   systemctl status postgresql
   journalctl -u postgresql --since "30 min ago"
   ```

   - Look for:
     - Out-of-disk issues.
     - Data corruption messages.
     - Repeated crash loops.

3. **Check disk and filesystem**

   ```bash
   df -h
   dmesg | tail -n 50
   ```

   - If disk is full, consider emergency clean-up of logs or non-critical data, then attempt restart.

4. **Decision point: in-place recovery vs failover**

   - **Attempt in-place recovery first** if:
     - The underlying storage is healthy.
     - Issues look transient (for example, disk full, misconfiguration).
   - **Switch to failover** (promotion/restore) if:
     - LXC host is down for an extended period.
     - Strong signs of disk or data corruption.
     - Recovery risk is high relative to RPO/RTO commitments.

Record the decision and rationale in the incident ticket and in a short text file in the proof folder.

---

## 4. Phase 2 – Promote replica or restore to new primary

> Goal: Establish a new **PostgreSQL primary** that can take over db-01’s role with an acceptable RPO.

### 4.1 Promote an existing standby (preferred path)

If you have a hot/warm standby (for example, LXC db-02 or a cloud replica):

1. **Confirm standby health**

   - Check service status and replication lag:

     ```bash
     systemctl status postgresql
     # Example (may differ based on tooling):
     psql -U postgres -c "SELECT pg_is_in_recovery(), now() - pg_last_xact_replay_timestamp();"
     ```

2. **Promote standby to primary**

   Use the appropriate promotion command for your setup (for example):

   ```bash
   # Example using pg_ctl on the standby:
   pg_ctlcluster <version> main promote
   ```

   Or the tool provided by your backup/replication stack.

3. **Record the promotion**

   - Capture the promotion command and logs to:
     - `docs/proof/data/postgresql/db01-failover-<date>/promotion-logs.txt`

4. **Update DNS / connection endpoints (if applicable)**

   - If applications refer to `db-01` via DNS, you may:
     - Update DNS to point to the new primary, or
     - Use a connection string/endpoint that already abstracts this.

### 4.2 Restore from backup (fallback path)

If no healthy standby is available:

1. **Provision a new PostgreSQL LXC or instance**

   - Create `db-new` LXC (or equivalent) with host-mounted storage aligned to ADR-0013.
   - Install PostgreSQL at the expected version.

2. **Restore from last good backup**

   - Use your chosen restore mechanism (for example, WAL-G, base backup + WAL):

     ```bash
     # Pseudocode; adapt to your tooling
     wal-g backup-fetch /var/lib/postgresql/data LATEST
     ```

   - Confirm PostgreSQL starts cleanly after restore.

3. **Record RPO impact**

   - Determine how much time/data was lost compared to the current time.
   - Document RPO breach (if any) in the incident ticket.

4. **Prepare the new instance to act as primary**

   - Confirm `pg_is_in_recovery()` returns `false` (not in recovery).
   - Confirm you can connect as the NetBox and other app users.

---

## 5. Phase 3 – Repoint dependent workloads

> Goal: Safely reconnect applications (for example, NetBox on RKE2) to the new PostgreSQL primary.

1. **Identify affected applications**

   At minimum:

   - NetBox on RKE2 (see [HOWTO – Deploy NetBox on RKE2 Using PostgreSQL LXC](../howtos/HOWTO_deploy_netbox_on_rke2_with_postgresql_lxc.md)).
   - Any other workloads configured to talk to `db-01`.

2. **Update connection endpoints**

   Depending on your architecture:

   - If using DNS (for example, `db-01.internal.local`):
     - Update DNS to point at the new primary.
   - If using explicit hostnames in K8s secrets:
     - Update the relevant Secrets or ExternalSecrets and apply via GitOps/CI.

3. **Restart or roll pods**

   For K8s workloads (example for NetBox):

   ```bash
   kubectl rollout restart deploy/netbox -n network-platform
   ```

   Ensure workloads pick up new connection settings.

4. **Verify application connectivity**

   - Check application logs for successful DB connections.
   - Perform basic functional checks (for example, NetBox login, query, create/delete a test record).

5. **Record application-level evidence**

   - `kubectl get pods` outputs.
   - Application health endpoints.
   - Store under:
     - `docs/proof/apps/netbox/`
     - `docs/proof/data/postgresql/db01-failover-<date>/apps-checks.txt`

---

## 6. Phase 4 – Stabilisation and follow-up

1. **Monitor new primary**

   - Check PostgreSQL logs and metrics for:
     - Errors.
     - High replication lag (if you re-establish a standby).
     - Resource saturation.

2. **Decide what to do with the old db-01**

   - If db-01 returns:
     - Consider reinitialising it as a standby using fresh base backup from the new primary.
   - Ensure you do not inadvertently bring it back as a split-brain primary.

3. **Re-establish backup and replication**

   - Ensure regular backup jobs point to the new primary.
   - Restore standby/replica topology.

4. **Update diagrams and documentation if topology changed**

   - If the long-term primary host has changed, update:
     - ADR-0013 links or notes (if required).
     - Platform diagrams.
     - Any static documentation that assumes db-01 hostname as the only primary.

---

## 7. Evidence and close-out

Before closing this runbook:

1. Ensure the following locations contain up-to-date artefacts for this event:

   - [`docs/proof/data/postgresql/`](../../docs/proof/data/postgresql/)  
   - [`docs/proof/apps/netbox/`](../../docs/proof/apps/netbox/)  
   - Any additional app-specific proof folders.

2. Update the incident ticket with:

   - Timeline (failure → decision → promotion/restore → repoint → stable).
   - RPO/RTO observations.
   - Root cause (if known) and contributing factors.
   - Follow-up tasks (for example, capacity, hardware, backup tuning).

3. If this was a drill:

   - Capture lessons learned.
   - Validate that steps were realistic and repeatable.
   - Align future DR drills to use this runbook as a baseline.

---

## 8. Validation checklist

- [ ] Nature of db-01 failure identified and documented.  
- [ ] Decision (recover in place vs promote/restore) made and recorded with rationale.  
- [ ] New primary (standby promoted or restored instance) is healthy and accepting connections.  
- [ ] Dependent workloads (for example, NetBox on RKE2) have been repointed and validated.  
- [ ] Backups and, if applicable, standby/replica topology have been re-established.  
- [ ] Evidence artefacts stored under [`docs/proof/data/postgresql/`](../../docs/proof/data/postgresql/) and relevant application proof folders.  
- [ ] Incident ticket updated with findings and follow-up actions.  

---

## References

- [ADR-0013 – PostgreSQL Runs in LXC (State on Host-Mounted Storage; Backups First-Class)](../adr/ADR-0013_postgresql-as-lxc.md)  
- [ADR-0202 – Adopt RKE2 as Primary Runtime for Platform and Applications](../adr/ADR-0202-rke2-primary-runtime-for-platform-and-apps.md)  
- [ADR-0701 – Use GitHub Actions as Stateless DR Orchestrator](../adr/ADR-0701-github-actions-stateless-dr-orchestrator.md)  
- [ADR-0801 – Treat Cost as a First-Class Signal for DR and Cloud Bursting](../adr/ADR-0801-cost-first-class-signal-dr-bursting.md)  
- [Evidence 3 – Source of Truth and Network Automation](../evidence/evidence-03-source-of-truth-netbox-automation.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  
- [`docs/proof/data/postgresql/`](../../docs/proof/data/postgresql/)  
- [`docs/proof/apps/netbox/`](../../docs/proof/apps/netbox/)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation
