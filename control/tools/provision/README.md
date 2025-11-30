# Packer Provisioning Toolkit (Proxmox)

Operational scripts for Packer template builds on Proxmox VE. Handles Proxmox API bootstrap (via the `init` toolkit), unattended file rendering, logging, and evidence generation.

> **Templates:** [`infra/packer-multi-os/`](../../../infra/packer-multi-os/)  
> **Documentation:** [HOWTO](../../../docs/howtos/HOWTO_packer_proxmox_template.md) · [Runbook](../../../docs/runbooks/platform/packer-proxmox-template-build.md) · [ADR-0016](../../../docs/adr/ADR-0016-packer-cloudinit-vm-templates.md)

---

## Structure

```text
control/tools/provision/init/
├── .conf/
│   ├── azure.conf
│   ├── gcp.conf
│   ├── netbox.conf
│   └── proxmox.conf
├── init-azure-env.sh
├── init-gcp-env.sh
└── init-proxmox-env.sh        # Proxmox env bootstrap (API, token, storage, bridge)

control/tools/provision/packer/
├── README.md
├── bin/
│   ├── build-wrapper.sh       # Build orchestration with logging
│   ├── chain-lib.sh           # Chain ID tracking
│   ├── evidence_packer.sh     # Proof artifact generation
│   ├── prestage-iso.sh        # ISO download to Proxmox
│   ├── render_unattended.sh   # Template rendering
│   ├── test-template.sh       # Post-build validation
│   └── validate-all.sh        # Validate all templates
└── remote/
    └── init-packer-remote.sh  # Runs on Proxmox (user/token/ACLs)
```

Proxmox environment output:

```text
infra/env/
└── .env.proxmox               # PROXMOX_* for Proxmox API and networking
```

---

## `init-proxmox-env.sh`

**Path:** `control/tools/provision/init/init-proxmox-env.sh`  
**Purpose:** Bootstrap Proxmox API access and generate a shared Proxmox env file for Packer and on-prem Terraform.

### Behaviour

- Reads `control/tools/provision/init/.conf/proxmox.conf`.
- Optionally reads `control/secrets.env` for `PROXMOX_TOKEN_SECRET`.
- Uploads and executes `remote/init-packer-remote.sh` on the Proxmox node.
- Ensures the automation user exists (for example `automation@pam`) with required ACLs.
- Creates or reuses the API token:
  - If `PROXMOX_TOKEN_SECRET` is missing, generates a new token and writes it into `control/secrets.env`.
  - If `PROXMOX_TOKEN_SECRET` exists, reuses the existing secret and skips token rotation.
- Discovers:
  - Node name.
  - Storage pools (VM and ISO).
  - Network bridge for builds.
- Writes `infra/env/.env.proxmox` with `PROXMOX_*` exports:
  - Proxmox API URL, token ID, token secret, node.
  - Storage pools for VM and ISO.
  - Network bridge and HTTP helper bind address/port.
- Generates an init proof artifact and log for audit.

### Usage

From the repository root:

```bash
control/tools/provision/init/init-proxmox-env.sh
```

or via the Packer Makefile:

```bash
cd infra/packer-multi-os
make init
```

### Output

- `infra/env/.env.proxmox`
- `output/logs/packer/init/<timestamp>/init-packer.log`
- `docs/proof/platform/packer-builds/init/<timestamp>/` (when `evidence_packer.sh` is available)

---

## `remote/init-packer-remote.sh`

**Path:** `control/tools/provision/packer/remote/init-packer-remote.sh`  
**Purpose:** Perform Proxmox-local bootstrap when called over SSH.

### Behaviour

- Verifies Proxmox tools (`pveum`, `pvesh`) are available.
- Ensures the automation user exists (for example `automation@pam`).
- Ensures the API token exists:
  - If `SKIP_TOKEN_GEN` is unset:
    - Removes any existing token of the same name.
    - Creates a new token and returns the secret.
  - If `SKIP_TOKEN_GEN` is set:
    - Leaves the existing token in place and does not return a secret.
- Discovers:
  - Node name.
  - Primary IP for API access.
  - Storage pools for VM images and ISO images.
  - Active bridge, or falls back to the configured bridge.
- Applies ACLs for the user and token on `/` and the relevant storage paths.
- Prints `EXPORT:` lines for:
  - `TOKEN_SECRET` (when a new token is created).
  - `NODE`, `IP`, `STORAGE_VM`, `STORAGE_ISO`, `BRIDGE`.

