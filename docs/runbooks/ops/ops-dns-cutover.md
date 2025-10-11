---
title: "Ops: DNS Cutover"
category: ops
summary: "Cut traffic to the active site/cloud during DR or migration with verification and rollback."
last_updated: 2025-10-08
severity: P1
---

# Ops: DNS Cutover

**Purpose:** Cut traffic over to the active site/cloud during DR or migration.
**Owner:** Platform SRE/NetOps · **Time:** 5–10m

## Pre‑requisites
- Decision service or change ticket authorizing cutover.
- Target IPs/hostnames confirmed healthy.

## Rollback
- Re-run with previous target (on‑prem/cloud). Keep both command logs.

## Steps

1) **Execute cutover**
```bash
# provider: azure|gcp|onprem (per your script)
deployment/common/scripts/dns_cutover.sh azure   | tee "output/logs/dns/$(date -Iseconds)_cutover.log"
```

2) **Propagation check**
```bash
for r in 1.1.1.1 8.8.8.8 9.9.9.9; do
  dig @${r} +short <your_fqdn>;
done | tee -a "output/logs/dns/$(date -Iseconds)_propagation.txt"
```

## Verification
- External probes success (HTTP 200/healthz).
- Grafana traffic panel shows shift to target site.

## Evidence
- Log files under `output/logs/dns/`, screenshots under `docs/proof/observability/images/`.
