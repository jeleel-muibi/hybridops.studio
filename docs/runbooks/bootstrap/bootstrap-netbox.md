---
title: "Bootstrap: NetBox (Source of Truth)"
category: bootstrap
summary: "Deploy NetBox and seed it as the Source of Truth for inventory and automation."
last_updated: 2025-10-08
severity: P1
---

# Bootstrap: NetBox (SoT)

**Purpose:** Deploy NetBox to Kubernetes and seed it as Source of Truth (SoT).
**Owner:** Platform SRE · **When:** First-time bring-up or rebuild.
**Time:** 20–30m

## Pre‑requisites
- Kubernetes cluster reachable; kubecontext set.
- PostgreSQL reachable (on‑prem primary or DR target). DB creds available.
- GitOps bootstrap done *or* permission to apply manifests directly.
- Initial NetBox admin token (for seed API calls).

## Rollback
- `kubectl delete -f deployment/netbox/k8s/` (if applied directly) or revert GitOps app to previous commit.
- Restore DB from snapshot/WAL if seed corrupted data (rare).

## Steps

1) **Create/verify namespace & secrets**
```bash
kubectl get ns netbox || kubectl create ns netbox

# Example secret schema (replace with your Sealed/External Secrets flow)
kubectl -n netbox create secret generic netbox-env   --from-literal=DB_NAME=netbox   --from-literal=DB_USER=netbox   --from-literal=DB_PASSWORD='<redacted>'   --from-literal=DB_HOST='postgresql.default.svc'   --from-literal=SECRET_KEY='<django_secret>'
```
**Expected:** `netbox-env` present.
**Evidence:** `kubectl -n netbox get secrets > output/artifacts/inventories/$(date -Iseconds)_netbox_secrets.txt`

2) **Deploy NetBox (choose one)**
- **GitOps:** merge PR that adds `deployment/netbox/k8s/` to the apps repo.
- **Direct:**
```bash
kubectl -n netbox apply -f deployment/netbox/k8s/
kubectl -n netbox rollout status deploy/netbox --timeout=5m
```

3) **Seed SoT (optional but recommended)**
```bash
# Example: seed sites/devices via API with a small script
python deployment/netbox/seed/seed_from_yaml.py   --api https://netbox.<yourdomain>/api   --token $NETBOX_TOKEN   --files deployment/netbox/seed/examples/*.yml   | tee "output/logs/netbox/$(date -Iseconds)_seed.log"
```
**Expected:** objects created; no 4xx/5xx.
**Evidence:** seed log + NetBox UI screenshots of Sites/Devices.

4) **Export rendered inventory**
```bash
# If you expose inventory rendering:
ansible-inventory -i deployment/inventories/netbox/netbox.yml --list   | tee "output/artifacts/inventories/$(date -Iseconds)_netbox_render.json"
```

## Verification
- NetBox web loads; health endpoint OK.
- Random sample of devices/sites present.
- Cross-check inventory export with NetBox UI.

## Links
- Manifests: `deployment/netbox/k8s/`
- Inventory plugin: `deployment/inventories/netbox/netbox.yml`
- Evidence Map: `docs/evidence_map.md` → NetBox/SoT
