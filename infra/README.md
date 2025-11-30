# HybridOps.Studio — Infrastructure Layer (`infra/`)

The `infra/` directory contains the **infrastructure primitives** for the HybridOps.Studio lab:

- Environment artifacts (`infra/env`)
- VM templates built with Packer (`infra/packer-multi-os`)
- Terraform / Terragrunt stacks (`infra/terraform`)

This file provides an overview. Each subdirectory maintains its own detailed README.

---

## 1. Layout

```text
infra/
├── env/               # Generated environment artifacts (Proxmox, Azure, GCP, NetBox, etc.)
├── packer-multi-os/   # Proxmox VM templates (Linux & Windows) built with Packer
├── terraform/         # Terraform / Terragrunt live tree and modules
└── README.md          # This overview
```

High-level responsibilities:

- `env/` — Location where init scripts write environment and provider inputs.
- `packer-multi-os/` — VM template build and validation for Proxmox.
- `terraform/` — Composition of those templates into full environments (`dev`, `staging`, `prod`).

For detailed behaviour, refer to the README in each subdirectory.

---

## 2. `infra/env` — Environment artifacts

- **Purpose:** Central location where init tooling writes environment-specific files for Proxmox, Azure, GCP, NetBox, and related systems.
- **Format:** Shell-style env files and `.auto.tfvars.json` consumed by Terraform, Terragrunt and helper scripts.
- **Sources of truth:**
  - Configuration under `control/tools/provision/init/*.conf`
  - `control/secrets.env` (excluded from version control)
  - Remote systems (Proxmox API, cloud CLIs)

Detailed formats and generation flows are documented in `infra/env/README.md`.

> Generated files in `infra/env/` are not intended for manual editing. They should be refreshed by rerunning the appropriate init scripts.

---

## 3. `infra/packer-multi-os` — Proxmox VM templates

- **Purpose:** Build reusable VM templates (Ubuntu, Rocky, Windows Server/Client) for Proxmox VE.
- **Tooling:** HashiCorp Packer and the Proxmox plugin, orchestrated by the Makefile and provisioning toolkit under  
  `control/tools/provision/packer/`.
- **Outputs:** Cloud-init-capable templates, with build evidence recorded under `docs/proof/platform/packer-builds`.

Related documentation:

- `infra/packer-multi-os/README.md`
- `docs/howtos/HOWTO_packer_proxmox_template.md`
- `docs/runbooks/platform/packer-proxmox-template-build.md`
- `docs/adr/ADR-0016-packer-cloudinit-vm-templates.md`

---

## 4. `infra/terraform` — Terraform / Terragrunt

- **Purpose:** Define and deploy complete environments across:
  - Proxmox (SDN descriptors and VM clusters from templates)
  - Azure (VNet and AKS)
  - GCP (VPC and GKE)
- **Pattern:**
  - `live-v1/` — Terragrunt live tree (`dev`, `staging`, `prod`) with `00-foundation` and `10-platform` layers.
  - `modules/` — Local Terraform modules for Proxmox, Azure and GCP.
  - `backend-configs/` — Optional backend definitions for state (local vs remote).
  - `policies/` — OPA / Sentinel policies for Terraform runs.

Operational details, execution examples and Make targets are documented in `infra/terraform/README.md`.

---

## 5. Typical usage sequence

From the repository root:

1. **Generate or refresh environment artifacts**

   ```bash
   # Proxmox API, storage and bridge
   ./control/tools/provision/init/init-proxmox-env.sh

   # Azure and GCP provider inputs
   ./control/tools/provision/init/init-azure-env.sh
   ./control/tools/provision/init/init-gcp-env.sh
   ```

2. **Build or refresh VM templates (when base images change)**

   ```bash
   cd infra/packer-multi-os
   make init
   make build-ubuntu-24.04
   make build-rocky-10
   make build-windows-server-2025
   ```

3. **Bring up environments with Terragrunt**

   ```bash
   cd infra/terraform

   # Example: dev foundation
   terragrunt run-all apply --terragrunt-working-dir live-v1/dev/00-foundation

   # Example: dev platform
   terragrunt run-all apply --terragrunt-working-dir live-v1/dev/10-platform
   ```

This overview intentionally remains high-level. For precise inputs, outputs and evidence flows, refer to the README files inside each subdirectory and the linked HOWTOs ADRs and Runbooks.

**Maintainer:** Jeleel Muibi  
**Last Updated:** 2025-11-29
