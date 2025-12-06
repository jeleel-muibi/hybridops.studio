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
MKDOCS := $(VENV_BIN)/mkdocs
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

export TF_IN_AUTOMATION := 1
TF_DIR_AZ := terraform-infra/environments/cloud/azure
TF_DIR_GCP := terraform-infra/environments/cloud/gcp
TFVARS_AZ ?= $(TF_DIR_AZ)/vars.dr.tfvars
TFVARS_GCP ?= $(TF_DIR_GCP)/vars.dr.tfvars
BACKEND_AZ ?= terraform-infra/backend-configs/azure.backend.hcl
BACKEND_GCP ?= terraform-infra/backend-configs/gcp.backend.hcl
TF_APPLY := terraform -input=false -auto-approve
TF_INIT := terraform init -upgrade -reconfigure

KUBECONFIG_AZ ?= $(HOME)/.kube/azure
KUBECONFIG_GCP ?= $(HOME)/.kube/gcp

.PHONY: help docs.prepare docs.build docs.serve docs.clean \
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
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "1. Install system prerequisites:"
	@echo "   make prereq.all      # Install everything (system + Python)"
	@echo "   make prereq.base     # Core tools only (Terraform, kubectl, Packer, gh)"
	@echo "   make prereq.azure    # Azure CLI (optional)"
	@echo "   make prereq.gcp      # GCP SDK (optional)"
	@echo "   make prereq.check    # Verify installations"
	@echo ""
	@echo "2. Build VM templates with Packer:"
	@echo "   ./control/tools/provision/init/init-proxmox-env.sh <proxmox-ip>"
	@echo "   cd infra/packer"
	@echo "   make build-ubuntu          # Ubuntu 22.04 LTS (~15-20 min)"
	@echo "   make build-rocky           # Rocky Linux 9 (~15-20 min)"
	@echo "   make build-windows         # Windows Server 2022 (~60-90 min)"
	@echo ""
	@echo "3. Verify templates:"
	@echo "   ssh root@<proxmox-ip> 'qm list | grep -E \"9000|9001|9002|9100\"'"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "Daily Operations"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "Environment:"
	@echo "  make env.setup              # Create output directories"
	@echo "  make env.print              # Show tool versions"
	@echo "  make sanity                 # Verify tools"
	@echo ""
	@echo "Domain Deployments:"
	@echo "  make linux.<target>         # Linux operations"
	@echo "  make kubernetes.<target>    # Kubernetes operations"
	@echo "  make network.<target>       # Network automation"
	@echo "  make windows.<target>       # Windows operations"
	@echo "  make jenkins.<target>       # CI/CD pipeline"
	@echo "  make netbox.<target>        # Network documentation"
	@echo ""
	@echo "DR/Cloud Operations:"
	@echo "  make dr.db.promote CLOUD=azure       # Promote database"
	@echo "  make dr.cluster.attach CLOUD=gcp     # Attach cluster"
	@echo "  make dr.gitops.sync CLOUD=azure      # Sync GitOps"
	@echo "  make dr.dns.cutover CLOUD=gcp        # DNS cutover"
	@echo ""
	@echo "Burst Scaling:"
	@echo "  make burst.scale.up CLOUD=azure      # Scale up"
	@echo "  make burst.validate                  # Validate"
	@echo "  make burst.scale.down CLOUD=azure    # Scale down"
	@echo ""
	@echo "Documentation:"
	@echo "  make docs.build             # Build all documentation sites"
	@echo "  make docs.serve             # Serve docs locally"
	@echo "  make docs.clean             # Clean generated docs"
	@echo ""
	@echo "Showcases:"
	@echo "  make showcase.list                               # List all showcases"
	@echo "  make showcase.linux-administration.demo          # Demo Linux skills"
	@echo "  make showcase.network-automation.demo            # Demo network automation"
	@echo "  make showcase.dr-failover-to-cloud.demo          # Demo DR failover"
	@echo "  make showcase.kubernetes-autoscaling.demo        # Demo K8s autoscaling"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "For detailed help:"
	@echo "  make -C deployment/<domain> help"
	@echo "  make -C infra/packer help"
	@echo "  make -C control/tools/setup help"
	@echo ""
	@echo "Note: Python environment auto-configures when needed"
	@echo ""

prereq.%: ## Install system prerequisites (base|azure|gcp|python.env|all|check) - e.g. make prereq.base
	@$(MAKE) -C control/tools/setup $*

venv.setup: $(VENV_MARKER) ## Setup Python virtual environment

$(VENV_MARKER): control/requirements.txt
	@$(MAKE) -C control/tools/setup python.env

