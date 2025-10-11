# Burst‑to‑Cloud Kubernetes — Proof Pack
_Last updated: 2025-09-22 00:07 UTC_

- **What this proves:** Burst‑to‑cloud Kubernetes in **AKS/GKE**. Workers added on demand; autoscaler and VMSS/MIG events recorded.
- **Capture date (UTC):** 2025-09-22 00:07 UTC
- **How to verify:** See `./links.txt` (Grafana CPU/util thresholds → autoscaler events; `kubectl get nodes` before/after; Azure VMSS / GCP MIG activity).
- **Hint:** Include timestamps that correlate Grafana alerts → CI trigger → scale events.

**Back to:** [Evidence Map](../../evidence_map.md)
