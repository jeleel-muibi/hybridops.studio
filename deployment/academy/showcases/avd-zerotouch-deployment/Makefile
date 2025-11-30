    # Auto-generated Makefile for showcase: avd-zerotouch-deployment
    SHELL := /usr/bin/env bash
    .SHELLFLAGS := -eu -o pipefail -c
    .ONESHELL:
    MAKEFLAGS += --no-builtin-rules
    .DEFAULT_GOAL := help

    OUTPUT_DIR ?= ../../output
    EVIDENCE_DIR := $(OUTPUT_DIR)/artifacts/showcases/avd-zerotouch-deployment
    LOG_DIR      := $(OUTPUT_DIR)/logs/showcases/avd-zerotouch-deployment

    .PHONY: help env demo evidence destroy advanced-networking

    help: ## Show this help
    	@awk 'BEGIN{FS":.*##"; printf "\navd-zerotouch-deployment targets:\n"} /^[a-zA-Z0-9_.-]+:.*##/{printf "  \033[36m%-24s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

    env: ## Create local output/evidence folders
    	mkdir -p "$(EVIDENCE_DIR)" "$(LOG_DIR)"

    demo: env ## End-to-end demo for avd-zerotouch-deployment
    	@echo "[avd-zerotouch-deployment] demo: wire Terraform/Ansible/Jenkins as needed"
    	@echo "  - capture screenshots/logs into $(EVIDENCE_DIR)"

    evidence: env ## Export screenshots/logs to Proof archive
    	@echo "[avd-zerotouch-deployment] evidence: move curated proof to docs/proof/<topic>"
    	@echo "  - source: $(EVIDENCE_DIR)"
    	@echo "  - target: docs/proof/... (per Evidence Map)"

    destroy: ## Tear down avd-zerotouch-deployment resources
    	@echo "[avd-zerotouch-deployment] destroy: tear down infra if this showcase provisions any"

    advanced-networking: ## Provision/verify hub-and-spoke + private access
	@echo "[AVD] advanced-networking: implement Terraform/Ansible here (hub, spokes, private DNS)"
