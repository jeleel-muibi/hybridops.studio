---
title: "DR: Failback to On-Prem"
category: dr
summary: "Return steady-state to on-prem following a DR window; promote DB, reconcile workloads, cut back DNS."
last_updated: 2025-10-08
severity: P1
---

# DR: Failback to On‑Prem

**Purpose:** Return steady‑state to on‑prem after DR window.
**Owner:** Platform SRE (lead) · DB SRE · NetOps.
**Target window:** ≤ 30m

## Pre‑requisites
- On‑prem cluster healthy; interconnect (NCC hub‑and‑spoke) up.
- Confirm no DR‑specific write constraints remain in apps.

## Rollback
If failback stalls or on‑prem degrades, re‑run **Failover to Cloud**.

## Steps

1) **Re‑establish DB primary on‑prem**
```bash
deployment/common/scripts/dr_restore_promote.sh onprem   | tee "output/logs/db/$(date -Iseconds)_promote_onprem.log"
```
**Expected:** Primary is on‑prem; RO in cloud (optional).

2) **Reconcile workloads back to on‑prem (GitOps)**
```bash
kubectl config use-context onprem
# Ensure apps are pointed to on‑prem manifests/targets
# Trigger reconciliation or wait for controllers to sync
kubectl get pods -A -o wide   | tee "output/artifacts/dr-drills/$(date -Iseconds)_pods_onprem.txt"
```

3) **DNS cutback**
```bash
deployment/common/scripts/dns_cutover.sh onprem   | tee "output/logs/dns/$(date -Iseconds)_cutback_onprem.log"
```

4) **De‑provision DR surge (optional)**
```bash
make burst.scale.down CLOUD=azure   # or gcp
```

## Verification
- **No data divergence** vs cloud. Validate row counts / key checks.
- Monitoring back to baseline; synthetics pass.
- Export screenshots/logs to `docs/proof/sql-ro/images/` and `docs/proof/observability/images/`.
