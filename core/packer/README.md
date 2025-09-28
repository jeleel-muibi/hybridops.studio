# Packer Templates – HybridOps.Studio

## Overview

This folder contains Packer templates used to build golden images for Windows and Linux environments. These images are pre-configured with essential components and optimized for fast provisioning in HybridOps.Studio.

## Structure

- `windows/`: Packer templates for Windows Server images (e.g., AD, SQL, SCCM).
- `linux/`: Packer templates for Linux images (e.g., kubeadm, monitoring agents).

## Integration

Packer images are consumed by Terraform modules and configured further via Ansible. They serve as the base for VM provisioning across on-prem and cloud environments.

## Purpose

To ensure consistent, secure, and reproducible base images for hybrid infrastructure automation, reducing configuration drift and provisioning time.
