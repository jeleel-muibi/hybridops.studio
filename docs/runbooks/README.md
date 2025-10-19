# Runbooks — Operational Procedures

Concise, reproducible procedures for DR, burst, bootstrap, DNS cutover, VPN, secrets rotation, and more.  
Each runbook is outcome-focused and linked to supporting evidence.

> The list below is generated automatically from the runbooks in this folder.  
> For update details, see the [Maintenance Guide](../maintenance.md#runbooks-index-generation).

---

## Conventions (applies to all runbooks)
- **Pre-checks** — prerequisites and environment sanity.
- **Execute** — ordered steps and commands.
- **Verify** — success criteria and dashboards to check.
- **Artifacts** — logs/exports to capture under `output/`.
- **Rollback** — safe, minimal reversal steps.
- **See also** — [Evidence Map](../evidence_map.md) · [Proof Archive](../proof/README.md) · [Related runbooks](./by-category/)

---

## Runbook Catalog

<!-- RUNBOOKS:INDEX START -->
**Categories:** [bootstrap (4)](./by-category/bootstrap.md) · [burst (1)](./by-category/burst.md) · [dr (5)](./by-category/dr.md) · [ops (4)](./by-category/ops.md)

For detailed metadata (severity, timestamps), see the [full index](./000-INDEX.md).


---

<details>
  <summary><strong>All Runbooks</strong> (14) — click to expand</summary>

- [Bootstrap: GitOps (Argo CD / Flux)](./bootstrap/bootstrap-gitops.md)
- [Bootstrap: NetBox (Source of Truth)](./bootstrap/bootstrap-netbox.md)
- [Bootstrap: RKE2 (On-Prem)](./bootstrap/bootstrap-rke2-install.md)
- [ctrl-01 Day-1 bootstrap & verification](./bootstrap/bootstrap-ctrl01-node.md)
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


<sub>Last generated: 2025-10-19 01:38 UTC</sub>
<!-- RUNBOOKS:INDEX END -->

---

### 📂 Related
- [HOWTOs](../howto/README.md)
- [ADRs](../adr/README.md)

[Back to Docs Home](../README.md)
