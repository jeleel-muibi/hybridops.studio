# —— Ansible (concise) ——
.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c
.SILENT:

INV  ?= inventories/hosts.ini
PLAY ?= site.yml

.PHONY: help lint check run
help: ## List targets
	@awk 'BEGIN{FS":.*##";print "Ansible:"} /^[a-zA-Z0-9_-]+:.*##/ {printf "  %-10s %s\n",$$1,$$2}' $(MAKEFILE_LIST)

lint:   ## ansible-lint (if installed)
	ansible-lint -v . || true

check:  ## dry-run
	ansible-playbook -i $(INV) $(PLAY) --check -v

run:    ## apply
	ansible-playbook -i $(INV) $(PLAY) -v
