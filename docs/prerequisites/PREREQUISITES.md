---
title: System Prerequisites
---

# System Prerequisites

Before running automation workflows, install system-level tools. Python dependencies are managed separately via `control/requirements.txt`.

## Quick Start

```bash
make prereq.base     # Core tools (always required)
make prereq.azure    # Azure CLI (if using Azure)
make prereq.gcp      # GCP SDK (if using GCP)
make venv.setup      # Python environment
```

## Core Tools

Required for all operations:

```bash
make prereq.base
```

Installs:
- Terraform
- kubectl  
- Packer
- GitHub CLI

## Cloud Providers

Install only what you need:

```bash
make prereq.azure    # Azure CLI
make prereq.gcp      # GCP SDK
```

## Manual Installation

If you prefer manual installation over Make targets:

### Base Tools

```bash
# Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt update && sudo apt install -y terraform

# kubectl
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# GitHub CLI
sudo apt install -y gh

# Packer
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt update && sudo apt install -y packer
```

### Cloud Tools

```bash
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# GCP SDK
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
    sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
sudo apt update && sudo apt install -y google-cloud-sdk
```

## Verification

```bash
make prereq.check
```

Or verify manually:

```bash
terraform version
kubectl version --client
packer version
gh version
python3 --version
az version         # If Azure installed
gcloud version     # If GCP installed
```

## Python Environment

After system tools are installed:

```bash
make venv.setup
source .venv/bin/activate
```

This installs Python packages from `control/requirements.txt`.

## Troubleshooting

### Permission Denied

If you encounter permission errors during installation:

```bash
sudo chown -R $USER:$USER ~/.local
```

### Missing GPG Keys

If apt-key warnings appear, keys are deprecated but functional. Future versions will use signed-by method shown in GCP installation.

### Python Version

Minimum Python 3.10 required. Check with:

```bash
python3 --version
```

Upgrade if needed:

```bash
sudo apt update && sudo apt install -y python3.10
```

---

**Maintainer:** HybridOps.Studio  
**License:** MIT-0 for code, CC-BY-4.0 for documentation unless otherwise stated.
