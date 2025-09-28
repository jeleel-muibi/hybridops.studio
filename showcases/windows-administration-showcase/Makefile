# —— Windows Administration showcase (concise) ——
.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c
.SILENT:

ANS := ansible-playbooks
TF  := terraform-configs
PS  := powershell-scripts

.PHONY: help ans-check ans-apply tf-plan tf-apply tf-destroy ps-demo
help:
	@echo "Targets:"
	@echo "  ans-check   - ansible dry-run (Windows hosts)"
	@echo "  ans-apply   - ansible apply (Windows hosts)"
	@echo "  tf-plan     - terraform plan (Windows infra)"
	@echo "  tf-apply    - terraform apply"
	@echo "  tf-destroy  - terraform destroy"
	@echo "  ps-demo     - run sample PowerShell script"

ans-check:
	cd $(ANS) && ansible-playbook -i inventory.ini windows.yml --check -v

ans-apply:
	cd $(ANS) && ansible-playbook -i inventory.ini windows.yml -v

tf-plan:
	cd $(TF) && terraform init -input=false && terraform plan -no-color -input=false -out=tf.plan

tf-apply:
	cd $(TF) && terraform apply -no-color -auto-approve tf.plan || \
	cd $(TF) && terraform apply -no-color -auto-approve

tf-destroy:
	cd $(TF) && terraform destroy -no-color -auto-approve

ps-demo:
	pwsh -File $(PS)/Example.ps1 || powershell.exe -File $(PS)/Example.ps1
