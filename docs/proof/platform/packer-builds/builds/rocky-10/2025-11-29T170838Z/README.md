# Proof: Packer Build — rocky-10

**Generated:** 2025-11-29T170838Z
**Status:** SUCCESS
**VMID:** 9003
**Build Duration:** 3 minutes 52 seconds

## VM Configuration

| Property | Value |
|----------|-------|
| Name | `rocky-10-template` |
| OS Type | `l26` |
| CPU | 1 socket(s) × 2 core(s) |
| Memory | 4096 MB |
| Disk (scsi0) | `local-lvm:base-9003-disk-0,cache=none,replicate=0,size=10G` |
| Network (net0) | `virtio=2E:FA:4C:E3:75:6D,bridge=vmbr0` |
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
  - **SHA256:** `5601445e4fe4f5f4476342b1cca4c166337bae4a92cb1483ce446ffeba14f98b`
  - **Size:** 25809 bytes
- [`proof.json`](./proof.json) - Machine-readable evidence

---

_Infrastructure Maintainer: Jeleel Muibi | HybridOps.Studio_
_Evidence Generated: 2025-11-29T170838Z_
