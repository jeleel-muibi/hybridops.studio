# Makefile
# Build automation for Packer multi-OS templates on Proxmox
# Author: Jeleel Muibi | HybridOps.Studio
# Created: 2025-11-17

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

REPO_ROOT     := $(shell git rev-parse --show-toplevel 2>/dev/null || echo "../..")
CONTROL_ROOT  := $(REPO_ROOT)/control/tools/provision/packer
INIT_ROOT     := $(REPO_ROOT)/control/tools/provision/init
BIN_DIR       := $(CONTROL_ROOT)/bin
PACKER_ROOT   := $(CURDIR)

INIT_PROXMOX    := $(INIT_ROOT)/init-proxmox-env.sh
WRAPPER         := $(BIN_DIR)/build-wrapper.sh
RENDER_SCRIPT   := $(BIN_DIR)/render_unattended.sh
PRESTAGE_SCRIPT := $(BIN_DIR)/prestage-iso.sh
ENV_FILE        := $(REPO_ROOT)/infra/env/.env.proxmox

PROXMOX_CONF := $(INIT_ROOT)/.conf/proxmox.conf
PROXMOX_IP   := $(shell grep -E '^PROXMOX_IP=' $(PROXMOX_CONF) 2>/dev/null | cut -d= -f2 || echo "")

UBUNTU22_VMID ?= 9000
UBUNTU24_VMID ?= 9001
ROCKY9_VMID   ?= 9002
ROCKY10_VMID  ?= 9003
WIN2022_VMID  ?= 9100
WIN2025_VMID  ?= 9101
WIN11_VMID    ?= 9102

.PHONY: help init env.proxmox check-env sync-ubuntu sync-rocky sync-windows-server sync-windows-client
.PHONY: prestage-rocky-9 prestage-rocky-10 prestage-ubuntu-2204 prestage-ubuntu-2404
.PHONY: prestage-windows-server-2022 prestage-windows-server-2025 prestage-windows-11
.PHONY: build-ubuntu-22.04 build-ubuntu-24.04 build-rocky-9 build-rocky-10
.PHONY: build-windows-server-2022 build-windows-server-2025 build-windows-11-enterprise
.PHONY: clean clean-all clean-logs

help:
	@echo "Packer Template Build Targets"
	@echo ""
	@echo "Initialization:"
	@echo "  init                        Initialize Proxmox API access"
	@echo "  env.proxmox                 Ensure Proxmox environment variables are set"
	@echo ""
	@echo "Build Targets:"
	@echo "  build-ubuntu-22.04          Build Ubuntu 22.04 LTS template"
	@echo "  build-ubuntu-24.04          Build Ubuntu 24.04 LTS template"
	@echo "  build-rocky-9               Build Rocky Linux 9 template"
	@echo "  build-rocky-10              Build Rocky Linux 10 template"
	@echo "  build-windows-server-2022   Build Windows Server 2022 template"
	@echo "  build-windows-server-2025   Build Windows Server 2025 template"
	@echo "  build-windows-11-enterprise Build Windows 11 Enterprise template"
	@echo ""
	@echo "Cleanup:"
	@echo "  clean                       Remove synced and rendered files"
	@echo "  clean-all                   Deep clean (includes .env and cache)"
	@echo "  clean-logs                  Remove all logs and evidence (with confirmation)"

init:
	@[ -f "$(PROXMOX_CONF)" ] || { echo "Missing $(PROXMOX_CONF)"; exit 1; }
	@bash "$(INIT_PROXMOX)"

$(ENV_FILE):
	@$(MAKE) --no-print-directory init

env.proxmox: $(ENV_FILE)

check-env: env.proxmox
	@command -v packer >/dev/null 2>&1 || { echo "Packer not installed"; exit 1; }

sync-ubuntu:
	@cp shared/generic.pkr.hcl          linux/ubuntu/generic.pkr.hcl
	@cp shared/variables.global.pkr.hcl linux/ubuntu/variables.pkr.hcl
	@cp shared/config.plugins.pkr.hcl   linux/ubuntu/config.plugins.pkr.hcl
	@bash "$(RENDER_SCRIPT)" --root "$(PACKER_ROOT)" --target linux/ubuntu

