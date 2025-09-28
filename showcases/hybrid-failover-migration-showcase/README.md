
<!-- ============================================================= -->
# HybridOps.Studio – Automated Cloud Failover Showcase

**Description:** End-to-end automated failover of the Control Node from on‑prem Proxmox to Azure or GCP, chosen dynamically based on available credits.

**Author:** Jeleel Muibi
**Last Updated:** 2025-09-25

<!-- SPDX-License-Identifier: MIT -->
<!-- ============================================================= -->

## Overview
This showcase demonstrates **automated failover** of the **Control Node** (Jenkins, Terraform, Ansible, Packer, CLIs) from **on‑prem (Proxmox VM)** to **Azure or GCP**, chosen **dynamically at runtime** based on **available credits**.

> **Non-optional cloud choice:** A **Decision step** always runs first to **pick the target cloud** based on **higher available credits** (with thresholds and tie‑breakers), then continues with that cloud’s Terraform workflow.

## Architecture (Mermaid)
```mermaid
flowchart TD
    A[On-Prem Control Node VM (Proxmox)] --> B[Packer Build]
    B --> C[Upload Image to Azure Blob (VHD)]
    B --> D[Upload Image to GCP (Compute Image)]
    E[Decision Step: Check Available Credits] -->|Higher Credit| F{Target Cloud?}
    F -->|Azure| G[Terraform Apply: Azure Failover]
    F -->|GCP| H[Terraform Apply: GCP Failover]
    G --> I[Control Node Running in Azure]
    H --> J[Control Node Running in GCP]
    I --> K[Jenkins + Ansible Post-Config]
    J --> K
```

## Decision Flow (Credits‑Aware)
1. **Collect**: Query cost/credit metrics for Azure and GCP (or read pre‑synced metrics).
2. **Normalize**: Convert to common currency/timeframe.
3. **Threshold**: Enforce `MIN_CREDIT` (e.g., £50).
4. **Compare**: Choose higher available credit.
5. **Tie‑breakers**: stability → latency → round‑robin.
6. **Emit**: `TARGET_CLOUD=azure|gcp`, `DECISION_REASON=...`.

## Repository Layout
```
failover/
├─ README.md
├─ decision/
│  ├─ README.md
│  ├─ credits_probe.py
│  ├─ decision_example.sh
│  ├─ config.yaml
│  └─ credits.prom
├─ packer/
│  ├─ README.md
│  ├─ scripts/
│  │  └─ install_tools.sh
│  ├─ failover-to-azure/
│  │  ├─ README.md
│  │  └─ control-node.pkr.hcl
│  └─ failover-to-gcp/
│     ├─ README.md
│     └─ control-node.pkr.hcl
├─ terraform/
│  ├─ README.md
│  ├─ azure-failover/
│  │  ├─ README.md
│  │  ├─ main.tf
│  │  ├─ variables.tf
│  │  └─ outputs.tf
│  └─ gcp-failover/
│     ├─ README.md
│     ├─ main.tf
│     ├─ variables.tf
│     └─ outputs.tf
└─ jenkins/
   ├─ README.md
   └─ Jenkinsfile
```

## Prerequisites
- **On‑prem**: Proxmox VM for Control Node (Ubuntu LTS recommended).
- **Control Node stack**: Jenkins, Terraform, Ansible, Packer, Azure CLI, gcloud SDK.
- **Cloud**: Azure subscription + storage account/container; GCP project + bucket + Compute Image permissions.
- **Credentials**: Least‑privileged identities for billing read + image import + VM create.

## Quick Start
1. **Packer Build & Publish** → Azure VHD + GCP Image.
2. **Decision Step** sets `TARGET_CLOUD`.
3. **Terraform Apply** in `terraform/<cloud>-failover/`.
4. (Optional) **Ansible** post‑config.

## Evidence & Portfolio Tips
- Archive Jenkins logs and decision outputs.
- Commit Mermaid diagrams (auto‑renders on GitHub).
- Record short demos for Packer, Decision, Terraform.

---
