
<!-- ============================================================= -->
# Terraform – Azure Failover Stack

**Description:** Provisions the Control Node VM from the VHD in Azure Blob.

**Author:** Jeleel Muibi
**Last Updated:** 2025-09-25

<!-- SPDX-License-Identifier: MIT -->
<!-- ============================================================= -->

## Flow
1. Resolve **VHD URL** (SAS) for desired version.
2. Create **Image** from VHD.
3. Create **VM** from Image.
4. Output public/private IP.

## Outputs
- `control_node_ip`
- `vm_id`
- `version`

## Notes
- Enforce tags: `project=hybridops.studio`, `component=control-node`, `stage=failover`.
