
<!-- ============================================================= -->
# Packer – GCP Failover Image

**Description:** Publishes a Compute Image into a GCP Project for VM creation.

**Author:** Jeleel Muibi
**Last Updated:** 2025-09-25

<!-- SPDX-License-Identifier: MIT -->
<!-- ============================================================= -->

## Inputs
- GCP Service Account with minimal roles (image import + Compute).
- GCS bucket for intermediates (if used).

## Output
- GCP Compute Image ready for Terraform.

## Notes
- Label images with `env`, `version`, `source`.
- Keep import logs for evidence.
