# —— CI/CD Pipeline showcase (concise) ——
.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c
.SILENT:

.PHONY: help lint-gha lint-jenkins demo
help:
	@echo "Targets:"
	@echo "  lint-gha     - quick YAML lint for GitHub Actions"
	@echo "  lint-jenkins - quick linter for Jenkinsfiles (if you add one)"
	@echo "  demo         - run demo script (scripts/demo.sh)"

lint-gha:
	find github-actions -type f \( -name "*.yml" -o -name "*.yaml" \) -print0 | xargs -0 -I{} sh -c "echo '→ {}'; yamllint {} || true"

lint-jenkins:
	@echo "Add Jenkinsfile lint if needed (e.g., Jenkins linter API). Skipping for now."

demo:
	bash scripts/demo.sh
