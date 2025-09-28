# —— Terraform (concise) ——
.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c
.SILENT:

PLAN ?= tf.plan

.PHONY: help fmt init validate plan apply destroy
help: ## List targets
	@awk 'BEGIN{FS":.*##";print "Terraform:"} /^[a-zA-Z0-9_-]+:.*##/ {printf "  %-10s %s\n",$$1,$$2}' $(MAKEFILE_LIST)

fmt:        ## terraform fmt -check -recursive
	terraform fmt -check -recursive || (echo "Run: terraform fmt -recursive" && exit 1)

init:       ## terraform init
	terraform init -input=false

validate:   ## terraform validate
	terraform validate

plan:       ## terraform plan -> $(PLAN)
	terraform plan -no-color -input=false -out=$(PLAN)

apply:      ## terraform apply (uses plan if present)
	terraform apply -no-color -auto-approve $(PLAN) || terraform apply -no-color -auto-approve

destroy:    ## terraform destroy
	terraform destroy -no-color -auto-approve
