# HybridOps.Studio — Hero + Mermaid (GTV ready)

> Use this snippet in your README to present a 10/10 elevator architecture view with one‑click evidence.

## Hero (PNG)

![HybridOps — Hero Elevator](HybridOps_Hero_Elevator_v10.png)

## Hero (Mermaid)

```mermaid
%% HybridOps.Studio — Hero Elevator (C4 Elevator)
flowchart LR
  %% ------------------------------------------------------------
  %% HERO ELEVATOR: HybridOps.Studio — Multivendor • Multicloud • Automated DR/Burst
  %% ------------------------------------------------------------
  %% Layout direction
  %% We nest three bands as subgraphs: Sites | Hub & Observability | Cloud DR/Burst
  %% Dashed edges represent VPN/Federation/Burst/Replication; Solid edges are primary/control
  %% ------------------------------------------------------------

  %% ========== BAND A: SITES ==========
  subgraph A_BAND[Band A — Sites]
    direction LR

    %% --- Site A (On‑Prem / Proxmox) ---
    subgraph SITE_A[Site A — Proxmox]
      direction LR
      PF_HA[pfSense HA [HA]]
      CSR[CSR1000v (IPsec)]
      PX[Proxmox Cluster [HA]]
      KCP[K8s Control‑Plane (x3) + Workers [HA]]
      CM_PRI[SCCM Primary]
      SQL_WSFC[SQL Server WSFC [WSFC]]
      NAS[Synology NAS]
      PROM_ON[Prometheus (On‑Prem)]
    end

    %% --- EVE‑NG Region with two sub‑sites ---
    subgraph EVENG[EVE‑NG Region]
      direction LR

      subgraph B1[EVE Site B1]
        B1_PF[B1 pfSense (IPsec)]
        B1_RSW[B1 Routers/Switches]
        B1_K8W[B1 K8s Workers (join CP)]
        B1_CM[B1 SCCM Secondary]
        B1_SEG[VRFs: Transit, Corp<br/>VLANs: 10/20/30]
      end

      subgraph B2[EVE Site B2]
        B2_PF[B2 pfSense (IPsec)]
        B2_RSW[B2 Routers/Switches]
        B2_K8W[B2 K8s Workers (join CP)]
        B2_CM[B2 SCCM Secondary]
        B2_SEG[VRFs: Transit, Corp<br/>VLANs: 10/20/30]
      end
    end
  end

  %% ========== BAND B: HUB & OBSERVABILITY ==========
  subgraph B_BAND[Band B — Hub & Observability]
    direction LR
    NCC[Google NCC (Hub‑and‑Spoke)]
    PROM_FED[Prometheus Federation]
    GRAF[Grafana]
    ALERTS[Alerting / Webhooks]
  end

  %% ========== BAND C: CLOUD DR / BURST ==========
  subgraph C_BAND[Band C — Cloud DR / Burst]
    direction LR

    %% --- Azure Spoke ---
    subgraph AZ[Microsoft Azure]
      AZ_CSR[CSR (Spoke)]
      AZ_BURST[K8s Burst Workers [Burst]]
      AZ_DR[Failover Compute [DR]]
      AZ_SQLRO[Read‑Only DB Replica [RO]]
      AZ_BLOB[Blob (Packer Images)]
      PROM_AZ[Prometheus (Azure)]
      AZ_MON[Azure Monitor]
    end

    %% --- GCP Spoke ---
    subgraph GCP[Google Cloud Platform]
      GCP_BURST[K8s Burst Workers [Burst]]
      GCS[GCS (Packer Mirror)]
      PROM_G[Prometheus (GCP)]
    end

    %% --- CI/CD & Images ---
    subgraph CICD[CI/CD & Images]
      JENK[Jenkins (pipelines)]
      GHA[GitHub Actions (CI)]
      PKR[Packer (Linux control + Windows images)]
      TF[Terraform Cloud (state/plans)]
    end
  end

  %% ==================== PRIMARY / CONTROL LINKS (solid) ====================
  PX --- KCP
  CM_PRI --- SQL_WSFC
  NAS --- PX
  PROM_ON --- PX

  B1_RSW --- B1_K8W
  B2_RSW --- B2_K8W

  %% ==================== VPN / FEDERATION / BURST / REPLICATION (dashed) ====================
  %% IPsec: Sites ↔ Hub and EVE ↔ Site A
  CSR -. IPsec .-> NCC
  B1_PF -. IPsec .-> NCC
  B2_PF -. IPsec .-> NCC
  B1_PF -. "IPsec (B1 ↔ Site A)" .-> PF_HA
  B2_PF -. "IPsec (B2 ↔ Site A)" .-> PF_HA

  %% Spoke: NCC -> Azure CSR
  NCC -. Spoke .-> AZ_CSR

  %% Federation: On‑prem → Federation → Azure/GCP Prom
  PROM_ON -. Federation .-> PROM_FED
  PROM_FED -.-> PROM_AZ
  PROM_FED -.-> PROM_G

  %% Burst workers join on‑prem CP
  KCP -. "K8s join (Burst)" .-> AZ_BURST
  KCP -. "K8s join (Burst)" .-> GCP_BURST

  %% DB Read‑only replica
  SQL_WSFC -. "DB Replica (RO)" .-> AZ_SQLRO

  %% Images pipeline
  PKR -. Images .-> AZ_BLOB
  PKR -. Images .-> GCS

  %% Autoscale signal
  AZ_MON -. Autoscale .-> AZ_BURST

  %% ==================== KPIs (as a compact panel) ====================
  subgraph KPIS[KPIs]
    direction TB
    KPI1[RTO ≤ 15 min]
    KPI2[RPO ≤ 5 min]
    KPI3[Packer ≤ 12 min | TF ≤ 10 min]
    KPI4[+2 workers @70% | scale‑in <40%]
  end

  %% ==================== Claims & Evidence IDs ====================
  subgraph CLAIMS[Claims & Evidence (map to README anchors)]
    C1[Product‑led blueprint [E1]]
    C2[Impact: DR/burst drills [E2]]
    C3[Recognition: Galaxy/YouTube [E3][E4]]
  end

  %% ==================== Micro‑flows (numbered) ====================
  subgraph FLOWS[Micro‑flows]
    F1[1) Autoscale → Burst to Azure]
    F2[2) Failover drill (On‑Prem → Azure)]
    F3[3) Images: Packer → Blob/GCS → TF]
    F4[4) Federated Observability → Grafana]
  end

  %% Place KPIs/Claims/Flows “near” the right‑hand side by connecting to hub band (light solid)
  NCC --- KPIS
  NCC --- CLAIMS
  NCC --- FLOWS

  %% ==================== Short URL ====================
  URL[(hybridops.studio/gtv)]
  URL --- CLAIMS

  %% ==================== Styling ====================
  classDef onprem fill:#FFFFFF,stroke:#90A4AE,stroke-width:2,color:#263238;
  classDef eveng  fill:#FFF8E1,stroke:#B0BEC5,stroke-width:2,color:#263238;
  classDef hub    fill:#E8F5E9,stroke:#B0BEC5,stroke-width:2,color:#263238;
  classDef cloudA fill:#E3F2FD,stroke:#B0BEC5,stroke-width:2,color:#263238;
  classDef cloudG fill:#E8F5E9,stroke:#B0BEC5,stroke-width:2,color:#263238;
  classDef panel  fill:#FFFFFF,stroke:#B0BEC5,stroke-width:2,color:#263238;

  class SITE_A,PX,KCP,CM_PRI,SQL_WSFC,NAS,PROM_ON,PF_HA,CSR onprem;
  class EVENG,B1,B2,B1_PF,B1_RSW,B1_K8W,B1_CM,B1_SEG,B2_PF,B2_RSW,B2_K8W,B2_CM,B2_SEG eveng;
  class NCC,PROM_FED,GRAF,ALERTS hub;
  class AZ,AZ_CSR,AZ_BURST,AZ_DR,AZ_SQLRO,AZ_BLOB,PROM_AZ,AZ_MON cloudA;
  class GCP,GCP_BURST,GCS,PROM_G cloudG;
  class CICD,JENK,GHA,PKR,TF panel;
  class KPIS,CLAIMS,FLOWS,URL panel;

```

