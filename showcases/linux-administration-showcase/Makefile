# —— Linux Administration showcase (concise) ——
.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c
.SILENT:

ANS := ansible-playbooks
MON := monitoring-setup
BASH := bash-scripts

.PHONY: help ans-check ans-apply monitor bash-demo
help:
	@echo "Targets:"
	@echo "  ans-check  - ansible dry-run in $(ANS)"
	@echo "  ans-apply  - ansible apply in $(ANS)"
	@echo "  monitor    - run monitoring setup script(s)"
	@echo "  bash-demo  - run example bash script"

ans-check:
	cd $(ANS) && ansible-playbook -i inventory.ini site.yml --check -v

ans-apply:
	cd $(ANS) && ansible-playbook -i inventory.ini site.yml -v

monitor:
	cd $(MON) && bash setup.sh

bash-demo:
	cd $(BASH) && bash example.sh