sync-rocky:
	@cp shared/generic.pkr.hcl          linux/rocky/generic.pkr.hcl
	@cp shared/variables.global.pkr.hcl linux/rocky/variables.pkr.hcl
	@cp shared/config.plugins.pkr.hcl   linux/rocky/config.plugins.pkr.hcl
	@bash "$(RENDER_SCRIPT)" --root "$(PACKER_ROOT)" --target linux/rocky

sync-windows-server:
	@cp shared/generic.pkr.hcl          windows/server/generic.pkr.hcl
	@cp shared/variables.global.pkr.hcl windows/server/variables.pkr.hcl
	@cp shared/config.plugins.pkr.hcl   windows/server/config.plugins.pkr.hcl
	@bash "$(RENDER_SCRIPT)" --root "$(PACKER_ROOT)" --target windows/server

sync-windows-client:
	@cp shared/generic.pkr.hcl          windows/client/generic.pkr.hcl
	@cp shared/variables.global.pkr.hcl windows/client/variables.pkr.hcl
	@cp shared/config.plugins.pkr.hcl   windows/client/config.plugins.pkr.hcl
	@bash "$(RENDER_SCRIPT)" --root "$(PACKER_ROOT)" --target windows/client

prestage-rocky-9:
	@[ -n "$(PROXMOX_IP)" ] || { echo "PROXMOX_IP not set in $(PROXMOX_CONF)"; exit 1; }
	@$(PRESTAGE_SCRIPT) $(PROXMOX_IP) --pkrvars linux/rocky/rocky-9.pkrvars.hcl iso

prestage-rocky-10:
	@[ -n "$(PROXMOX_IP)" ] || { echo "PROXMOX_IP not set in $(PROXMOX_CONF)"; exit 1; }
	@$(PRESTAGE_SCRIPT) $(PROXMOX_IP) --pkrvars linux/rocky/rocky-10.pkrvars.hcl iso

prestage-ubuntu-2204:
	@[ -n "$(PROXMOX_IP)" ] || { echo "PROXMOX_IP not set in $(PROXMOX_CONF)"; exit 1; }
	@$(PRESTAGE_SCRIPT) $(PROXMOX_IP) --pkrvars linux/ubuntu/ubuntu-22.04.pkrvars.hcl iso

prestage-ubuntu-2404:
	@[ -n "$(PROXMOX_IP)" ] || { echo "PROXMOX_IP not set in $(PROXMOX_CONF)"; exit 1; }
	@$(PRESTAGE_SCRIPT) $(PROXMOX_IP) --pkrvars linux/ubuntu/ubuntu-24.04.pkrvars.hcl iso

prestage-windows-server-2022:
	@[ -n "$(PROXMOX_IP)" ] || { echo "PROXMOX_IP not set in $(PROXMOX_CONF)"; exit 1; }
	@$(PRESTAGE_SCRIPT) $(PROXMOX_IP) --pkrvars windows/server/windows-server-2022.pkrvars.hcl iso

prestage-windows-server-2025:
	@[ -n "$(PROXMOX_IP)" ] || { echo "PROXMOX_IP not set in $(PROXMOX_CONF)"; exit 1; }
	@$(PRESTAGE_SCRIPT) $(PROXMOX_IP) --pkrvars windows/server/windows-server-2025.pkrvars.hcl iso

prestage-windows-11:
	@[ -n "$(PROXMOX_IP)" ] || { echo "PROXMOX_IP not set in $(PROXMOX_CONF)"; exit 1; }
	@$(PRESTAGE_SCRIPT) $(PROXMOX_IP) --pkrvars windows/client/windows-11-enterprise.pkrvars.hcl iso

build-ubuntu-22.04: prestage-ubuntu-2204 check-env sync-ubuntu
	$(eval CHAIN_ID := CHAIN-$(shell date -u +%Y%m%dT%H%M%SZ)-ubuntu-22-04)
	@CHAIN_ID=$(CHAIN_ID) bash "$(WRAPPER)" --dir linux/ubuntu --key ubuntu-22.04 --hint-target linux --default-vmid $(UBUNTU22_VMID) --env "$(ENV_FILE)"
	@$(MAKE) --no-print-directory clean

build-ubuntu-24.04: prestage-ubuntu-2404 check-env sync-ubuntu
	$(eval CHAIN_ID := CHAIN-$(shell date -u +%Y%m%dT%H%M%SZ)-ubuntu-24-04)
	@CHAIN_ID=$(CHAIN_ID) bash "$(WRAPPER)" --dir linux/ubuntu --key ubuntu-24.04 --hint-target linux --default-vmid $(UBUNTU24_VMID) --env "$(ENV_FILE)"
	@$(MAKE) --no-print-directory clean

