#!/usr/bin/env bash
# HybridOps.Studio - Base Prerequisites Installer
# Installs core infrastructure tools required for all operations
# Author: jeleel-muibii
# Last Modified: 2025-11-23

set -euo pipefail

install_terraform() {
    if command -v terraform &>/dev/null; then
        return 0
    fi

    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    sudo apt update && sudo apt install -y terraform
}

install_kubectl() {
    if command -v kubectl &>/dev/null; then
        return 0
    fi

    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
}

install_github_cli() {
    if command -v gh &>/dev/null; then
        return 0
    fi

    sudo apt update && sudo apt install -y gh
}

install_packer() {
    if command -v packer &>/dev/null; then
        return 0
    fi

    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    sudo apt update && sudo apt install -y packer
}

main() {
    install_terraform
    install_kubectl
    install_github_cli
    install_packer
}

main "$@"
