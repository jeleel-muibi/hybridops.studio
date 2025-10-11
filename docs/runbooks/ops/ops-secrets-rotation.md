---
title: "Ops: Secrets Rotation"
category: ops
summary: "Rotate sensitive credentials/keys (Sealed Secrets / External Secrets / Vault) with minimal downtime."
last_updated: 2025-10-08
severity: P1
---

# Ops: Secrets Rotation

**Purpose:** Rotate sensitive credentials/keys with minimal downtime.
**Owner:** Platform SRE/SecOps

## Pre‑requisites
- Chosen mechanism (Sealed Secrets / External Secrets / Vault operator).
- KMS access (Azure Key Vault / GCP KMS) or on‑prem HSM.

## Rollback
- Re-apply previous sealed secret or previous version in vault with a short TTL.

## Steps

1) **Prepare new secret material**
```bash
# Example with Sealed Secrets (kubeseal)
kubectl -n appns create secret generic myapp-secret --dry-run=client   --from-literal=API_KEY='<new>' -o yaml |   kubeseal --format yaml > deployment/app/myapp/sealedsecret.yaml
git add deployment/app/myapp/sealedsecret.yaml && git commit -m "rotate: myapp API key"
git push
```

2) **Reconcile via GitOps**
- Wait for controller to apply changes; watch rollout.

3) **Verify app reload / access**
- App reads new credentials; zero downtime or planned blip.

## Evidence
- Commit hash; controller events; app logs → `output/artifacts/showcases/...`
- Screenshots to `docs/proof/observability/images/`.
