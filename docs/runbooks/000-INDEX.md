# 000-INDEX — Runbooks
_Last updated: 2025-10-20 21:05 UTC_

Tabular summary of reproducible operational procedures grouped by category and severity.

**Categories:** [bootstrap (4)](./by-category/bootstrap.md) · [burst (1)](./by-category/burst.md) · [dr (5)](./by-category/dr.md) · [ops (5)](./by-category/ops.md)

**Legend:** P1 = critical · P2 = high · P3 = normal

| Runbook | Link | Severity | Category | Last updated |
|:---------|:----:|:--------:|:---------:|:-------------:|
| Bootstrap: GitOps (Argo CD / Flux) | [Open](./bootstrap/bootstrap-gitops.md) | P2 | bootstrap | 2025-10-08 |
| Bootstrap: NetBox (Source of Truth) | [Open](./bootstrap/bootstrap-netbox.md) | P1 | bootstrap | 2025-10-08 |
| Bootstrap: RKE2 (On-Prem) | [Open](./bootstrap/bootstrap-rke2-install.md) | P1 | bootstrap | 2025-10-08 |
| ctrl-01 Day-1 bootstrap & verification | [Open](./bootstrap/bootstrap-ctrl01-node.md) | P2 | bootstrap | 2025-10-18 |
| Burst: Scale Out / In | [Open](./burst/burst-scale-out-in.md) | P2 | burst | 2025-10-08 |
| DR Cutover (Alias) | [Open](./dr/dr_cutover.md) | P1 | dr | 2025-10-08 |
| DR: Failback to On-Prem | [Open](./dr/dr-failback-to-onprem.md) | P1 | dr | 2025-10-08 |
| DR: Failover to Cloud | [Open](./dr/dr-failover-to-cloud.md) | P1 | dr | 2025-10-08 |
| Ops: PostgreSQL — WAL-G Restore/Promote | [Open](./dr/ops-postgres-walg-restore-promote.md) | P1 | dr | 2025-10-08 |
| Source of Truth (SoT) Pivot — Terraform → NetBox → Ansible | [Open](./dr/sot_pivot.md) | P2 | dr | 2025-10-08 |
| Ops: AVD Zero-Touch | [Open](./ops/ops-avd-zero-touch.md) | P3 | ops | 2025-10-08 |
| Ops: DNS Cutover | [Open](./ops/ops-dns-cutover.md) | P1 | ops | 2025-10-08 |
| Ops: Secrets Rotation | [Open](./ops/ops-secrets-rotation.md) | P1 | ops | 2025-10-08 |
| Ops: Site-to-Site VPN Bring-Up | [Open](./ops/ops-vpn-bringup.md) | P1 | ops | 2025-10-08 |
| Secrets Rotation — Azure Key Vault + Jenkins Service Principal | [Open](./ops/ops_rotate_jenkins_sp_secret_akv.md) | P2 | ops | 2025-10-20 |
