# CI/CD Automation

## Overview
This folder contains automation pipelines and orchestration logic for continuous integration and continuous delivery (CI/CD) across hybrid and cloud-native environments.

## Structure
- `jenkins/`: Jenkins pipelines for provisioning, deployment, and failover orchestration.
- `github-actions/`: GitHub Actions workflows for budget polling, DNS updates, and GitOps triggers.

## Integration
- Ties into Terraform provisioning and Ansible orchestration.
- Triggers failover scenarios and cloud bursting based on monitoring signals.
- Supports GitOps workflows for AKS/GKE clusters.

## Purpose
To demonstrate enterprise-grade CI/CD automation that integrates infrastructure provisioning, configuration management, and hybrid failover orchestration.
