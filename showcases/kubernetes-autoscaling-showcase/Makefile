# —— Kubernetes Autoscaling showcase (concise) ——
.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c
.SILENT:

TF_DIR := terraform
ANS_DIR := ansible
PIPE   := jenkins-pipeline

.PHONY: help tf-init tf-plan tf-apply tf-destroy ans-check ans-apply trig
help:
	@echo "Targets:"
	@echo "  tf-init/plan/apply/destroy  - terraform in $(TF_DIR)"
	@echo "  ans-check / ans-apply       - ansible in $(ANS_DIR)"
	@echo "  trig                        - trigger pipeline script (placeholder)"

tf-init:
	cd $(TF_DIR) && terraform init -input=false

tf-plan:
	cd $(TF_DIR) && terraform plan -no-color -input=false -out=tf.plan

tf-apply:
	cd $(TF_DIR) && terraform apply -no-color -auto-approve tf.plan || \
	cd $(TF_DIR) && terraform apply -no-color -auto-approve

tf-destroy:
	cd $(TF_DIR) && terraform destroy -no-color -auto-approve

ans-check:
	cd $(ANS_DIR) && ansible-playbook -i inventory.ini playbook.yml --check -v

ans-apply:
	cd $(ANS_DIR) && ansible-playbook -i inventory.ini playbook.yml -v

trig:
	bash $(PIPE)/trigger.sh
