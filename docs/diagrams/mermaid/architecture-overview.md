## Mermaid Diagram (renders on GitHub)
> **Legend:** Solid = control/data · Dashed = IPsec/eBGP

```mermaid
flowchart LR
  %% ===== On-Prem =====
  subgraph OnPrem["On-Prem (Site A) [HA]"]
    PVE["Proxmox [HA]"]
    PF["pfSense [HA]"]
    K8S["K8s Control Plane x3 + Workers [HA]"]
    SQL["SQL Server (WSFC)"]
    PROM_ON["Prometheus (on-prem)"]
  end

  %% ===== EVE-NG =====
  subgraph EVE["EVE-NG Region (B1/B2)"]
    EDGE["pfSense Edges (IPsec)"]
    WORKERS["K8s Workers + routers/switches"]
  end

  %% ===== Hub & Decision =====
  subgraph HUB["Google NCC (Hub)"]
    NCC["NCC Hub"]
    PROM_FED["Prometheus Federation Core"]
    DEC["Decision Service (policy-governed)"]
  end

  %% ===== Azure =====
  subgraph AZ["Azure (DR/Burst)"]
    K8S_AZ["K8s Burst Workers"]
    RO_DB["Read-Only DB [RO]"]
    DR["Failover Compute [DR]"]
    AZ_MON["Azure Monitor (signals)"]
    PROM_AZ["Prometheus"]
    BLOB["Blob (Packer images)"]
  end

  %% ===== GCP =====
  subgraph GC["GCP (Burst)"]
    K8S_GCP["K8s Burst Workers"]
    GCS["GCS (Packer mirror)"]
    PROM_GCP["Prometheus"]
    GCP_MON["GCP Monitoring (signals)"]
  end

  %% ===== CI/CD & Images =====
  subgraph CICD["CI/CD & Images"]
    JENK["Jenkins"]
    GHA["GitHub Actions"]
    PACK["Packer"]
    TFC["Terraform Cloud"]
  end

  %% Primary (solid)
  PVE --> K8S
  K8S --> SQL
  PROM_ON --> PROM_FED
  TFC --> PVE
  JENK --> PACK
  GHA --> PACK
  PACK --> BLOB
  PACK --> GCS

  %% Overlays (dashed)
  PF -. "IPsec" .-> NCC
  EDGE -. "IPsec" .-> NCC
  PROM_FED -. "Federation" .-> PROM_AZ
  PROM_FED -. "Federation" .-> PROM_GCP
  K8S -. "Burst" .-> K8S_AZ
  K8S -. "Burst" .-> K8S_GCP
  SQL -. "Replication" .-> RO_DB
  AZ_MON -. "Signals" .-> DEC
  GCP_MON -. "Signals" .-> DEC
  PROM_FED --> DEC
  DEC -. "Trigger" .-> K8S_AZ
  DEC -. "Trigger" .-> K8S_GCP
  DEC -. "Trigger" .-> DR
```