venv.clean: ## Remove virtual environment
	@rm -rf $(VENV_DIR)
	@echo "Virtual environment removed."

docs.prepare: $(VENV_MARKER) ## Generate indexes and MkDocs configuration
	@$(PYTHON) control/tools/docs/indexing/gen_adr_index.py
	@$(PYTHON) control/tools/docs/indexing/gen_howto_index.py
	@$(PYTHON) control/tools/docs/indexing/gen_runbook_index.py
	@$(PYTHON) control/tools/docs/indexing/gen_ci_index.py
	@$(PYTHON) control/tools/docs/indexing/gen_showcase_index.py
	@$(PYTHON) control/tools/docs/mkdoc/build_generator/stub_filter.py
	@$(PYTHON) control/tools/docs/mkdoc/build_generator/build_mkdocs_trees.py

docs.build: docs.prepare ## Build public and academy documentation sites
	@$(MKDOCS) build -f control/tools/docs/mkdoc/mkdocs.public.yml
	@$(MKDOCS) build -f control/tools/docs/mkdoc/mkdocs.academy.yml

docs.serve: $(VENV_MARKER) ## Serve documentation locally for preview
	@$(MKDOCS) serve -f control/tools/docs/mkdoc/mkdocs.public.yml

docs.clean: ## Remove generated documentation artifacts
	@rm -f docs/adr/README.md docs/runbooks/README.md docs/howto/README.md docs/ci/README.md docs/showcases/README.md
	@rm -rf docs/adr/by-domain docs/runbooks/by-category docs/howto/by-topic docs/ci/by-area docs/showcases/by-audience
	@rm -rf deployment/build/docs deployment/build/site/docs-academy deployment/build/site/docs-public
	@rm -f control/tools/docs/mkdoc/mkdocs.public.yml control/tools/docs/mkdoc/mkdocs.academy.yml
	@rm -f docs/runbooks/000-INDEX.md docs/howto/000-INDEX.md docs/ci/000-INDEX.md
	@clear
	@echo "Documentation artifacts and terminal cleaned."

env.setup: ## Create output directories
	@mkdir -p "$(LOGS_DIR)" \
	  "$(RUNS_DIR)"/{linux,kubernetes,netbox,network,windows,jenkins} \
	  "$(ART_DIR)"/{inventories,dr-drills,decision} \
	  "$(OUTPUT_DIR)"/{logs/terraform,artifacts/terraform}

env.print: ## Display tool versions and paths
	@echo "ANSIBLE_VERSION=$$(ansible --version 2>/dev/null | head -1 || echo 'not installed')"
	@echo "TERRAFORM_VERSION=$$(terraform version 2>/dev/null | head -1 || echo 'not installed')"
	@echo "KUBECTL_VERSION=$$(kubectl version --client --short 2>/dev/null || echo 'not installed')"
	@echo "PYTHON_VERSION=$$(python3 --version 2>/dev/null || echo 'not installed')"
	@echo "OUTPUT_DIR=$(OUTPUT_DIR)"

sanity: ## Verify required tools are installed
	@command -v ansible >/dev/null || { echo "ansible not found - run: make prereq.all"; exit 1; }
	@command -v terraform >/dev/null || { echo "terraform not found - run: make prereq.base"; exit 1; }
	@command -v kubectl >/dev/null || { echo "kubectl not found - run: make prereq.base"; exit 1; }

fmt: ## Format Terraform files recursively
	@terraform -chdir=terraform-infra fmt -recursive || true

lint: $(VENV_MARKER) ## Run linters on Ansible and YAML files
	@$(VENV_BIN)/ansible-lint || true
	@$(VENV_BIN)/yamllint . || true

$(addsuffix .%, $(DOMAINS)): $(VENV_MARKER) ## Route domain targets to deployment subdirectories
	@d=$(@D); t=$(@F); $(MAKE) -C deployment/$$d $$t

gitops: ## Bootstrap GitOps components
	@kubectl apply -f deployment/kubernetes/gitops/bootstrap.yaml

set-kubecontext-azure: ## Set Kubernetes context for Azure
	@[ -f "$(KUBECONFIG_AZ)" ] && export KUBECONFIG="$(KUBECONFIG_AZ)" || true

set-kubecontext-gcp: ## Set Kubernetes context for GCP
	@[ -f "$(KUBECONFIG_GCP)" ] && export KUBECONFIG="$(KUBECONFIG_GCP)" || true

dr.db.promote: ## Restore and promote database in target cloud
	@[ -z "$(CLOUD)" ] && { echo "Error: CLOUD not set (use: CLOUD=azure or CLOUD=gcp)"; exit 1; } || true
	@bash deployment/common/scripts/dr_restore_promote.sh $(CLOUD)

