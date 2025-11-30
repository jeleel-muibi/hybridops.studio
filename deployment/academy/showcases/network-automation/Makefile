# Auto-generated Makefile for showcase: network-automation
SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:
MAKEFLAGS += --no-builtin-rules
.DEFAULT_GOAL := help

OUTPUT_DIR ?= ../../output
EVIDENCE_DIR := $(OUTPUT_DIR)/artifacts/showcases/network-automation
LOG_DIR      := $(OUTPUT_DIR)/logs/showcases/network-automation

.PHONY: help env demo evidence destroy

help: ## Show this help
	@awk 'BEGIN{FS":.*##"; printf "\nnetwork-automation targets:\n"} /^[a-zA-Z0-9_.-]+:.*##/{printf "  \033[36m%-24s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

env: ## Create local output/evidence folders
	mkdir -p "$(EVIDENCE_DIR)" "$(LOG_DIR)"

demo: env ## End-to-end demo for network-automation
	@echo "[network-automation] demo: wire Terraform/Ansible/Jenkins as needed"
	@echo "  - capture screenshots/logs into $(EVIDENCE_DIR)"

evidence: env ## Export screenshots/logs to Proof archive
	@echo "[network-automation] evidence: move curated proof to docs/proof/<topic>"
	@echo "  - source: $(EVIDENCE_DIR)"
	@echo "  - target: docs/proof/... (per Evidence Map)"

destroy: ## Tear down network-automation resources
	@echo "[network-automation] destroy: tear down infra if this showcase provisions any"
