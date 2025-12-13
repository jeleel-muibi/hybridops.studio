# Proof: Packer Build — rocky-9

**Generated:** 2025-12-13T210027Z
**Status:** SUCCESS
**VMID:** 9005
**Build Duration:** 4 minutes 33 seconds

## VM Configuration

| Property | Value |
|----------|-------|
| Name | `rocky-9-template` |
| OS Type | `l26` |
| CPU | 1 socket(s) × 2 core(s) |
| Memory | 4096 MB |
| Disk (scsi0) | `local-lvm:base-9005-disk-0,cache=none,replicate=0,size=10G` |
| Network (net0) | `virtio=EE:E0:0A:4C:A5:66,bridge=vmbr0` |
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
  - **SHA256:** `4c41a88314968fe9790ad3a382b0c3f950e8cacd0cb7c7b862dd00ceacbe552b`
  - **Size:** 26340 bytes
- [`proof.json`](./proof.json) - Machine-readable evidence

---

_Infrastructure Maintainer: Jeleel Muibi | HybridOps.Studio_
_Evidence Generated: 2025-12-13T210027Z_
