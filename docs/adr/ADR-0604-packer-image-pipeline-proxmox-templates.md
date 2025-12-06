---
id: ADR-0604
title: "Standardise Packer Image Pipeline for Proxmox Templates"
status: Accepted
date: 2025-12-01
category: "06-cicd-automation"

domains: ["platform", "cicd", "infra"]
owners: ["HybridOps.Studio"]
supersedes: []
superseded_by: []

links:
  prs: []
  runbooks: []
  howtos: []
  evidence:
    - "../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md"
  diagrams: []

draft: false
is_template_doc: false
tags: ["packer", "proxmox", "templates", "automation"]
access: public

stub:
  enabled: false
  blurb: ""
  highlights: []
  cta_url: ""
  cta_label: ""

---

# Standardise Packer Image Pipeline for Proxmox Templates

## Status
Accepted — a shared Packer workspace and pipeline are the single standard for building Proxmox VM templates used by RKE2, platform services and workloads.

## 1. Context

HybridOps.Studio relies on **Proxmox VM templates** as the starting point for:

- RKE2 control-plane and worker nodes.
- Control-node style VMs and other infrastructure components.
- Lab workloads that require consistent base images.

Before this ADR, templates could be:

- Built manually using the Proxmox UI.
- Built via ad-hoc Packer configurations for a single OS.
- Inconsistently named, versioned and documented.

Problems with this approach:

- Hard to prove how a template was built or rebuilt.
- Inconsistent cloud-init configuration and guest tools.
- Difficult to attach **evidence** to specific images for assessors.

A standard image pipeline is required to:

- Support Evidence 4 (Delivery Platform, GitOps and Cluster Operations).
- Provide a repeatable base for RKE2 and other workloads.
- Produce logs and artefacts under `docs/proof/infra/packer/`.

## 2. Decision

HybridOps.Studio adopts a **single, shared Packer workspace and pipeline** as the **standard** for building Proxmox templates.

Key aspects:

- All Proxmox templates used for RKE2 and platform workloads are built from:
  - A shared configuration in `infra/packer-multi-os/`.
  - OS-specific subdirectories for Ubuntu, Rocky, Windows and others.
- The pipeline is driven by:
  - A Makefile and helper scripts in the Packer workspace.
  - Jenkins pipelines (see ADR-0603) that invoke Packer using standard targets.
- Templates follow a defined naming and VMID scheme, for example:
  - `tpl-ubuntu-22.04`, `tpl-ubuntu-24.04`, `tpl-rocky-9`, `tpl-win2022`.
  - VMID allocations documented and reserved for templates.
- Evidence of builds (logs, manifests, checksums) is stored under:
  - `docs/proof/infra/packer/`.

Manual template creation and one-off Packer configs are considered **non-standard** and should not be used in delivery pipelines.

## 3. Rationale

The rationale for standardising on a single Packer pipeline:

Consistency:

- All templates share:
  - Cloud-init layout and base configuration.
  - Guest agent and tooling (for example, QEMU guest agent).
  - Disk layout and Proxmox storage configuration.
- This reduces surprises when RKE2 nodes or other VMs are created from templates.

Traceability and evidence:

- Every template build:
  - Has a corresponding Packer log.
  - Can be traced back to a commit and a Jenkins run.
  - Produces artefacts under `docs/proof/infra/packer/`.
- This supports Evidence 4 and makes it easy to show template provenance.

Operational simplicity:

- One workspace and Makefile for all OS templates, with shared logic.
- Clear commands for validation and build (for example, `make validate`, `make build-ubuntu-2204`).
- Simplifies automation from Jenkins and GitHub Actions.

Future extensibility:

- Adding a new OS (for example, Rocky 10) is a matter of:
  - Adding a new subdirectory and configuration under `infra/packer-multi-os/`.
  - Extending the Makefile and pipelines.
- Existing tooling and processes remain the same.

Trade-offs:

- The shared workspace introduces a learning curve.
- A bug in shared logic can affect multiple templates.

