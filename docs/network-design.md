# Network Design — HybridOps.Studio
_Last updated: 2025-09-21 19:53 UTC_

This document describes the **hub-and-spoke hybrid network** for HybridOps.Studio: an on-prem Proxmox core (hosting EVE-NG sub-sites **B1/B2**) connected via **Google NCC (hub)** to **Azure** and **GCP** spokes. It supports **DR/burst**, **policy-driven routing**, and **federated observability** while keeping real addresses out of Git.

---

## Addressing & ASNs (illustrative)
- **ASNs:** Site-A **65010** · B1 **65011** · B2 **65012** · NCC **65000** · Azure **65020** · GCP **65030**
- **K8s (on-prem):** Pods **172.21.0.0/16**, Services **172.22.0.0/16**
- **Cloud workers:** Azure **10.60.0.0/16** · GCP **10.70.0.0/16**
- **RO DB (Azure):** **10.60.20.0/24**
- **Segmentation:** VRFs: **Transit**, **Corp**; VLANs: **10 App**, **20 DB**, **30 Mgmt**

> Addresses are placeholders. Real IPs are resolved at runtime by the pipeline.

---

## Routing, VPN, and HA
- **VPN:** Route-based **IPsec VTI** between each site (Site-A, B1, B2) and **NCC hub**.
- **Dynamic routing:** **eBGP** on all IPsec VTIs; **OSPF** internally in each site.
- **HA:** pfSense/Cisco HA at edges; VRRP/HSRP/CARP as appropriate; STP on L2 segments.
- **Policy controls:** Prefer on-prem for steady-state; burst/failover steered via **BGP communities** / **local-pref**.
- **North-south:** Egress governed by NCC policies; east-west via Transit VRF with route filters.

---

## Observability & Decisioning
- **Prometheus (on-prem)** scrapes on-prem + EVE sub-sites; exports to **Prometheus Federation Core**.
- **Cloud signals:** Azure Monitor / Google Cloud Monitoring supplement federation for burst/DR triggers.
- **Decision Service:** Consumes metrics + SLOs + credit/cost signals; triggers **CI/CD** to scale or fail over.

---

## Test Matrix (minimum)
- **VPN:** IPsec up on Site-A↔NCC, B1↔NCC, B2↔NCC; Azure/GCP spokes up.
- **Routing:** eBGP adjacencies established; route exchange for K8s Pods/Services and RO DB.
- **Segmentation:** Inter-VRF isolation enforced; only approved Transit routes leaked to Corp.
- **DR/Burst:** Policy flip sends new flows to Azure/GCP workers; RO DB reachable; latency within SLO.

---

## Mermaid Diagram (renders on GitHub)
> **Legend:** Solid = control/data · Dashed = IPsec/eBGP

```mermaid
flowchart LR
  %% ===== On-Prem =====
  subgraph OnPrem["On-Prem (Site A) [HA]"]
    PVE["Proxmox Cluster [HA]"]
    PF["pfSense [HA]"]
    CSR["Cisco CSR (IPsec)"]
    KCP["K8s Control Plane x3 [HA]"]
    KW["K8s Workers"]
    SQL["SQL Server (WSFC)"]
    NAS["Synology NAS"]
    PROM_ON["Prometheus (scrapes on-prem + EVE)"]
    GRAF["Grafana (on-prem)"]
  end

  %% ===== EVE-NG Region =====
  subgraph EVE["EVE-NG Region"]
    subgraph B1["Sub-site B1"]
      PF_B1["pfSense Edge (IPsec)"]
      RSW_B1["Routers & Switches"]
      KW_B1["K8s Workers"]
    end
    subgraph B2["Sub-site B2"]
      PF_B2["pfSense Edge (IPsec)"]
      RSW_B2["Routers & Switches"]
      KW_B2["K8s Workers"]
    end
  end

  %% ===== Hub / Federation / Decision =====
  subgraph HUB["Google NCC (Hub)"]
    NCC["NCC Control"]
    PROM_CORE["Prometheus Federation Core"]
    DEC["Decision Service (policy-governed)"]
  end

  %% ===== Azure =====
  subgraph Azure["Azure (DR/Burst)"]
    CSR_AZ["CSR Spoke"]
    K8S_AZ["K8s Burst Workers"]
    RO_DB["Read-Only DB Replica [RO]"]
    DR_VM["Failover Compute [DR]"]
    AZ_MON["Azure Monitor (signals)"]
    PROM_AZ["Prometheus"]
    BLOB["Blob (Packer images)"]
  end

  %% ===== GCP =====
  subgraph GCP["GCP (Burst)"]
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

  %% ===== Primary (solid) flows =====
  PVE --> KCP
  KCP --> KW
  KCP --> SQL
  PROM_ON --> PROM_CORE
  GRAF --> PROM_CORE
  TFC --> PVE
  JENK --> PACK
  GHA --> PACK
  PACK --> BLOB
  PACK --> GCS

  %% ===== Overlays (dashed) =====
  PF -. "IPsec (Site-A to Hub)" .-> NCC
  CSR -. "IPsec (Site-A to Hub)" .-> NCC
  PF_B1 -. "IPsec (to Hub)" .-> NCC
  PF_B2 -. "IPsec (to Hub)" .-> NCC
  PF_B1 -. "IPsec (B1 to Site-A)" .- PF
  PF_B2 -. "IPsec (B2 to Site-A)" .- PF
  PF_B1 -. "IPsec (B1↔B2)" .- PF_B2

  PROM_CORE -. "Federation" .-> PROM_AZ
  PROM_CORE -. "Federation" .-> PROM_GCP
  KCP -. "Burst" .-> K8S_AZ
  KCP -. "Burst" .-> K8S_GCP
  SQL -. "Replication" .-> RO_DB

  AZ_MON -. "Signals" .-> DEC
  GCP_MON -. "Signals" .-> DEC
  PROM_CORE --> DEC

  DEC -. "Trigger" .-> K8S_AZ
  DEC -. "Trigger" .-> K8S_GCP
  DEC -. "Trigger" .-> DR_VM
  DEC -. "Trigger" .-> TFC
```
