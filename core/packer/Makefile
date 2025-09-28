# —— Packer (concise) ——
.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c
.SILENT:

PKR ?= .

.PHONY: help init validate build
help: ## List targets
	@awk 'BEGIN{FS":.*##";print "Packer:"} /^[a-zA-Z0-9_-]+:.*##/ {printf "  %-10s %s\n",$$1,$$2}' $(MAKEFILE_LIST)

init:       ## packer init
	packer init $(PKR)

validate:   ## packer validate
	packer validate $(PKR)

build:      ## packer build
	packer build $(PKR)
