# —— Showcases Orchestrator (concise) ——
.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c
.SILENT:

SUBS := ci-cd-pipeline-showcase hybrid-failover-migration-showcase kubernetes-autoscaling-showcase \
        linux-administration-showcase network-automation-nornir windows-administration-showcase

.PHONY: help list
help: ## List sub-projects & how to run them
	@echo "Showcases:"
	@for s in $(SUBS); do echo "  - $$s (use: make -C showcases/$$s help)"; done
	@echo
	@echo "Examples:"
	@echo "  make -C showcases/network-automation-nornir dry-run"
	@echo "  make -C showcases/hybrid-failover-migration-showcase plan SCENARIO=failover-azure"

list: ## List available sub-project directories
	@printf "%s\n" $(SUBS)
