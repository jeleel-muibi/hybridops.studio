# Architecture Hero — Layout Specification (draw.io / diagrams.net)

**Goal:** One-page overview: on-prem Proxmox hosting EVE-NG sub-sites, hub-and-spoke via Google NCC to Azure/GCP, and **Prometheus-driven DR/burst** with a **policy-governed Decision Service**. KPIs and Evidence anchors are prominent.

## Canvas
- **Top band:** Title + KPI badges (**RTO 15m · RPO 5m · Packer 12m · Terraform 10m · Autoscale +2@70%**) + short URL (optional).
- **Middle left:** **On-Prem (Site A / Proxmox)** cluster.
- **Center:** **Google NCC (Hub)** + thin **Observability Bus** line (anchors federation).
- **Middle right:** **Azure** (top) and **GCP** (bottom) clouds.
- **Bottom band:** **CI/CD & Images** lane with flows to Proxmox and cloud storage.

## Content (boxes)
- **On-Prem (Site A / Proxmox):** pfSense **[HA]**; Cisco CSR (IPsec); K8s control-plane x3 **[HA]** + workers; Windows/Linux nodes; SQL Server **WSFC**; SCCM Primary; Synology NAS; **Prometheus (on-prem)**; **Grafana (on-prem)**.
- **EVE-NG Region (B1 / B2):** pfSense edge (IPsec); routers/switches (CSR1000v, Nexus, Arista vEOS) + FortiGate; K8s workers (join Site-A CP); DC02; SCCM Secondary; End-user segment.
- **Hub & Observability:** **Google NCC (Hub)**; **Prometheus Federation Core**; Grafana dashboards; Alerting/Webhooks; (thin “observability bus” element).
- **Azure (DR/Burst):** CSR Spoke; **K8s burst workers**; **Failover compute [DR]**; **Read-only DB replica [RO]**; Blob (Packer images); **Prometheus**; **Azure Monitor** (signals).
- **GCP (Burst):** **K8s burst workers**; GCS (Packer mirror); **Prometheus**; (GCP Managed Service for Prometheus acceptable).
- **CI/CD & Images:** Jenkins; GitHub Actions; **Packer** (Windows + control node images); **Terraform Cloud** (plans/state); **Decision Service (policy-governed)** block with inputs/outputs.

## Lines & Labels
- **Solid:** primary control/data.
- **Dashed:** **IPsec / Federation / Burst / Replication** (label each segment).
- **Key edges to include:**
  - **Site-A ↔ B1 ↔ B2** (IPsec between EVE-NG sub-sites; both to Site-A).
  - **Sites → NCC** (IPsec to hub); **NCC → Azure** (spoke).
  - **KCP → Burst workers** (to AKS/GKE).
  - **SQL WSFC → RO DB (Azure)** (replication).
  - **Prom (on-prem) → Federation Core → Cloud Prom** (federation arrows run along the “observability bus”).
  - **Azure Monitor / GCP MSP → Decision Service** (supplemental cloud signals).
  - **Decision Service → Pipelines** (Jenkins/GitHub Actions/Terraform/Packer) → **Autoscale / Failover** actions.

## Badges & Anchors
- Use badges: **[HA] [WSFC] [RO] [DR]** where applicable.
- Add small **E1–E4** evidence markers near relevant boxes/lanes (clickable in README/Evidence Map).

## Iconography
- Prefer official vendor/product SVGs embedded in the `.drawio` for crisp export (Azure, GCP, Kubernetes, Prometheus, Grafana, pfSense, Cisco).
- Keep consistent size; align to grid; avoid overlapping labels.

## Export
- **PNG 3840 px width (4K)**, transparent background.
- Keep a matching **SVG** if needed for print.
- File names (neutral):
  - Source: `docs/diagrams/flowcharts/architecture-hero.drawio`
  - Render: `docs/diagrams/flowcharts/renders/architecture-hero.png`
