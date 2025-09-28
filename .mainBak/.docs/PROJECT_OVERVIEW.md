# Project Overview

**Environment Guard Framework (EGF)**

**Author:** Jeleel Muibi | **Last Updated:** 2025-09-10 | **Classification:** Project Overview | HybridOps.Studio

---

# Infrastructure Automation Portfolio

## Overview

This project showcases advanced, modular Infrastructure-as-Code (IaC) and automation practices across on-premises, hybrid, and cloud environments. It covers secure inventory management, network automation (including hybrid cloud), Windows and Linux server automation, infrastructure provisioning with Terraform, and modern container orchestration using Kubernetes and Docker Swarm.

Each subsystem is self-contained, with dedicated documentation and best practices for clarity, reusability, and scalability.

---

## Project Structure

```
├── README.md
├── deployments/
│   ├── README.md     # <-- Index/table of deployment scripts
│   ├── deploy.sh
│   ├── deploy_network.sh
│   ├── deploy_sql.sh
│   └── ...
├── docs/
├── inventories/
├── networkAutomation/
├── windowsAutomation/
├── linuxAutomation/
├── terraform-infra/
├── serverAutomation/
├── containerization/
├── common/
│   ├── script/
│   │   ├── parse_yaml.py
│   │   └── common_utils.sh
│   └── ...
└── ...
```

---

## Subsystems

### [Inventories](./inventories/README.md)
Secure, dynamic inventory management for all environments and device types, featuring variable abstraction, Ansible Vault encryption, and support for both cloud and on-premises hosts.
Environments such as `dev` and `staging` are used for best-practice separation and safe deployment.

### [Network Automation](./networkAutomation/README.md)
Automates configuration, compliance, and monitoring of network devices—including hybrid cloud connectivity (e.g., Azure BGP/ExpressRoute via CSR1000v). Includes playbooks, roles, and diagrams for secure, extensible network operations.

### [Windows Automation](./windowsAutomation/README.md)
Provisioning, configuration, and application deployment automation for Windows servers using Ansible, PowerShell, and WinRM. Covers SQL Server, clustering, and hardening.

### [Linux Automation](./linuxAutomation/README.md)
Automates Linux server lifecycle management, including provisioning, configuration, security, and application deployment.

### [Terraform Infra](./terraform-infra/README.md)
Multi-cloud and hybrid infrastructure provisioning and lifecycle management using Terraform.

### [Server Automation](./serverAutomation/README.md)
Centralized scripts for day-to-day server administration across platforms.

### [Containerization](./containerization/README.md)
Deploys and manages container workloads with Docker, Docker Swarm, and Kubernetes. Supports both standalone and orchestrated environments.

---

## Key Diagrams

Architectural overviews, network topologies, and workflow diagrams are in [`docs/`](./docs/).

Example:

![Project Topology](docs/topology.png)
![Project Topology](docs/topology(network_design).png)

---

## How to Deploy

Run automation using deployment scripts in the `deployments/` directory for consistency and reliability:

```bash
# All-in-one deployment
./deployments/deploy.sh dev

# Targeted deployments
./deployments/deploy_network.sh dev
./deployments/deploy_sql.sh staging
```

- All inventories are generated dynamically before playbooks are executed.
- For details on each script, see comments at the top of each script.

---

## Inventory Generation

When generating inventory, specify **one or more environments**:
- Single: `dev`
- Multiple: `dev,staging`

Leaving the input blank will cause the playbook to fail and prompt you to specify at least one environment.

See [inventories/README.md](inventories/README.md) for advanced usage.

---

## Vault Handling

All secrets are encrypted with Ansible Vault. Scripts and playbooks expect a vault password provided at runtime with `--ask-vault-pass`.
If not using encryption, you may remove this flag.

---

## Utility Scripts

Helper scripts for parsing and validation are in `common/script/` and are used internally.
They are not intended for direct execution by end users.

---

## Getting Started

1. Review each subsystem’s `README.md` for prerequisites and usage.
2. See diagrams in `docs/` for architectural context.
3. Secrets and sensitive variables are managed with Vault—see inventory docs for details.
4. Use the scripts in `deployments/` for all deployments.

---

## More Information

- [Inventory documentation](./inventories/README.md)
- [Deployment scripts and troubleshooting](./deployments/README.md)

---

## About the Author

By Jeleel Muibi, infrastructure automation specialist.
Built to demonstrate advanced DevOps, SRE, and platform engineering practices for enterprise and cloud-native environments.

---
---

## Pipeline Context

This component is part of the Environment Guard Framework (EGF) pipeline.

For full pipeline flow and visuals, see:
- [docs/egf_pipeline.md](./docs/egf_pipeline.md)

Related roles:
- [env_guard](./common/env_guard/)
- [gen_inventory](./common/gen_inventory/)
- [host_selector](./common/host_selector/)
- [ip_mapper](./common/ip_mapper/)
- [connectivity_test](./common/connectivity_test/)

---
