# Terraform Infrastructure Provisioning (HybridOps.Studio)

## Overview
This folder contains all Terraform logic for provisioning infrastructure across on-prem and cloud environments. It supports hybrid networking, Kubernetes clusters, cloud bursting, and failover scenarios.

## Structure
- `modules/`: Reusable modules for compute, networking, VPN, Kubernetes, and cloud resources.
- `environments/`: Environment-specific deployments (on-prem dev/staging/prod, cloud prod targets).
- `cloud-showcases/`: Standalone AKS and GKE demos showcasing GitOps, autoscaling, and managed identity.
- `scenarios/`: Ephemeral failover and migration tests with isolated state.
- `backend-configs/`: Terraform Cloud workspace configurations (dev, staging, prod, scenario).
- `output/`: Runtime outputs consumed by Ansible (`terraform_outputs.json`).

## Integration
- Works with Ansible for post-provisioning.
- Integrated with Jenkins for CI/CD.
- Supports budget-aware cloud selection via decision-service.

## Purpose
Terraform provisions the foundational infrastructure for HybridOps.Studio, enabling hybrid orchestration, cloud-native showcases, and disaster recovery testing.
