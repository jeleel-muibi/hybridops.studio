# HybridOps.Studio - Root Makefile
# Orchestrates multi-domain infrastructure, DR workflows, and showcase deployments
# Maintainer: HybridOps.Studio
# Last Modified: 2025-01-23

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:
MAKEFLAGS += --no-builtin-rules
.DEFAULT_GOAL := help

VENV_DIR := .venv
VENV_MARKER := $(VENV_DIR)/.installed
VENV_BIN := $(VENV_DIR)/bin
PYTHON := $(VENV_BIN)/python3
TERRAFORM ?= terraform

OUTPUT_DIR ?= output
LOGS_DIR := $(OUTPUT_DIR)/logs/ansible
ART_DIR := $(OUTPUT_DIR)/artifacts
RUNS_DIR := $(ART_DIR)/ansible-runs

DOMAINS := linux kubernetes netbox network windows jenkins
SHOWCASES := \
  avd-zerotouch-deployment \
  ci-cd-pipeline \
  dr-failover-to-cloud \
  kubernetes-autoscaling \
  linux-administration \
  migrate-onprem-to-cloud \
  network-automation \
  dr-failback-to-onprem \
  scale-workload-to-cloud \
  windows-administration

CLOUD ?= $(CLOUD_PROVIDER)

ANSIBLE_CONFIG := $(abspath deployment/ansible.cfg)
export ANSIBLE_CONFIG

TF_CLOUD_CFG ?= control/tools/terraform/backend-configs/remote/backend.hcl
TF_LOCAL_CFG ?= control/tools/terraform/backend-configs/local/backend.hcl
TF_BACKEND_CFG ?= $(TF_CLOUD_CFG)

TF_APPLY := terraform -input=false -auto-approve
TF_INIT := terraform init -upgrade -reconfigure

KUBECONFIG_AZ ?= $(HOME)/.kube/azure
KUBECONFIG_GCP ?= $(HOME)/.kube/gcp

.PHONY: help \
        env.setup env.print sanity fmt lint \
        $(addsuffix .%, $(DOMAINS)) \
        gitops dr.db.promote dr.cluster.attach dr.gitops.sync dr.dns.cutover \
        burst.scale.up burst.validate burst.scale.down \
        set-kubecontext-azure set-kubecontext-gcp \
        showcase.% showcase.list \
        showcase.avd-zerotouch-deployment.% \
        showcase.ci-cd-pipeline.% \
        showcase.dr-failover-to-cloud.% \
        showcase.kubernetes-autoscaling.% \
        showcase.linux-administration.% \
        showcase.migrate-onprem-to-cloud.% \
        showcase.network-automation.% \
        showcase.dr-failback-to-onprem.% \
        showcase.scale-workload-to-cloud.% \
        showcase.windows-administration.% \
        prereq.% venv.setup venv.clean

help: ## Show usage guide
	@awk 'BEGIN{FS=" *:.*## *"; printf "\nTargets:\n"} /^[a-zA-Z0-9_.-]+:.*##/{printf "  \033[36m%-34s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Showcases:"
	@echo "  $(SHOWCASES)" | tr ' ' '\n' | sed 's/^/  /'
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "Foundation Setup (First Time Only)"
	@echo "  make env.setup          # Generate env files for Proxmox/Azure/GCP"
	@echo ""
	@echo "Sanity & Formatting"
	@echo "  make sanity             # Validate Terraform, Ansible, Packer configs"
	@echo "  make fmt                # Run fmt for Terraform and Packer"
	@echo "  make lint               # Run Ansible lint checks"
	@echo ""
	@echo "Domain-Specific Operations"
	@echo "  make linux.<target>     # e.g. linux.bootstrap, linux.hardening"
	@echo "  make kubernetes.<target>"
	@echo "  make netbox.<target>"
	@echo "  make network.<target>"
	@echo "  make windows.<target>"
	@echo "  make jenkins.<target>"
	@echo ""
	@echo "GitOps & DR"
	@echo "  make gitops             # Sync manifests via GitOps"
	@echo "  make dr.db.promote      # Promote DR database"
	@echo "  make dr.cluster.attach  # Attach DR cluster"
	@echo "  make dr.gitops.sync     # Sync DR GitOps state"
	@echo "  make dr.dns.cutover     # DNS cutover to DR site"
	@echo ""
	@echo "Bursting"
	@echo "  make burst.scale.up     # Scale workloads to cloud"
	@echo "  make burst.validate     # Validate burst workloads"
	@echo "  make burst.scale.down   # Scale down burst workloads"
	@echo ""
	@echo "Showcases"
	@echo "  make showcase.list      # List available showcases"
	@echo "  make showcase.<name>.run"
	@echo "  make showcase.<name>.evidence"
	@echo ""
	@echo "Prerequisites"
	@echo "  make prereq.base        # Install base tooling"
	@echo "  make prereq.azure       # Azure CLI"
	@echo "  make prereq.gcp         # GCP SDK"
	@echo "  make prereq.python.env  # Python venv for tooling"
	@echo "  make prereq.all         # All of the above"
	@echo ""
	@echo "Virtualenv"
	@echo "  make venv.setup         # Ensure venv exists"
	@echo "  make venv.clean         # Remove venv"
	@echo ""