build-rocky-9: prestage-rocky-9 check-env sync-rocky
	$(eval CHAIN_ID := CHAIN-$(shell date -u +%Y%m%dT%H%M%SZ)-rocky-9)
	@CHAIN_ID=$(CHAIN_ID) bash "$(WRAPPER)" --dir linux/rocky --key rocky-9 --hint-target linux --default-vmid $(ROCKY9_VMID) --env "$(ENV_FILE)"
	@$(MAKE) --no-print-directory clean

build-rocky-10: prestage-rocky-10 check-env sync-rocky
	$(eval CHAIN_ID := CHAIN-$(shell date -u +%Y%m%dT%H%M%SZ)-rocky-10)
	@CHAIN_ID=$(CHAIN_ID) bash "$(WRAPPER)" --dir linux/rocky --key rocky-10 --hint-target linux --default-vmid $(ROCKY10_VMID) --env "$(ENV_FILE)"
	@$(MAKE) --no-print-directory clean

build-windows-server-2022: prestage-windows-server-2022 check-env sync-windows-server
	$(eval CHAIN_ID := CHAIN-$(shell date -u +%Y%m%dT%H%M%SZ)-windows-server-2022)
	@CHAIN_ID=$(CHAIN_ID) bash "$(WRAPPER)" --dir windows/server --key windows-server-2022 --hint-target windows --default-vmid $(WIN2022_VMID) --env "$(ENV_FILE)"
	@$(MAKE) --no-print-directory clean

build-windows-server-2025: prestage-windows-server-2025 check-env sync-windows-server
	$(eval CHAIN_ID := CHAIN-$(shell date -u +%Y%m%dT%H%M%SZ)-windows-server-2025)
	@CHAIN_ID=$(CHAIN_ID) bash "$(WRAPPER)" --dir windows/server --key windows-server-2025 --hint-target windows --default-vmid $(WIN2025_VMID) --env "$(ENV_FILE)"
	@$(MAKE) --no-print-directory clean

build-windows-11-enterprise: prestage-windows-11 check-env sync-windows-client
	$(eval CHAIN_ID := CHAIN-$(shell date -u +%Y%m%dT%H%M%SZ)-windows-11-enterprise)
	@CHAIN_ID=$(CHAIN_ID) bash "$(WRAPPER)" --dir windows/client --key windows-11-enterprise --hint-target windows --default-vmid $(WIN11_VMID) --env "$(ENV_FILE)"
	@$(MAKE) --no-print-directory clean

clean:
	@echo "Cleaning synced and rendered files..."
	@rm -f linux/ubuntu/generic.pkr.hcl linux/ubuntu/variables.pkr.hcl linux/ubuntu/config.plugins.pkr.hcl
	@rm -f linux/rocky/generic.pkr.hcl linux/rocky/variables.pkr.hcl linux/rocky/config.plugins.pkr.hcl
	@rm -f windows/server/generic.pkr.hcl windows/server/variables.pkr.hcl windows/server/config.plugins.pkr.hcl
	@rm -f windows/client/generic.pkr.hcl windows/client/variables.pkr.hcl windows/client/config.plugins.pkr.hcl
	@rm -f linux/ubuntu/http/user-data linux/ubuntu/http/meta-data
	@rm -f linux/rocky/http/ks.cfg
	@rm -f windows/server/http/Autounattend.xml
	@rm -f windows/client/http/Autounattend.xml

clean-all: clean
	@echo "Deep cleaning (.env, cache, Packer plugins)..."
	@rm -f "$(ENV_FILE)"
	@rm -rf packer_cache linux/*/packer_cache windows/*/packer_cache
	@find . -type d -name '.terraform.d' -exec rm -rf {} + 2>/dev/null || true

clean-logs:
	@echo "WARNING: This will remove ALL logs and evidence!"
	@read -p "Continue? (y/N): " -n 1 -r; echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		rm -rf $(REPO_ROOT)/output/logs/packer; \
		rm -rf $(REPO_ROOT)/docs/proof/platform/packer-builds; \
		echo "Logs and evidence removed"; \
	else \
		echo "Cancelled"; \
	fi
