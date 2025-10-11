# Proof Archive

Curated evidence supporting HybridOps.Studio’s KPIs and architecture. Each entry links to a focused topic with screenshots, logs, and exports.

---

## KPI Evidence

- **RTO ≤ 15m** — **[DR KPIs](./observability/README.md#dr-kpis)**
- **RPO ≤ 5m** — **[SQL RPO / Read‑Only](./sql-ro/README.md#rpo--ro)**
- **Packer ≤ 12m** — **[Runtime Images](./images-runtime/README.md#packer-builds)**
- **Terraform ≤ 10m** — **[CI Runs](./others/README.md#terraform-apply)**
- **Autoscale +2@70% (scale‑in <40%)** — **[Autoscaling](./observability/README.md#autoscaling)**

---

## Architecture Evidence

- **NCC hub‑and‑spoke** — **[NCC](./ncc/README.md)**
- **Prometheus federation (on‑prem ↔ cloud)** — **[Observability](./observability/README.md#federation)**
- **SQL WSFC → cloud read‑only for DR** — **[SQL RO](./sql-ro/README.md)**
- **Runtime images mirrored to Blob/GCS** — **[Images Runtime](./images-runtime/README.md)**
- **Policy‑driven burst/failover** — **[Decision Service](./decision-service/README.md)**
- **S2S VPN (sites ↔ clouds)** — **[VPN](./vpn/README.md)**

---

## Gallery Shortcuts

- Observability — [`observability/images`](./observability/images/)
- SQL RO — [`sql-ro/images`](./sql-ro/images/)
- Runtime images — [`images-runtime/images`](./images-runtime/images/)
- NCC — [`ncc/images`](./ncc/images/)
- Decision — [`decision-service/images`](./decision-service/images/)
- Miscellaneous — [`others/assets`](./others/assets/)

---

**Navigate:** [Evidence Map](../evidence_map.md) · [Project README](../../README.md)
