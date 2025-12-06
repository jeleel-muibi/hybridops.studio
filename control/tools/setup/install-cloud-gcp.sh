#!/usr/bin/env bash
# Install GCP SDK prerequisites
# Maintainer: HybridOps.Studio
# Last Modified: 2025-11-23

set -euo pipefail

if command -v gcloud &>/dev/null; then
    exit 0
fi

echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
    sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

sudo apt update && sudo apt install -y google-cloud-sdk
