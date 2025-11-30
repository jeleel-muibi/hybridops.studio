# File: Makefile - System Prerequisites Installer
# Purpose: Install core tooling and Python environment for HybridOps.Studio
# Author: Jeleel Muibi
# Date: 2025-01-23

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

SETUP_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
REPO_ROOT := $(shell cd $(SETUP_DIR) && git rev-parse --show-toplevel 2>/dev/null || echo "$(SETUP_DIR)/../../..")

.PHONY: help base azure gcp all check python.env

help: ## Show available installation targets
	@awk 'BEGIN{FS=" *:.*## *"; printf "\nTargets:\n"} /^[a-zA-Z0-9_.-]+:.*##/{printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

base: ## Install core tools: Terraform, kubectl, Packer, GitHub CLI
	@bash $(SETUP_DIR)/install-base.sh

azure: ## Install Azure CLI
	@bash $(SETUP_DIR)/install-cloud-azure.sh

gcp: ## Install GCP SDK
	@bash $(SETUP_DIR)/install-cloud-gcp.sh

python.env: ## Setup Python virtual environment
	@bash $(SETUP_DIR)/install-python-env.sh

all: ## Install all system prerequisites
	@bash $(SETUP_DIR)/install-all.sh
	@$(MAKE) python.env

check: ## Verify which tools are installed
	@command -v terraform >/dev/null && echo "Terraform: installed" || echo "Terraform: missing"
	@command -v kubectl >/dev/null && echo "kubectl: installed" || echo "kubectl: missing"
	@command -v packer >/dev/null && echo "Packer: installed" || echo "Packer: missing"
	@command -v gh >/dev/null && echo "GitHub CLI: installed" || echo "GitHub CLI: missing"
	@command -v az >/dev/null && echo "Azure CLI: installed" || echo "Azure CLI: missing"
	@command -v gcloud >/dev/null && echo "GCloud SDK: installed" || echo "GCloud SDK: missing"
	@command -v python3 >/dev/null && echo "Python3: installed" || echo "Python3: missing"
	@test -d $(REPO_ROOT)/.venv && echo "Python virtual environment: ready" || echo "Python virtual environment: missing"