dr.cluster.attach: ## Attach cloud cluster via Terraform
	@[ -z "$(CLOUD)" ] && { echo "Error: CLOUD not set (use: CLOUD=azure or CLOUD=gcp)"; exit 1; } || true
	@if [ "$(CLOUD)" = "azure" ]; then \
	  cd $(TF_DIR_AZ) && $(TF_INIT) -backend-config=$(abspath $(BACKEND_AZ)) && \
	    $(TF_APPLY) -var-file=$(abspath $(TFVARS_AZ)); \
	elif [ "$(CLOUD)" = "gcp" ]; then \
	  cd $(TF_DIR_GCP) && $(TF_INIT) -backend-config=$(abspath $(BACKEND_GCP)) && \
	    $(TF_APPLY) -var-file=$(abspath $(TFVARS_GCP)); \
	fi

dr.gitops.sync: ## Sync GitOps state in target cloud
	@[ -z "$(CLOUD)" ] && { echo "Error: CLOUD not set (use: CLOUD=azure or CLOUD=gcp)"; exit 1; } || true
	@$(MAKE) set-kubecontext-$(CLOUD)
	@kubectl get ns || true
	@kubectl -n argocd rollout status deploy/argocd-repo-server --timeout=5m

dr.dns.cutover: ## Update DNS to point to target cloud
	@[ -z "$(CLOUD)" ] && { echo "Error: CLOUD not set (use: CLOUD=azure or CLOUD=gcp)"; exit 1; } || true
	@bash deployment/common/scripts/dns_cutover.sh $(CLOUD)

burst.scale.up: ## Scale up cloud cluster resources
	@[ -z "$(CLOUD)" ] && { echo "Error: CLOUD not set (use: CLOUD=azure or CLOUD=gcp)"; exit 1; } || true
	@if [ "$(CLOUD)" = "azure" ]; then \
	  cd $(TF_DIR_AZ) && $(TF_APPLY) -var-file=$(abspath $(TFVARS_AZ)) -var="burst=true"; \
	elif [ "$(CLOUD)" = "gcp" ]; then \
	  cd $(TF_DIR_GCP) && $(TF_APPLY) -var-file=$(abspath $(TFVARS_GCP)) -var="burst=true"; \
	fi

burst.validate: ## Validate cluster state after scaling
	@kubectl get nodes -o wide || true
	@kubectl get pods -A || true

burst.scale.down: ## Scale down burst resources
	@[ -z "$(CLOUD)" ] && { echo "Error: CLOUD not set (use: CLOUD=azure or CLOUD=gcp)"; exit 1; } || true
	@if [ "$(CLOUD)" = "azure" ]; then \
	  cd $(TF_DIR_AZ) && $(TF_APPLY) -var-file=$(abspath $(TFVARS_AZ)) -var="burst=false"; \
	elif [ "$(CLOUD)" = "gcp" ]; then \
	  cd $(TF_DIR_GCP) && $(TF_APPLY) -var-file=$(abspath $(TFVARS_GCP)) -var="burst=false"; \
	fi

showcase.%: ## Display showcase usage
	@echo "Usage: make showcase.<name>.<target>"
	@echo "Targets: demo, destroy, evidence"
	@echo "Names:"; echo "$(SHOWCASES)" | tr ' ' '\n'

showcase.list: ## List all available showcases
	@echo "$(SHOWCASES)" | tr ' ' '\n'

showcase.avd-zerotouch-deployment.%:
	@$(MAKE) -C showcases/avd-zerotouch-deployment $*

showcase.ci-cd-pipeline.%:
	@$(MAKE) -C showcases/ci-cd-pipeline $*

showcase.dr-failover-to-cloud.%:
	@$(MAKE) -C showcases/dr-failover-to-cloud $*

showcase.kubernetes-autoscaling.%:
	@$(MAKE) -C showcases/kubernetes-autoscaling $*

showcase.linux-administration.%:
	@$(MAKE) -C showcases/linux-administration $*

showcase.migrate-onprem-to-cloud.%:
	@$(MAKE) -C showcases/migrate-onprem-to-cloud $*

showcase.network-automation.%:
	@$(MAKE) -C showcases/network-automation $*

showcase.dr-failback-to-onprem.%:
	@$(MAKE) -C showcases/dr-failback-to-onprem $*

showcase.scale-workload-to-cloud.%:
	@$(MAKE) -C showcases/scale-workload-to-cloud $*

showcase.windows-administration.%:
	@$(MAKE) -C showcases/windows-administration $*
