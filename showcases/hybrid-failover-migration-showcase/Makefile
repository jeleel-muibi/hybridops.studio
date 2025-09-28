# —— Hybrid Failover/Migration (concise) ——
.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c
.SILENT:

# Terraform scenarios under terraform-scenarios/<SCENARIO>
SCENARIO ?= failover-azure
TF_DIR   := terraform-scenarios/$(SCENARIO)
TF       := cd $(TF_DIR) &&
PLAN     ?= tf.plan

PKR_DIR  := packer-images
DEC_DIR  := decision-service

.PHONY: help plan apply destroy fmt pkr-validate pkr-build dec-run
help:
	@echo "Targets:"
	@echo "  fmt                - terraform fmt -check -recursive"
	@echo "  plan               - terraform plan in scenario ($(SCENARIO))"
	@echo "  apply              - terraform apply"
	@echo "  destroy            - terraform destroy"
	@echo "  pkr-validate       - packer init/validate (in $(PKR_DIR))"
	@echo "  pkr-build          - packer build (edit vars before running)"
	@echo "  dec-run            - run decision-service (edit as needed)"
	@echo "Vars: SCENARIO=$(SCENARIO)"

fmt:
	terraform fmt -check -recursive || (echo "Run 'terraform fmt -recursive' to fix." && exit 1)

plan:
	$(TF) terraform init -input=false
	$(TF) terraform plan -no-color -input=false -out=$(PLAN)

apply:
	$(TF) terraform apply -no-color -auto-approve $(PLAN) || \
	$(TF) terraform apply -no-color -auto-approve

destroy:
	$(TF) terraform destroy -no-color -auto-approve

pkr-validate:
	cd $(PKR_DIR) && packer init . && packer validate .

pkr-build:
	cd $(PKR_DIR) && packer build .

dec-run:
	python3 $(DEC_DIR)/src/main.py
