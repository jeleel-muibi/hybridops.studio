    # Auto-generated Makefile for showcase: kubernetes-autoscaling
    SHELL := /usr/bin/env bash
    .SHELLFLAGS := -eu -o pipefail -c
    .ONESHELL:
    MAKEFLAGS += --no-builtin-rules
    .DEFAULT_GOAL := help

    OUTPUT_DIR ?= ../../output
    EVIDENCE_DIR := $(OUTPUT_DIR)/artifacts/showcases/kubernetes-autoscaling
    LOG_DIR      := $(OUTPUT_DIR)/logs/showcases/kubernetes-autoscaling

    .PHONY: help env demo evidence destroy   loadgen

    help: ## Show this help
    	@awk 'BEGIN{FS":.*##"; printf "\nkubernetes-autoscaling targets:\n"} /^[a-zA-Z0-9_.-]+:.*##/{printf "  \033[36m%-24s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

    env: ## Create local output/evidence folders
    	mkdir -p "$(EVIDENCE_DIR)" "$(LOG_DIR)"

    demo: env ## End-to-end demo for kubernetes-autoscaling
    	@echo "[kubernetes-autoscaling] demo: wire Terraform/Ansible/Jenkins as needed"
    	@echo "  - capture screenshots/logs into $(EVIDENCE_DIR)"

    evidence: env ## Export screenshots/logs to Proof archive
    	@echo "[kubernetes-autoscaling] evidence: move curated proof to docs/proof/<topic>"
    	@echo "  - source: $(EVIDENCE_DIR)"
    	@echo "  - target: docs/proof/... (per Evidence Map)"

    destroy: ## Tear down kubernetes-autoscaling resources
    	@echo "[kubernetes-autoscaling] destroy: tear down infra if this showcase provisions any"

    loadgen: ## Start/stop a synthetic load generator to trigger autoscaling
	@echo "[K8s] loadgen: implement k6/vegeta or a simple looped curl here"
