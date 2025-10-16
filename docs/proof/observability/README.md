# Proof Archive

Curated operational evidence supporting **HybridOps.Studio** architecture and KPI guarantees.  
Each section links to focused artifacts — screenshots, logs, and exports — that demonstrate measurable reliability, automation, and auditability.

---

## KPI Evidence

- **RTO ≤ 15 min** — [**DR KPIs**](./observability/#dr-kpis)
- **RPO ≤ 5 min** — [**SQL RPO / Read-Only**](./sql-ro/#rpo--ro)
- **Packer ≤ 12 min** — [**Runtime Images**](./images-runtime/#packer-builds)
- **Terraform ≤ 10 min** — [**CI Runs**](./others/#terraform-apply)
- **Autoscale (+2 @ 70% / scale-in < 40%)** — [**Autoscaling**](./observability/#autoscaling)

---

## Architecture Evidence

- **ctrl-01 (Jenkins Controller)** — [**Bootstrap Proof**](./ctrl01/latest/)  
  *Zero-touch controller provisioning, service validation, and evidence generation.*

- **NCC hub-and-spoke** — [**NCC**](./ncc/)
- **Prometheus federation (on-prem ↔ cloud)** — [**Observability**](./observability/#federation)
- **SQL WSFC → Cloud Read-Only for DR** — [**SQL RO**](./sql-ro/)
- **Runtime images mirrored to Blob / GCS** — [**Images Runtime**](./images-runtime/)
- **Policy-driven burst / failover** — [**Decision Service**](./decision-service/)
- **S2S VPN (sites ↔ clouds)** — [**VPN**](./vpn/)

---

## Gallery Shortcuts

| Subsystem | Summary |
|------------|----------|
| Observability | [`observability/`](./observability/) |
| SQL RO | [`sql-ro/`](./sql-ro/) |
| Runtime Images | [`images-runtime/`](./images-runtime/) |
| NCC | [`ncc/`](./ncc/) |
| Decision | [`decision-service/`](./decision-service/) |
| Miscellaneous | [`others/`](./others/) |

---

**Navigate:** [Evidence Map](../evidence_map.md) · [Project README](../../README.md)
