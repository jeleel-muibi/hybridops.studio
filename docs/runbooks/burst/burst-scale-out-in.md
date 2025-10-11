---
title: "Burst: Scale Out / In"
category: burst
summary: "Temporarily add/remove cloud capacity in response to load or schedules."
last_updated: 2025-10-08
severity: P2
---

# Burst: Scale Out / In

**Purpose:** Temporarily add/remove cloud capacity based on load or scheduled peaks.
**Owner:** Platform SRE · **When:** Alert threshold crossed or scheduled peak.

## Pre‑requisites
- Authorization to burst (policy/Decision Service/schedule).
- Networking and cluster access in place.

## Steps

1) **Scale out (add capacity)**
```bash
export CLOUD=gcp   # or azure
make burst.scale.up CLOUD=$CLOUD   | tee "output/logs/terraform/$(date -Iseconds)_burst_up_${CLOUD}.log"
```

2) **Validate workload placement**
```bash
make burst.validate
kubectl top nodes   | tee "output/artifacts/showcases/kubernetes-autoscaling/$(date -Iseconds)_top_nodes_${CLOUD}.txt"
kubectl get pods -A -o wide   | tee "output/artifacts/showcases/kubernetes-autoscaling/$(date -Iseconds)_pods_${CLOUD}.txt"
```

3) **Scale in (remove surge)**
```bash
make burst.scale.down CLOUD=$CLOUD   | tee "output/logs/terraform/$(date -Iseconds)_burst_down_${CLOUD}.log"
```

## Evidence
- HPA/VPA events & graphs → `docs/proof/observability/images/`.
- Terraform logs → `output/logs/terraform/`.
