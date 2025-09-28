# Ansible Orchestration (HybridOps.Studio)

## Overview
This folder contains the core orchestration logic for HybridOps.Studio using Ansible. It drives post-provisioning configuration across Windows, Linux, and network domains, integrating with Terraform-provisioned infrastructure and CI/CD pipelines.

## Structure
- `roles/`: Reusable Ansible roles for system configuration, Kubernetes setup, and service deployment.
- `inventories/`: Environment-specific host definitions (dev, staging, prod) including emulated routers and switches.
- `windows/`: Playbooks for configuring Windows Server components (AD, SQL Server, SCCM, DFS).
- `linux/`: Playbooks for Linux automation (SSH hardening, kubeadm, monitoring agents).
- `network/`: Playbooks for configuring emulated network devices (CSR1000v, pfSense) via SSH.

## Integration
- Triggered by Jenkins or GitHub Actions.
- Consumes Terraform outputs at runtime (`terraform/output/terraform_outputs.json`).
- Can invoke PowerShell scripts for Windows automation and Bash scripts for Linux tasks.

## Purpose
Ansible serves as the orchestration backbone, ensuring consistent configuration across hybrid environments and enabling automated failover, migration, and service deployment.
