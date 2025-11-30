# Proof: Packer Build — windows-server-2022

**Generated:** 2025-11-29T171633Z
**Status:** SUCCESS
**VMID:** 9100
**Build Duration:** 4 minutes 52 seconds

## VM Configuration

| Property | Value |
|----------|-------|
| Name | `windows-server-2022-template` |
| OS Type | `win10` |
| CPU | 1 socket(s) × 4 core(s) |
| Memory | 8192 MB |
| Disk (scsi0) | `local-lvm:base-9100-disk-0,cache=none,replicate=0,size=60G` |
| Network (net0) | `virtio=62:5B:B2:FD:72:37,bridge=vmbr0` |
| Template Flag | 1 |

## Post-Build Validation

**Status:** passed

| Test | Status |
|------|--------|
| Guest Agent | working |
| Connectivity | working |
| Network | working |

## Artifacts

- [`packer.log`](./packer.log) - Full build log
  - **SHA256:** `76dfe0d092a3b0f9547699eda4b0ece8180a9f1cd043b6864ad978c29fb943a1`
  - **Size:** 23101 bytes
- [`proof.json`](./proof.json) - Machine-readable evidence

---

_Infrastructure Maintainer: Jeleel Muibi | HybridOps.Studio_
_Evidence Generated: 2025-11-29T171633Z_
