# Hybrid Failover & Migration Showcase

This showcase demonstrates a DR cutover using the real deployment pipeline.

## What it proves
- WAL-G restore/promote of on‑prem Postgres to cloud storage target
- Attach cloud cluster and sync apps with GitOps
- DNS cutover
- Evidence captured for portfolio

## How to run
```bash
# from repo root (or any path; Makefiles resolve it)
make env.setup
make sanity

# run the DR demo
make showcase.hybrid-failover-migration-showcase.demo
```

## Outputs
- Evidence copied to: `showcases/hybrid-failover-migration-showcase/evidence/`
- Full logs remain under: `out/artifacts/ansible-runs/**`
