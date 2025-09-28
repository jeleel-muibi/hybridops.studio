
#!/usr/bin/env bash
set -euxo pipefail

sudo apt-get update -y
sudo apt-get install -y --no-install-recommends   ca-certificates curl gnupg lsb-release software-properties-common   unzip jq git python3 python3-venv python3-pip bc apt-transport-https

# HashiCorp (Terraform & Packer)
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" |   sudo tee /etc/apt/sources.list.d/hashicorp.list

# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Google Cloud CLI repo
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" |   sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list

sudo apt-get update -y
sudo apt-get install -y terraform packer ansible google-cloud-cli

terraform -version || true
packer -version || true
ansible --version || true
az version || true
gcloud version || true
