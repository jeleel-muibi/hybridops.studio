
<!-- ============================================================= -->
# Packer – Azure Failover Image

**Description:** Produces a VHD and uploads it to Azure Blob for VM creation.

**Author:** Jeleel Muibi
**Last Updated:** 2025-09-25

<!-- SPDX-License-Identifier: MIT -->
<!-- ============================================================= -->

## Inputs
- Azure Service Principal.
- Storage Account + Container for VHDs.

## Output
- VHD in Blob Storage, referenced by Terraform to create a Managed Disk and VM.

## Notes
- Prefer SAS tokens with expiry for uploads.
- Tag artifacts with `env`, `version`, `source`.
