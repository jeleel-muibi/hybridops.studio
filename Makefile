# ===== Root Makefile: environment sanity + routing + provider-aware DR =====
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:
MAKEFLAGS += --no-builtin-rules
.DEFAULT_GOAL := help

# -----------------------------------------------------------------------------
# Paths
# Centralized output sink (logs, artifacts, evidence)
OUTPUT_DIR ?= output
LOGS_DIR   := $(OUTPUT_DIR)/logs/ansible
ART_DIR    := $(OUTPUT_DIR)/artifacts
RUNS_DIR   := $(ART_DIR)/ansible-runs

# Domains & Showcases
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

# Provider wiring
CLOUD ?= $(CLOUD_PROVIDER)

# Ansible config (keep repo root clean; everything points here)
ANSIBLE_CONFIG := $(abspath deployment/ansible.cfg)
export ANSIBLE_CONFIG

# Terraform helpers
export TF_IN_AUTOMATION := 1
TF_DIR_AZ   := terraform-infra/environments/cloud/azure
TF_DIR_GCP  := terraform-infra/environments/cloud/gcp
TFVARS_AZ   ?= $(TF_DIR_AZ)/vars.dr.tfvars
TFVARS_GCP  ?= $(TF_DIR_GCP)/vars.dr.tfvars
BACKEND_AZ  ?= terraform-infra/backend-configs/azure.backend.hcl
BACKEND_GCP ?= terraform-infra/backend-configs/gcp.backend.hcl
TF_APPLY    := terraform -input=false -auto-approve
TF_INIT     := terraform init -upgrade -reconfigure

# Optional kubeconfig contexts
KUBECONFIG_AZ  ?= $(HOME)/.kube/azure
KUBECONFIG_GCP ?= $(HOME)/.kube/gcp

# -----------------------------------------------------------------------------
.PHONY: help adr.index env.setup env.print sanity fmt lint runbooks runbooks.index howto.index \
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
        showcase.windows-administration.%

help: ## Show this help
	@awk 'BEGIN{FS":.*##"; printf "\nTargets:\n"} /^[a-zA-Z0-9_.-]+:.*##/{printf "  \033[36m%-34s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo "\nShowcases:"
	@echo "  $(SHOWCASES)"

adr.index:  ## Generate ADR index and domain pages
	@python3 control/tools/repo/indexing/gen_adr_index.py

howto.index: ## Generate How-To index
	@python3 control/tools/repo/indexing/gen_howto_index.py

runbooks.index:
	@python3 control/tools/repo/indexing/gen_runbook_index.py

env.setup: ## Create output/ dirs for logs & artifacts
	mkdir -p "$(LOGS_DIR)" 	  "$(RUNS_DIR)"/{linux,kubernetes,netbox,network,windows,jenkins} 	  "$(ART_DIR)"/{inventories,dr-drills,decision} 	  "$(OUTPUT_DIR)"/{logs/terraform,artifacts/terraform}

env.print: ## Print tool versions and key paths
	echo "ANSIBLE_VERSION=$$(ansible --version 2>/dev/null | head -1 || echo 'n/a')"
	echo "TERRAFORM_VERSION=$$(terraform version 2>/dev/null | head -1 || echo 'n/a')"
	echo "KUBECTL_VERSION=$$(kubectl version --client --short 2>/dev/null || echo 'n/a')"
	echo "OUTPUT_DIR=$(OUTPUT_DIR)"

sanity: ## Check required tools/versions/credentials
	command -v ansible   >/dev/null || { echo "ansible not found";   exit 1; }
	command -v terraform >/dev/null || { echo "terraform not found"; exit 1; }
	command -v kubectl   >/dev/null || { echo "kubectl not found";   exit 1; }
	echo "[OK] core tools present"

fmt: ## Terraform fmt recursively
	terraform -chdir=terraform-infra fmt -recursive || true

lint: ## ansible-lint + yamllint
	ansible-lint || true
	yamllint . || true

# Route <domain>.<target> to deployment/<domain>/Makefile
$(addsuffix .%, $(DOMAINS)): ## Route domain to deployment/<domain>/Makefile
	d=$(@D); t=$(@F); \
	$(MAKE) -C deployment/$$d $$t

gitops: ## Bootstrap GitOps (Argo/Flux) manifests
	kubectl apply -f deployment/kubernetes/gitops/bootstrap.yaml

set-kubecontext-azure: ## Set kube context for Azure
	@[ -f "$(KUBECONFIG_AZ)" ] && export KUBECONFIG="$(KUBECONFIG_AZ)" || true

set-kubecontext-gcp: ## Set kube context for GCP
	@[ -f "$(KUBECONFIG_GCP)" ] && export KUBECONFIG="$(KUBECONFIG_GCP)" || true

# ----------------------- DR / Burst orchestration -----------------------------
dr.db.promote: ## Restore/promote Postgres in target cloud
	@if [ "$(CLOUD)" = "azure" ]; then \
	  echo "[DR] Promote/restore Postgres → Azure"; \
	  bash deployment/common/scripts/dr_restore_promote.sh azure; \
	elif [ "$(CLOUD)" = "gcp" ]; then \
	  echo "[DR] Promote/restore Postgres → GCP"; \
	  bash deployment/common/scripts/dr_restore_promote.sh gcp; \
	else \
	  echo "CLOUD_PROVIDER not set (azure|gcp)"; exit 2; \
	fi

