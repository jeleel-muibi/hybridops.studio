
<!-- ============================================================= -->
# Terraform – Cloud Provisioning

**Description:** Instantiates the Control Node from the latest published image in the chosen cloud.

**Author:** Jeleel Muibi
**Last Updated:** 2025-09-25

<!-- SPDX-License-Identifier: MIT -->
<!-- ============================================================= -->

## Scope
- Minimal stacks per cloud to create networking prereqs (or reference existing) and boot a Control Node VM from image.
- Apply tags/labels for cost tracking.
- Output connection details for post‑provision steps.

## Common Variables
- `image_version`
- `vm_size`
- `admin_username`
- `ssh_public_key`
- `tags` / `labels`

> Jenkins sets these via environment variables.
