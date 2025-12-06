# Windows Administration Showcase

Automated provisioning/configuration: **AD**, **GPO**, **SCCM** app deployment, optional PXE workflows using Ansible + PowerShell.

- **Maintainer:** HybridOps.Studio
- **Last Updated:** 2025-09-18
- **SPDX-License-Identifier:** MIT

## Layout
```
ansible-playbooks/
powershell-scripts/
terraform-configs/
diagrams/
```

## How to Run
1) Provision infra (optional) with Terraform
2) Apply Ansible playbooks for AD/GPO/SCCM
3) Validate with PowerShell checks
