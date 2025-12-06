# Changelog

All notable changes to the HybridOps Studio project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog. com/en/1.0. 0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2. 0.0.html).

## [0.1.0-sdn] - 2025-12-06

### Added
- Complete SDN infrastructure deployment across 6 environments
- Reusable Terraform module for Proxmox SDN (infra/terraform/modules/proxmox/sdn)
- Terragrunt-based DRY configuration management
- Centralized version control in root.hcl
- Enterprise-grade naming conventions (onprem site)

### Environments
- Management (VLAN 10): 10.10.0.0/24 - Infrastructure management plane
- Observability (VLAN 11): 10.11.0.0/24 - Monitoring and metrics platform
- Development (VLAN 20): 10. 20.0.0/24 - Development workloads
- Staging (VLAN 30): 10.30.0.0/24 - Pre-production testing
- Production (VLAN 40): 10.40.0.0/24 - Production workloads
- Network Lab (VLAN 50): 10. 50.0.0/24 - EVE-NG and network testing

### Technical Details
- Terraform version: >= 1.5.0
- Proxmox provider: bpg/proxmox v0.87.0
- State backend: Local filesystem
- Validation: 6/6 environments passing
- Deployment: 6/6 environments successful

### Architecture
- VLAN-based network segmentation
- Isolated workload environments
- Shared management and observability planes
- Gateway configuration for future routing
- DNS server placeholders for each network

## [Unreleased]

### Planned
- Phase 2: IPAM configuration module
- Phase 2: LXC container deployment module
- Phase 2: VM deployment module
- Phase 3: Application deployment (PostgreSQL, control node)
- Phase 4: Observability stack (Prometheus, Grafana, Loki)
