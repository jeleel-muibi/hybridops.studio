# PowerShell Automation – HybridOps.Studio

## Overview

This folder contains PowerShell scripts and modules used to automate Windows Server operations within the HybridOps.Studio hybrid infrastructure. These scripts support domain join, SQL Server installation, clustering, and other Windows-specific tasks that complement Ansible and Terraform provisioning.

## Structure

- `scripts/`: Standalone PowerShell scripts for operational tasks.
- `modules/`: Reusable PowerShell modules for advanced automation.
- `windows/`: Domain-specific scripts for Windows Server roles and services.

## Integration

PowerShell scripts are triggered via Ansible (`win_shell`, `win_command`) or CI/CD pipelines (Jenkins). They operate on provisioned Windows VMs and integrate with Packer-built images and Terraform outputs.

## Purpose

To provide robust, scriptable automation for Windows infrastructure components in hybrid environments, ensuring consistency, repeatability, and enterprise-grade configuration.