env.setup: ## Generate environment artifacts (Proxmox, Azure, GCP)
	@./control/tools/provision/init/init-proxmox-env.sh
	@./control/tools/provision/init/init-azure-env.sh
	@./control/tools/provision/init/init-gcp-env.sh

env.print: ## Print resolved environment variables
	@echo "CLOUD_PROVIDER=$(CLOUD)"
	@echo "TF_BACKEND_CFG=$(TF_BACKEND_CFG)"
	@echo "ANSIBLE_CONFIG=$(ANSIBLE_CONFIG)"
	@echo "KUBECONFIG_AZ=$(KUBECONFIG_AZ)"
	@echo "KUBECONFIG_GCP=$(KUBECONFIG_GCP)"

sanity: ## Run basic validation across Terraform, Ansible and Packer
	@echo "Running Terraform validate..."
	@find infra/terraform -maxdepth 4 -type f -name "*.tf" -print0 | xargs -0 -I{} dirname {} | sort -u | while read -r dir; do \
	  echo "  -> $$dir"; \
	  (cd "$$dir" && $(TERRAFORM) validate || exit 1); \
	done
	@echo "Running Ansible syntax checks..."
	@ANSIBLE_CONFIG=$(ANSIBLE_CONFIG) ansible-playbook -i "localhost," -c local control/tools/ansible/sanity/syntax_check.yml
	@echo "Running Packer validate..."
	@cd infra/packer-multi-os && make validate

fmt: ## Run fmt for Terraform and Packer
	@echo "Running terraform fmt..."
	@find infra/terraform -type f -name "*.tf" -print0 | xargs -0 -I{} dirname {} | sort -u | while read -r dir; do \
	  echo "  -> $$dir"; \
	  (cd "$$dir" && $(TERRAFORM) fmt -write=true); \
	done
	@echo "Running packer fmt..."
	@cd infra/packer-multi-os && packer fmt -recursive .

lint: ## Run Ansible lint checks
	@echo "Running ansible-lint..."
	@ANSIBLE_CONFIG=$(ANSIBLE_CONFIG) ansible-lint

linux.%: ## Delegate to linux domain Makefile - e.g. make linux.bootstrap
	@$(MAKE) -C deployment/linux $*

kubernetes.%: ## Delegate to kubernetes domain Makefile
	@$(MAKE) -C deployment/kubernetes $*

netbox.%: ## Delegate to netbox domain Makefile
	@$(MAKE) -C deployment/netbox $*

network.%: ## Delegate to network domain Makefile
	@$(MAKE) -C deployment/network $*

windows.%: ## Delegate to windows domain Makefile
	@$(MAKE) -C deployment/windows $*

jenkins.%: ## Delegate to jenkins domain Makefile
	@$(MAKE) -C deployment/jenkins $*

gitops: ## Trigger GitOps sync (placeholder)
	@echo "GitOps sync not yet implemented - see GitOps ADR."

dr.db.promote: ## Promote DR database
	@echo "DR DB promote not yet implemented - see DR ADR."

