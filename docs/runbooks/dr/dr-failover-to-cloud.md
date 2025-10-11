---
title: "DR: Failover to Cloud"
category: dr
summary: "Promote PostgreSQL and shift workloads to the selected cloud (Azure/GCP) with RTO ≤ 15m and RPO ≤ 5m."
last_updated: 2025-10-08
severity: P1
---

# DR: Failover to Cloud

**Purpose:** Promote the database and shift workloads to cloud when on‑prem is impaired.
**Owner:** Platform SRE (lead) · DB SRE (DB steps) · NetOps (DNS).
**When:** DR declared; Decision Service selects target (Azure/GCP).
**Objectives:** **RTO ≤ 15m** · **RPO ≤ 5m**

## Pre‑requisites
- Decision Service output artifact available (target = `azure` or `gcp`).
- WAL‑G backups healthy; storage reachable from target site.
- Kube context available for AKS/GKE; networking path validated.
- Change ticket approved; comms channel open.

## Rollback
Run **[DR: Failback to On‑Prem](./dr-failback-to-onprem.md)** once the primary site is healthy.

## Steps

1) **Attach target cluster (Terraform)**
```bash
export CLOUD=azure   # or gcp
make dr.cluster.attach CLOUD=$CLOUD   | tee "output/logs/terraform/$(date -Iseconds)_attach_${CLOUD}.log"
```
**Expected:** AKS/GKE nodes ready; hub/spoke or peering in place.
**Evidence:** `output/logs/terraform/*_attach_${CLOUD}.log`

2) **Promote/restore PostgreSQL in target**
```bash
make dr.db.promote CLOUD=$CLOUD   | tee "output/logs/db/$(date -Iseconds)_promote_${CLOUD}.log"
```
**Expected:** `pg_is_in_recovery() = false`; app writes succeed.
**Evidence:** DB promote log + Decision JSON at `output/artifacts/decision/decision_*.json`

3) **Sync workloads via GitOps**
```bash
make dr.gitops.sync CLOUD=$CLOUD
kubectl get pods -A -o wide   | tee "output/artifacts/dr-drills/$(date -Iseconds)_pods_${CLOUD}.txt"
```
**Expected:** All DR workloads `Ready`; no CrashLoopBackOff.
**Evidence:** Pods listing + ArgoCD/Flux health screenshot.

4) **Public DNS cutover**
```bash
make dr.dns.cutover CLOUD=$CLOUD   | tee "output/logs/dns/$(date -Iseconds)_cutover_${CLOUD}.log"

for r in 1.1.1.1 8.8.8.8 9.9.9.9; do
  dig @${r} +short <your_fqdn>;
done | tee -a "output/logs/dns/$(date -Iseconds)_propagation_${CLOUD}.txt"
```
**Expected:** FQDN resolves to cloud endpoint; probes pass.
**Evidence:** DNS logs + propagation check.

## Verification
- **Grafana DR panel** green; synthetic checks pass.
- Record **start → finish** wall‑clock; show RTO ≤ 15m.
- Capture screenshots to `docs/proof/observability/images/`.