## 4. Consequences

### 4.1 Positive consequences

- **Single source of truth for templates**
  - All Proxmox templates are built from one workspace with shared logic.
  - Easier to audit and reason about changes.

- **Improved reliability**
  - Validations (for example, Packer `validate`, custom checks) can run before builds.
  - Common issues (ISO checksums, SSH wait logic) can be fixed once in shared code.

- **Better alignment with CI/CD**
  - Jenkins jobs can target standard Makefile goals.
  - Evidence 4 can consistently refer to the same pipeline and proof locations.

### 4.2 Negative consequences and risks

- **Blast radius of shared logic**
  - A misconfiguration in shared Packer code affects all templates.
  - Requires careful review and testing.

- **Initial migration effort**
  - Existing templates and ad-hoc configs must be migrated into the shared workspace.
  - Documentation and how-to guides must be updated.

Mitigations:

- Use feature branches and test builds before merging changes to shared Packer code.
- Maintain a validation script (for example, `validate-all.sh`) to run on all OS templates.
- Capture failed builds and regression tests in `docs/proof/infra/packer/` for debugging and evidence.

## 5. Alternatives considered

Per-OS Packer repositories:

- Would isolate issues per OS, but:
  - Fragments the tooling and makes automation harder.
  - Duplicates shared logic across multiple repos.

Manual template management via Proxmox UI:

- Simple for small experiments.
- Not acceptable for repeatable, evidence-driven templates.
- Difficult to link templates to specific commits and logs.

Use vendor images only:

- For some OSes (for example, cloud images), it is possible to import qcow2 or similar.
- However, HybridOps.Studio needs:
  - Customisation (extra tooling, config).
  - Evidence of how the images were built.

## 6. Implementation notes

Workspace:

- Packer workspace is located at:
  - [`infra/packer-multi-os/`](../../infra/packer-multi-os/)
- Structure:
  - Shared configuration and variables files.
  - OS-specific directories such as:
    - `linux/ubuntu/`
    - `linux/rocky/`
    - `windows/server/`

Pipeline:

- A Makefile defines standard targets (for example, `validate`, `build-<os>-<version>`).
- Jenkins pipelines call these targets using:
  - A fixed `.env` format for Proxmox API tokens and storage.
  - Logs and artefacts written under `output/` and copied into `docs/proof/infra/packer/`.

Evidence:

- Proof of template builds is stored under:
  - [`docs/proof/infra/packer/`](../../docs/proof/infra/packer/)
- Artefacts may include:
  - Packer logs.
  - Screenshots of Proxmox template configuration.
  - Checksums and build metadata.

## 7. Operational impact and validation

Operational impact:

- Platform and infra engineers must:
  - Make changes through the shared Packer workspace.
  - Use standard targets and environment files.
  - Ensure new OS templates follow naming and VMID conventions.

Validation:

- HOWTOs to be created:
  - Run the Packer image pipeline via Jenkins.
- Runbooks to be created:
  - Packer template build failure and recovery.
- Evidence folders:
  - [`docs/proof/infra/packer/`](../../docs/proof/infra/packer/)

Validation is considered successful when:

- All RKE2 and key infrastructure templates are built from `infra/packer-multi-os/`.
- Jenkins can rebuild templates on demand.
- Evidence folders contain logs and artefacts for recent builds.

## 8. References

- [ADR-0001 – ADR Process and Conventions](../adr/ADR-0001-adr-process-and-conventions.md)  
- [ADR-0202 – Adopt RKE2 as Primary Runtime for Platform and Applications](../adr/ADR-0202-rke2-primary-runtime-for-platform-and-apps.md)  
- [ADR-0603 – Run Jenkins Controller on Control Node, Agents on RKE2](../adr/ADR-0603-jenkins-controller-docker-agents-rke2.md)  
- [Evidence 4 – Delivery Platform, GitOps and Cluster Operations](../evidence/evidence-04-delivery-platform-gitops-cluster-operations.md)  

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
