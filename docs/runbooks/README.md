# Runbooks — Operational Procedures

Concise, reproducible procedures for DR, burst, bootstrap, DNS cutover, VPN, secrets rotation, and more.
Each runbook is outcome‑focused and linked to evidence.

> The list below is generated from the runbooks in this folder. For update details, see the [Maintenance Guide](../maintenance.md#runbooks-generator).

## Conventions (applies to all runbooks)
- **Pre-checks** — prerequisites and environment sanity.
- **Execute** — ordered steps and commands.
- **Verify** — success criteria and dashboards to check.
- **Artifacts** — logs/exports to capture under `output/`.
- **Rollback** — safe, minimal reversal steps.
- **See also** — [Evidence Map](../evidence_map.md) · [Proof Archive](../proof/README.md) · [Related runbooks](./by-category/)

<!-- RUNBOOKS:INDEX START -->
**Categories:** [bootstrap (3)](./by-category/bootstrap.md) · [burst (1)](./by-category/burst.md) · [dr (5)](./by-category/dr.md) · [ops (4)](./by-category/ops.md)

For detailed metadata (severity, timestamps), see the [full index](./000-INDEX.md).


---

<details>
  <summary><strong>All runbooks</strong> (13) — click to expand</summary>


- [Bootstrap: GitOps (Argo CD / Flux)](./bootstrap/bootstrap-gitops.md)
- [Bootstrap: NetBox (Source of Truth)](./bootstrap/bootstrap-netbox.md)
- [Bootstrap: RKE2 (On-Prem)](./bootstrap/bootstrap-rke2-install.md)
- [Burst: Scale Out / In](./burst/burst-scale-out-in.md)
- [DR Cutover (Alias)](./dr/dr_cutover.md)
- [DR: Failback to On-Prem](./dr/dr-failback-to-onprem.md)
- [DR: Failover to Cloud](./dr/dr-failover-to-cloud.md)
- [Ops: PostgreSQL — WAL-G Restore/Promote](./dr/ops-postgres-walg-restore-promote.md)
- [Source of Truth (SoT) Pivot — Terraform → NetBox → Ansible](./dr/sot_pivot.md)
- [Ops: AVD Zero-Touch](./ops/ops-avd-zero-touch.md)
- [Ops: DNS Cutover](./ops/ops-dns-cutover.md)
- [Ops: Secrets Rotation](./ops/ops-secrets-rotation.md)
- [Ops: Site-to-Site VPN Bring-Up](./ops/ops-vpn-bringup.md)

</details>


<sub>Last generated: 2025-10-11 11:34 UTC</sub>
<!-- RUNBOOKS:INDEX END -->

[Back to Docs Home](../README.md)
