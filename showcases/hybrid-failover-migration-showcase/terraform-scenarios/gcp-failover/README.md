
<!-- ============================================================= -->
# Terraform – GCP Failover Stack

**Description:** Provisions the Control Node VM from the published Compute Image.

**Author:** Jeleel Muibi
**Last Updated:** 2025-09-25

<!-- SPDX-License-Identifier: MIT -->
<!-- ============================================================= -->

## Flow
1. Resolve **image name** (latest by label or input version).
2. Create **VM instance** from image.
3. Output connection details.

## Outputs
- `control_node_ip`
- `instance_id`
- `version`

## Notes
- Apply labels for visibility and cost tracking.
