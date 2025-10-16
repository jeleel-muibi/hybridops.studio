# Proof Archive

Curated operational evidence supporting **HybridOps.Studio** architecture and KPI guarantees.  
Each section links to focused artifacts — screenshots, logs, and exports — that demonstrate measurable reliability, automation, and auditability.

---

## KPI Evidence

- **RTO ≤ 15 min** — [**DR KPIs**](./observability/README.md#dr-kpis)
- **RPO ≤ 5 min** — [**SQL RPO / Read-Only**](./sql-ro/README.md#rpo--ro)
- **Packer ≤ 12 min** — [**Runtime Images**](./images-runtime/README.md#packer-builds)
- **Terraform ≤ 10 min** — [**CI Runs**](./others/README.md#terraform-apply)
- **Autoscale (+2 @ 70% / scale-in < 40%)** — [**Autoscaling**](./observability/README.md#autoscaling)

---

## Architecture Evidence

- **ctrl-01 (Jenkins Controller)** — [**Bootstrap Proof**](./ctrl01/latest/README.md)  
  *Zero-touch controller provisioning, service validation, and evidence generation.*
- **NCC hub-and-spoke** — [**NCC**](./ncc/README.md)
- **Prometheus federation (on-prem ↔ cloud)** — [**Observability**](./observability/README.md#federation)
- **SQL WSFC → Cloud Read-Only for DR** — [**SQL RO**](./sql-ro/README.md)
- **Runtime images mirrored to Blob / GCS** — [**Images Runtime**](./images-runtime/README.md)
- **Policy-driven burst / failover** — [**Decision Service**](./decision-service/README.md)
- **S2S VPN (sites ↔ clouds)** — [**VPN**](./vpn/README.md)

---

## Gallery Shortcuts

| Subsystem | Path |
|------------|------|
| Observability | [`observability/images`](./observability/images/) |
| SQL RO | [`sql-ro/images`](./sql-ro/images/) |
| Runtime Images | [`images-runtime/images`](./images-runtime/images/) |
| NCC | [`ncc/images`](./ncc/images/) |
| Decision | [`decision-service/images`](./decision-service/images/) |
| Miscellaneous | [`others/assets`](./others/assets/) |

---

**Navigate:** [Evidence Map](../evidence_map.md) · [Project README](../../README.md)