This script is not called directly by operators. It is invoked by `init-proxmox-env.sh` over SSH.

---

## `bin/build-wrapper.sh`

**Path:** `control/tools/provision/packer/bin/build-wrapper.sh`  
**Purpose:** Orchestrate Packer builds with consistent logging and evidence.

### Behaviour

- Generates a chain ID for audit correlation.
- Creates a timestamped log directory per run.
- Sources the Proxmox env (`infra/env/.env.proxmox` or an explicit `--env` path).
- Runs `packer build` with the supplied arguments.
- Streams output to the console and a log file.
- On success:
  - Calls `evidence_packer.sh` to generate proof artifacts.
- On failure:
  - Logs the error; no proof is generated.

### Typical usage

Called by `infra/packer-multi-os/Makefile`:

```bash
build-wrapper.sh   --dir linux/ubuntu   --key ubuntu-2204   --hint-target linux   --default-vmid 9000   --env infra/env/.env.proxmox
```

---

## `bin/render_unattended.sh`

**Purpose:** Render unattended install templates for Linux and Windows.

### Behaviour

- Processes `.tpl` files using environment variable substitution.
- Generates:
  - `user-data` for Ubuntu.
  - `ks.cfg` for Rocky.
  - `Autounattend.xml` for Windows (optional).
- Uses values sourced from the Proxmox env (`.env.proxmox`) and template-specific variables.

**Called by:** Make targets in `infra/packer-multi-os` during sync/prep phases.

---

## `bin/prestage-iso.sh`

**Purpose:** Ensure required ISOs are present and verified on the Proxmox node.

### Behaviour

- Reads ISO URL and checksum from Packer variables.
- Downloads ISOs to the configured ISO storage if missing.
- Verifies checksums before builds.

---

## `bin/evidence_packer.sh`

**Purpose:** Generate build proof artifacts.

### Behaviour

- Creates a timestamped folder under `docs/proof/platform/packer-builds/`.
- Writes `README.md` with summary information.
- Writes `proof.json` with machine-readable metadata.
- Copies the build log and stores its checksum.
- Maintains `latest` symlinks for quick access.

---

## `bin/validate-all.sh`

**Purpose:** Validate all Packer templates.

### Usage

From `infra/packer-multi-os`:

```bash
../../control/tools/provision/packer/bin/validate-all.sh
```

Runs `packer validate` across all supported templates.

---

## Evidence layout

### Logs

```text
output/logs/packer/
├── init/
│   ├── <timestamp>/init-packer.log
│   └── latest -> <timestamp>
└── builds/
    └── <template-key>/
        ├── <timestamp>/packer.log
        └── latest -> <timestamp>
```

### Proof artifacts

```text
docs/proof/platform/packer-builds/
├── init/
│   ├── <timestamp>/
│   │   ├── README.md
│   │   ├── proof.json
│   │   └── init-packer.log
│   └── latest -> <timestamp>
└── builds/
    └── <template-key>/
        ├── <timestamp>/
        │   ├── README.md
        │   ├── proof.json
        │   └── packer.log
        └── latest -> <timestamp>
```

### Chain IDs

Packer init and build runs are tagged with a chain ID (for example, `CHAIN-20251128T210000Z-ubuntu-2204`).  
The chain ID is generated by `chain-lib.sh` and propagated by:

- `init-proxmox-env.sh` during Proxmox bootstrap.
- `bin/build-wrapper.sh` during template builds.
- `evidence_packer.sh` when generating proof artifacts.

This provides a single correlation handle across:

- Logs under `output/logs/packer/`
- Proof artifacts under `docs/proof/platform/packer-builds/`
- Any external dashboards that ingest these logs.

Example lookup:

```bash
CHAIN_ID="CHAIN-20251128T210000Z-ubuntu-2204"

grep -R "${CHAIN_ID}" output/logs/packer
grep -R "${CHAIN_ID}" docs/proof/platform/packer-builds
```

---

## References

- [ADR-0016: Packer + Cloud-Init VM Templates](../../../docs/adr/ADR-0016-packer-cloudinit-vm-templates.md)
- [Runbook: Proxmox VM Template Build](../../../docs/runbooks/platform/packer-proxmox-template-build.md)
- [HOWTO: First Packer Template](../../../docs/howtos/HOWTO_packer_proxmox_template.md)

---

**Maintainer:** jeleel-muibi  
**Last Updated:** 2025-11-28
