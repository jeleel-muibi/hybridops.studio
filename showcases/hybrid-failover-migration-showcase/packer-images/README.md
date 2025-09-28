
<!-- ============================================================= -->
# Packer – Image Build & Publish

**Description:** Builds a cloud‑ready Control Node image and publishes it to Azure and GCP.

**Author:** Jeleel Muibi
**Last Updated:** 2025-09-25

<!-- SPDX-License-Identifier: MIT -->
<!-- ============================================================= -->

## Scope
- Build the **Control Node** image from the on‑prem VM baseline.
- Publish outputs to **Azure Blob (VHD)** and **GCP (Compute Image)**.
- Version images with timestamps or Git commit SHAs.

## Key Considerations
- Use cloud‑init / provisioning scripts for first‑boot tasks.
- Install: Jenkins agent, Terraform, Ansible, Packer, Azure CLI, gcloud SDK.
- Avoid baking secrets; inject at runtime.

## Outputs
- `azure/control-node-<version>.vhd` in Blob Storage.
- `gcp/control-node-<version>` Compute Image.
