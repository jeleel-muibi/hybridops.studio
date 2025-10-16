# Runtime Images (Packer → Blob/GCS)

Evidence that image builds complete within **≤ 12m** and are mirrored to cloud storage.
- CI logs and final image manifests.
- Storage listings and artifact hashes.
**KPI tie-in:** Supports DR objectives (faster reprovisioning → RTO/RPO).
- Example artifacts: `images/*image_listing*.png`, `terraform_outputs.json`.

**Navigate:** [Evidence Map](../../evidence_map.md) · [Proof Archive](../README.md)