dr.cluster.attach: ## Attach DR cluster
	@echo "DR cluster attach not yet implemented - see DR ADR."

dr.gitops.sync: ## Sync GitOps for DR
	@echo "DR GitOps sync not yet implemented - see DR ADR."

dr.dns.cutover: ## DNS cutover to DR
	@echo "DR DNS cutover not yet implemented - see DR ADR."

burst.scale.up: ## Scale workloads to cloud
	@echo "Burst scale up not yet implemented - see burst ADR."

burst.validate: ## Validate burst workloads
	@echo "Burst validate not yet implemented - see burst ADR."

burst.scale.down: ## Scale workloads down
	@echo "Burst scale down not yet implemented - see burst ADR."

set-kubecontext-azure: ## Set kubeconfig context for Azure AKS
	@KUBECONFIG=$(KUBECONFIG_AZ) kubectl config use-context aks-hybridops || true

set-kubecontext-gcp: ## Set kubeconfig context for GCP GKE
	@KUBECONFIG=$(KUBECONFIG_GCP) kubectl config use-context gke-hybridops || true

showcase.list: ## List available showcases
	@echo "$(SHOWCASES)" | tr ' ' '\n'

showcase.%: ## Run a specific showcase target - e.g. showcase.ci-cd-pipeline.run
	@case "$*" in \
	  avd-zerotouch-deployment.*)  $(MAKE) -C deployment/showcases/avd-zerotouch-deployment $${*#avd-zerotouch-deployment.} ;; \
	  ci-cd-pipeline.*)            $(MAKE) -C deployment/showcases/ci-cd-pipeline $${*#ci-cd-pipeline.} ;; \
	  dr-failover-to-cloud.*)      $(MAKE) -C deployment/showcases/dr-failover-to-cloud $${*#dr-failover-to-cloud.} ;; \
	  kubernetes-autoscaling.*)    $(MAKE) -C deployment/showcases/kubernetes-autoscaling $${*#kubernetes-autoscaling.} ;; \
	  linux-administration.*)      $(MAKE) -C deployment/showcases/linux-administration $${*#linux-administration.} ;; \
	  migrate-onprem-to-cloud.*)   $(MAKE) -C deployment/showcases/migrate-onprem-to-cloud $${*#migrate-onprem-to-cloud.} ;; \
	  network-automation.*)        $(MAKE) -C deployment/showcases/network-automation $${*#network-automation.} ;; \
	  dr-failback-to-onprem.*)     $(MAKE) -C deployment/showcases/dr-failback-to-onprem $${*#dr-failback-to-onprem.} ;; \
	  scale-workload-to-cloud.*)   $(MAKE) -C deployment/showcases/scale-workload-to-cloud $${*#scale-workload-to-cloud.} ;; \
	  windows-administration.*)    $(MAKE) -C deployment/showcases/windows-administration $${*#windows-administration.} ;; \
	  *) echo "Unknown showcase: $*"; exit 1 ;; \
	esac

v: help ## Alias for help

env.setup: ## Generate environment artifacts (Proxmox, Azure, GCP)
	@./control/tools/provision/init/init-proxmox-env.sh
	@./control/tools/provision/init/init-azure-env.sh
	@./control/tools/provision/init/init-gcp-env.sh

env.print: ## Print resolved environment variables
	@echo "CLOUD_PROVIDER=$(CLOUD)"
	@echo "TF_BACKEND_CFG=$(TF_BACKEND_CFG)"
	@echo "ANSIBLE_CONFIG=$(ANSIBLE_CONFIG)"
	@echo "KUBECONFIG_AZ=$(KUBECONFIG_AZ)"
	@echo "KUBECONFIG_GCP=$(KUBECONFIG_GCP)"

prereq.%: ## Install system prerequisites (base|azure|gcp|python.env|all|check) - e.g. make prereq.base
	@$(MAKE) -C control/tools/setup $*

venv.setup: $(VENV_MARKER) ## Setup Python virtual environment

$(VENV_MARKER): control/requirements.txt
	@$(MAKE) -C control/tools/setup python.env

venv.clean: ## Remove virtual environment
	@rm -rf $(VENV_DIR)
	@echo "Virtual environment removed."
