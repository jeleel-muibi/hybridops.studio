#!/usr/bin/env bash
# HybridOps.Studio - Azure Prerequisites Installer
# Maintainer: HybridOps.Studio
# Last Modified: 2025-11-23

set -euo pipefail

if command -v az &>/dev/null; then
    exit 0
fi

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
