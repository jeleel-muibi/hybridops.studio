# System Prerequisites Installer

Automated installation scripts for HybridOps.Studio system-level dependencies.

## Scope

These scripts install and validate the core tooling required across the HybridOps.Studio ecosystem:

- Terraform (infrastructure as code)
- Packer (image and template builds)
- kubectl (Kubernetes interaction)
- GitHub CLI (CI/CD and GitHub workflows)
- Optional cloud CLIs:
  - Azure CLI
  - Google Cloud SDK (gcloud)
- Python runtime and virtual environment for HybridOps control tooling

For a full, command-level breakdown and manual installation steps, see the dedicated prerequisites guide linked below.

## Directory Layout

```text
control/tools/setup/
├── Makefile                # Installation orchestration
├── install-base.sh         # Core tools (Terraform, kubectl, Packer, gh)
├── install-cloud-azure.sh  # Azure CLI
├── install-cloud-gcp.sh    # GCP SDK
├── install-python-env.sh   # Python virtualenv + requirements
└── install-all.sh          # Complete installation (base + cloud CLIs + Python env)
```

## Usage

### From repository root

Preferred operator interface (delegates into this directory via the top-level Makefile):

```bash
make prereq.base     # Install core tools
make prereq.azure    # Install Azure CLI
make prereq.gcp      # Install GCP SDK
make prereq.python   # Provision Python virtual environment
make prereq.all      # Install everything (base + CLIs + Python env)
make prereq.check    # Verify installations
```

### From this directory (`control/tools/setup/`)

Direct usage for local development or CI images:

```bash
make base        # install-base.sh
make azure       # install-cloud-azure.sh
make gcp         # install-cloud-gcp.sh
make python.env  # install-python-env.sh
make all         # install-all.sh + python.env
make check       # presence/version checks
```

`make prereq.*` targets at the repository root should remain thin wrappers around these local targets so that operator UX stays stable while `control/tools/setup/` can evolve independently.

## Script Responsibilities

### `install-base.sh`

Installs core infrastructure tools required for all HybridOps.Studio workflows:

- Terraform
- kubectl
- Packer
- GitHub CLI

### `install-cloud-azure.sh`

Installs Azure CLI for Azure-focused workflows (for example AKS, Azure networking, and hybrid connectivity experiments).

### `install-cloud-gcp.sh`

Installs Google Cloud SDK (gcloud) for GCP-focused workflows.

### `install-python-env.sh`

Creates and maintains the Python virtual environment used by control tooling.

Typical responsibilities:

- Ensure `python3` and `python3-venv` are present.
- Create `.venv/` at the repository root if missing.
- Install or upgrade `pip` and supporting packaging tools.
- Install packages from `control/requirements.txt`.
- Write a marker file (for example `.venv/.installed`) used by `make check` to confirm readiness.

### `install-all.sh`

Wrapper that executes all installation scripts in a safe sequence. Intended for clean machines, CI agents, and repeatable environment provisioning. In normal workflows it should be used together with the Python environment target (`make prereq.all` / `make all`).

## Behavior

- Scripts are idempotent where possible.
- If a tool is already present and meets version expectations, it is skipped.
- Safe to re-run locally and in CI/CD pipelines.
- `make prereq.check` / `make check` run version and presence checks for all supported tools, including the Python virtual environment marker.

## Requirements

- Ubuntu/Debian-based system
- `sudo` privileges
- Internet connectivity
- Python 3.10+ available on `PATH` for downstream virtualenv and tooling setup

## Python Dependencies

Python package dependencies are managed via `control/requirements.txt` and installed by `install-python-env.sh` (or the corresponding Make targets). For direct invocation from the repository root:

```bash
make prereq.python
```

or from this directory:

```bash
make python.env
```

## Documentation

- System prerequisites (manual install commands, verification snippets, and additional notes):  
  [Global Prerequisites Guide](../../docs/prerequisites/PREREQUISITES.md)

---

Last Modified: 2025-11-23  
Maintainer: HybridOps.Studio