## Operational Flow (Runbook)

```mermaid
%% HybridOps.Studio — Operational Flow (Runbook)
flowchart LR
  %% ------------------------------------------------------------
  %% OPERATIONAL FLOW — Autoscale & Failover (Runbook excerpt)
  %% ------------------------------------------------------------
  subgraph BURST[Autoscale → Burst to Azure (Happy Path)]
    S1[1) Prometheus ≥ 70% (5 min)]
    S2[2) Azure Monitor rule evaluates/triggers]
    S3[3) CI/CD → Terraform: provision burst workers]
    S4[4) Workers join on‑prem K8s CP over VPN]
    S5[5) (Optional) Packer images pulled from Blob/GCS]
    S1 --> S2 --> S3 --> S4 --> S5
  end

  subgraph FAILBACK[Failback / Scale‑in]
    R1[A) CPU < 40% (15 min)]
    R2[B) Drain workloads; detach burst nodes]
    R3[C) Terraform destroy burst]
    R1 --> R2 --> R3
  end

  %% Evidence anchors (optional clickable labels)
  E1[[Evidence: Jenkins/GHA logs]]
  E2[[Evidence: Grafana dashboards]]
  BURST --- E2
  S3 --- E1

  %% Legend
  L[(Legend: boxes = steps; → = sequence)]

```

---
**Evidence quick-links**
- [E1] Jenkins/GitHub Actions run (burst to Azure)
- [E2] Grafana dashboard (CPU threshold, federation, drill traces)
- [E3] Ansible Galaxy roles (HybridOps.*)
- [E4] YouTube talk/demo — HybridOps.Studio DR/Burst

**Short URL:** `hybridops.studio/gtv`

*Legend*: Solid = primary • Dashed = VPN/Federation/Burst/Replication • Badges: `[HA]` `[WSFC]` `[RO]` `[DR]`
