---
title: "Bootstrap: GitOps (Argo CD / Flux)"
category: bootstrap
summary: "Install and bootstrap Argo CD or Flux to manage clusters declaratively."
last_updated: 2025-10-08
severity: P2
---

# Bootstrap: GitOps

**Purpose:** Install and bootstrap Argo CD / Flux to manage clusters declaratively.
**Owner:** Platform SRE · **When:** First-time cluster setup or rebuild.

## Pre-requisites
- Cluster kubeconfig present.
- Git credentials/SSH keys available.

## Steps

1) **Install bootstrap manifests**
```bash
make gitops | tee "output/logs/gitops/$(date -Iseconds)_bootstrap.log"
```

2) **Register apps & repos (if not GitOps-self-managed yet)**
- Point Argo/Flux at your apps repo paths.
- Verify reconciliation.

3) **Health check**
```bash
kubectl -n argocd rollout status deploy/argocd-repo-server --timeout=5m
```

## Evidence
- ArgoCD app health screenshots to `docs/proof/observability/images/`.
- Log file under `output/logs/gitops/`.
