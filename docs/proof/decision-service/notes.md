# Decision Service (Policy‑Driven Failover/Burst)
_Last updated: 2025-09-22 00:00 UTC_

**Proves:** A policy-governed Decision Service triggers autoscale/failover from SLO + cost/credits + monitor signals.

---

### Policy and Orchestration
- **What:** Decisions come from a versioned policy file; CI/CD executes the chosen scale/failover target.
- **Verify:** Open the **policy commit** and the **CI run** listed in `./links.txt`. Confirm the action (target + params) matches the policy.
- **Artifacts (`./images/`):** `policy_snippet.png`, `ci_run.png`
- **KPI tie-in:** Autoscale **+2@70%** (scale-in **<40%**), DR trigger conditions.

### Cloud Signals
- **What:** Azure Monitor / GCP Monitoring alert → webhook payload → CI run (same `correlation_id`, aligned timestamps).
- **Verify:** Follow **alert rule → incident → webhook delivery → CI run** using `./links.txt`. Match timestamps and `correlation_id`.
- **Artifacts (`./images/`):** `alert_policy.png`, `incident.png`, `webhook_payload.png`, `ci_run.png`, `scale_events.png`

---

### Capture Window (UTC)
- **From:** `YYYY-MM-DDTHH:MMZ` **To:** `YYYY-MM-DDTHH:MMZ`
- **Environment / workspace (non-sensitive):** `<name>`
- **Correlation ID(s):** `CID-YYYYMMDD-XXXX`

### Redactions
- Mask tenant/subscription/project IDs and any real IPs in screenshots or payloads.
- Keep links read-only; do not expose secrets or tokens.

**Navigate:** [Evidence Map](../../evidence_map.md) · [Proof Archive](../README.md)
