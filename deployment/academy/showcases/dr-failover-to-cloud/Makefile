    # Auto-generated Makefile for showcase: disaster-recovery-to-cloud
    SHELL := /usr/bin/env bash
    .SHELLFLAGS := -eu -o pipefail -c
    .ONESHELL:
    MAKEFLAGS += --no-builtin-rules
    .DEFAULT_GOAL := help

    OUTPUT_DIR ?= ../../output
    EVIDENCE_DIR := $(OUTPUT_DIR)/artifacts/showcases/disaster-recovery-to-cloud
    LOG_DIR      := $(OUTPUT_DIR)/logs/showcases/disaster-recovery-to-cloud

    .PHONY: help env demo evidence destroy  decision.dryrun

    help: ## Show this help
    	@awk 'BEGIN{FS":.*##"; printf "\ndisaster-recovery-to-cloud targets:\n"} /^[a-zA-Z0-9_.-]+:.*##/{printf "  \033[36m%-24s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

    env: ## Create local output/evidence folders
    	mkdir -p "$(EVIDENCE_DIR)" "$(LOG_DIR)"

    demo: env ## End-to-end demo for disaster-recovery-to-cloud
    	@echo "[disaster-recovery-to-cloud] demo: wire Terraform/Ansible/Jenkins as needed"
    	@echo "  - capture screenshots/logs into $(EVIDENCE_DIR)"

    evidence: env ## Export screenshots/logs to Proof archive
    	@echo "[disaster-recovery-to-cloud] evidence: move curated proof to docs/proof/<topic>"
    	@echo "  - source: $(EVIDENCE_DIR)"
    	@echo "  - target: docs/proof/... (per Evidence Map)"

    destroy: ## Tear down disaster-recovery-to-cloud resources
    	@echo "[disaster-recovery-to-cloud] destroy: tear down infra if this showcase provisions any"

    decision.dryrun: ## Run Decision Service dry-run (no changes) for visibility
	@echo "[Decision] Dry-run (use deployment/common/decision CLI if present)"
