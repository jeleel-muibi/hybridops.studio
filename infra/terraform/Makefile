# File: Makefile
# Purpose: Orchestrate Terraform/Terragrunt runs and generate cloud tfvars
# Author: Jeleel Muibi | HybridOps.Studio
# Date: 2025-11-28

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

REPO_ROOT      := $(shell git rev-parse --show-toplevel 2>/dev/null || echo "../..")
INIT_ROOT      := $(REPO_ROOT)/control/tools/provision/init
TERRAFORM_ROOT := $(REPO_ROOT)/infra/terraform
ENV_DIR        := $(REPO_ROOT)/infra/env

INIT_AZURE := $(INIT_ROOT)/init-azure-env.sh
INIT_GCP   := $(INIT_ROOT)/init-gcp-env.sh

TG_BIN         ?= terragrunt
TG_ARGS_COMMON := --terragrunt-non-interactive
LIVE_ROOT      ?= $(TERRAFORM_ROOT)/live-v1

LIVE_AZURE ?= $(LIVE_ROOT)/azure
LIVE_GCP   ?= $(LIVE_ROOT)/gcp

.PHONY: help env.azure env.gcp env.all fmt \
        plan-all apply-all destroy-all \
        plan.azure apply.azure destroy.azure \
        plan.gcp apply.gcp destroy.gcp

help: ## List available targets
	@awk 'BEGIN{FS=" *:.*## *"; printf "\nTargets:\n"} /^[a-zA-Z0-9_.-]+:.*##/{printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

env.azure: ## Generate Azure tfvars file
	@[ -x "$(INIT_AZURE)" ] || { echo "Missing or non-executable $(INIT_AZURE)"; exit 1; }
	@bash "$(INIT_AZURE)"

env.gcp: ## Generate GCP tfvars file
	@[ -x "$(INIT_GCP)" ] || { echo "Missing or non-executable $(INIT_GCP)"; exit 1; }
	@bash "$(INIT_GCP)"

env.all: env.azure env.gcp ## Generate tfvars for Azure and GCP

fmt: ## Run terraform fmt under infra/terraform
	@terraform fmt -recursive "$(TERRAFORM_ROOT)" || echo "terraform fmt failed; check configuration paths"

plan-all: env.all ## Terragrunt plan for all live stacks
	@[ -d "$(LIVE_ROOT)" ] || { echo "Missing LIVE_ROOT: $(LIVE_ROOT)"; exit 1; }
	@$(TG_BIN) run-all plan $(TG_ARGS_COMMON) --terragrunt-working-dir "$(LIVE_ROOT)"

apply-all: env.all ## Terragrunt apply for all live stacks
	@[ -d "$(LIVE_ROOT)" ] || { echo "Missing LIVE_ROOT: $(LIVE_ROOT)"; exit 1; }
	@$(TG_BIN) run-all apply $(TG_ARGS_COMMON) --terragrunt-working-dir "$(LIVE_ROOT)"

destroy-all: env.all ## Terragrunt destroy for all live stacks
	@[ -d "$(LIVE_ROOT)" ] || { echo "Missing LIVE_ROOT: $(LIVE_ROOT)"; exit 1; }
	@$(TG_BIN) run-all destroy $(TG_ARGS_COMMON) --terragrunt-working-dir "$(LIVE_ROOT)"

plan.azure: env.azure ## Terragrunt plan for Azure
	@[ -d "$(LIVE_AZURE)" ] || { echo "Missing LIVE_AZURE: $(LIVE_AZURE)"; exit 1; }
	@$(TG_BIN) run-all plan $(TG_ARGS_COMMON) --terragrunt-working-dir "$(LIVE_AZURE)"

apply.azure: env.azure ## Terragrunt apply for Azure
	@[ -d "$(LIVE_AZURE)" ] || { echo "Missing LIVE_AZURE: $(LIVE_AZURE)"; exit 1; }
	@$(TG_BIN) run-all apply $(TG_ARGS_COMMON) --terragrunt-working-dir "$(LIVE_AZURE)"

destroy.azure: env.azure ## Terragrunt destroy for Azure
	@[ -d "$(LIVE_AZURE)" ] || { echo "Missing LIVE_AZURE: $(LIVE_AZURE)"; exit 1; }
	@$(TG_BIN) run-all destroy $(TG_ARGS_COMMON) --terragrunt-working-dir "$(LIVE_AZURE)"

plan.gcp: env.gcp ## Terragrunt plan for GCP
	@[ -d "$(LIVE_GCP)" ] || { echo "Missing LIVE_GCP: $(LIVE_GCP)"; exit 1; }
	@$(TG_BIN) run-all plan $(TG_ARGS_COMMON) --terragrunt-working-dir "$(LIVE_GCP)"

apply.gcp: env.gcp ## Terragrunt apply for GCP
	@[ -d "$(LIVE_GCP)" ] || { echo "Missing LIVE_GCP: $(LIVE_GCP)"; exit 1; }
	@$(TG_BIN) run-all apply $(TG_ARGS_COMMON) --terragrunt-working-dir "$(LIVE_GCP)"

destroy.gcp: env.gcp ## Terragrunt destroy for GCP
	@[ -d "$(LIVE_GCP)" ] || { echo "Missing LIVE_GCP: $(LIVE_GCP)"; exit 1; }
	@$(TG_BIN) run-all destroy $(TG_ARGS_COMMON) --terragrunt-working-dir "$(LIVE_GCP)"

clean: ## Clean generated tfvars files
	@rm -f "$(ENV_DIR)"/azure.tfvars "$(ENV_DIR)"/gcp.tfvars
	@rm -rf .terraform .terraform.lock.hcl .terragrunt-cache
	@echo "Cleaned generated tfvars and Terragrunt cache"