dr.cluster.attach: ## Attach AKS/GKE (Terraform init/apply with provider-specific backend/vars)
	@if [ "$(CLOUD)" = "azure" ]; then \
	  echo "[DR] Terraform attach AKS"; \
	  (cd $(TF_DIR_AZ) && $(TF_INIT) -backend-config=$(abspath $(BACKEND_AZ)) && \
	    $(TF_APPLY) -var-file=$(abspath $(TFVARS_AZ))); \
	elif [ "$(CLOUD)" = "gcp" ]; then \
	  echo "[DR] Terraform attach GKE"; \
	  (cd $(TF_DIR_GCP) && $(TF_INIT) -backend-config=$(abspath $(BACKEND_GCP)) && \
	    $(TF_APPLY) -var-file=$(abspath $(TFVARS_GCP))); \
	else \
	  echo "CLOUD_PROVIDER not set (azure|gcp)"; exit 2; \
	fi

dr.gitops.sync: ## Set kubecontext and wait for GitOps to be healthy
	@if [ "$(CLOUD)" = "azure" ]; then \
	  $(MAKE) set-kubecontext-azure; \
	  kubectl get ns || true; \
	  kubectl -n argocd rollout status deploy/argocd-repo-server --timeout=5m; \
	elif [ "$(CLOUD)" = "gcp" ]; then \
	  $(MAKE) set-kubecontext-gcp; \
	  kubectl get ns || true; \
	  kubectl -n argocd rollout status deploy/argocd-repo-server --timeout=5m; \
	else \
	  echo "CLOUD_PROVIDER not set (azure|gcp)"; exit 2; \
	fi

dr.dns.cutover: ## Point public DNS to the selected cloud endpoints
	@if [ "$(CLOUD)" = "azure" ]; then \
	  bash deployment/common/scripts/dns_cutover.sh azure; \
	elif [ "$(CLOUD)" = "gcp" ]; then \
	  bash deployment/common/scripts/dns_cutover.sh gcp; \
	else \
	  echo "CLOUD_PROVIDER not set (azure|gcp)"; exit 2; \
	fi

burst.scale.up: ## Scale/burst the selected cloud cluster up
	@if [ "$(CLOUD)" = "azure" ]; then \
	  (cd $(TF_DIR_AZ) && $(TF_APPLY) -var-file=$(abspath $(TFVARS_AZ)) -var="burst=true"); \
	elif [ "$(CLOUD)" = "gcp" ]; then \
	  (cd $(TF_DIR_GCP) && $(TF_APPLY) -var-file=$(abspath $(TFVARS_GCP)) -var="burst=true"); \
	else \
	  echo "CLOUD_PROVIDER not set (azure|gcp)"; exit 2; \
	fi

burst.validate: ## Basic validation post-burst
	kubectl get nodes -o wide || true
	kubectl get pods -A || true

burst.scale.down: ## Scale burst resources down
	@if [ "$(CLOUD)" = "azure" ]; then \
	  (cd $(TF_DIR_AZ) && $(TF_APPLY) -var-file=$(abspath $(TFVARS_AZ)) -var="burst=false"); \
	elif [ "$(CLOUD)" = "gcp" ]; then \
	  (cd $(TF_DIR_GCP) && $(TF_APPLY) -var-file=$(abspath $(TFVARS_GCP)) -var="burst=false"); \
	else \
	  echo "CLOUD_PROVIDER not set (azure|gcp)"; exit 2; \
	fi

# ---------------------------- Showcase routers --------------------------------
showcase.%: ## Use: make showcase.<name>.<target>
	@echo "Usage: make showcase.<name>.<target> (targets: demo|destroy|evidence|advanced-networking, etc.)"
	@echo "Names:"; echo "$(SHOWCASES)" | tr ' ' '\n'

showcase.list: ## List showcase names line-by-line
	@echo "$(SHOWCASES)" | tr ' ' '\n'

showcase.avd-zerotouch-deployment.%:
	$(MAKE) -C showcases/avd-zerotouch-deployment $*

showcase.ci-cd-pipeline.%:
	$(MAKE) -C showcases/ci-cd-pipeline $*

showcase.dr-failover-to-cloud.%:
	$(MAKE) -C showcases/dr-failover-to-cloud $*

showcase.kubernetes-autoscaling.%:
	$(MAKE) -C showcases/kubernetes-autoscaling $*

showcase.linux-administration.%:
	$(MAKE) -C showcases/linux-administration $*

showcase.migrate-onprem-to-cloud.%:
	$(MAKE) -C showcases/migrate-onprem-to-cloud $*

showcase.network-automation.%:
	$(MAKE) -C showcases/network-automation $*

# Note: routing uses your folder name exactly as provided (includes 'failback').
showcase.dr-failback-to-onprem.%:
	$(MAKE) -C showcases/dr-failback-to-onprem $*

showcase.scale-workload-to-cloud.%:
	$(MAKE) -C showcases/scale-workload-to-cloud $*

showcase.windows-administration.%:
	$(MAKE) -C showcases/windows-administration $*
