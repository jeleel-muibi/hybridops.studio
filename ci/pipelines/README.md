# CI Pipelines (folder-per-pipeline)

This directory holds one folder per Jenkins pipeline, each with a `Jenkinsfile` as the single entrypoint.
Jobs are created by Jenkins Configuration as Code (JCasC) + Job DSL.

Pipelines included:
- `ci/akv-smoke` — AKV connectivity and secret fetch smoke test
- `ci/packer-build` — build an immutable base image with Packer
- `ci/terraform-plan-apply` — Terraform init/plan (+ optional apply)
- `ci/ansible-apply` — run idempotent Ansible playbooks
