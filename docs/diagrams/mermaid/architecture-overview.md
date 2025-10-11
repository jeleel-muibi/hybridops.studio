# Architecture Overview (Mermaid)

> **Navigate:** [Docs Home](../README.md) · [Network Design](../network/README.md)

## Network Core (Single Hub)
> **Legend:** solid = control/data · dotted = IPsec/BGP

```mermaid
flowchart TB
  subgraph OnPrem["On‑prem (Site A)"]
    direction TB
    EDGES["EVE‑NG Edges (B1/B2)"]
    PVE["Proxmox"]
    KCP["RKE2 Control‑plane"]
    PVE --> KCP
  end

  subgraph GCP["GCP Hub"]
    direction TB
    HAVPN["HA VPN"]
    CR["Cloud Router (BGP)"]
    HUB["Hub VPC"]
    NCC["NCC (Hub)"]
    GKE["GKE spokes"]
    HAVPN --> CR --> HUB --> NCC --> GKE
  end

  subgraph Azure["Azure Spoke"]
    direction TB
    AZGW["VPN Gateway (BGP)"]
    AKS["AKS / VNet"]
    AVD["AVD"]
    AZGW --> AKS --> AVD
  end

  %% Tunnels
  EDGES -. IPsec+BGP .-> HAVPN
  AZGW  -. Inter‑cloud BGP .-> CR
```

---

## Operations & Workloads (Windows, GitOps, DR)
> **Legend:** solid = control/data · dotted = GitOps/Config/Backups/Signals

```mermaid
flowchart TB
  %% ===== Workloads (on‑prem) =====
  subgraph Workloads["Workloads"]
    direction TB
    KCP["RKE2 Control‑plane"]
    KW["RKE2 Workers"]
    WIN["Windows AD / Admin Targets"]
    PG["PostgreSQL (Primary)"]
    KCP --> KW
  end

  %% ===== Tooling =====
  subgraph Tooling["Observability & CI/CD"]
    direction TB
    PFED["Prometheus Federation"]
    GRAF["Grafana"]
    ALERT["Alerting"]
    DEC["Decision Service (policy)"]
    TF["Terraform"]
    PKR["Packer"]
    ANS["Ansible / PowerShell"]
    PFED --> GRAF --> ALERT
    PFED -. signals .-> DEC
    DEC  -. triggers .-> TF
  end

  %% ===== Cloud targets =====
  subgraph Clouds["Cloud targets"]
    direction TB
    AKS["AKS"]
    GKE["GKE"]
  end

  %% ===== Artifacts =====
  subgraph Artifacts["Images & backups"]
    direction TB
    BLOB["Azure Blob"]
    GCS["GCS"]
  end

  %% Provision & GitOps
  TF --> AKS
  TF --> GKE
  KCP -. GitOps .-> AKS
  KCP -. GitOps .-> GKE

  %% Admin & config
  ANS -. WinRM .-> WIN
  ANS -. K8s mods .-> KCP

  %% Backups & images
  PG  -. WAL‑G .-> BLOB
  PG  -. WAL‑G .-> GCS
  PKR --> BLOB
  PKR --> GCS
```

---
---

## See also
- **Security & Compliance (summary)** — see [Network Design › Security](../network/README.md#security--compliance-summary)
- **Test Matrix (minimum)** — see [Network Design › Test Matrix](../network/README.md#test-matrix-minimum)
- **Alternative Topology (Dual Hubs)** — see [Network Design › Appendix — Dual Hubs](../network/README.md#appendix--dual-hubs-reference)
