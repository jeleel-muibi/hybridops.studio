# CI/CD Pipeline Showcase

End-to-end CI/CD for infra/app delivery via **Jenkins** and **GitHub Actions**, integrating Terraform, Ansible, and Packer.

- **Author:** Jeleel Muibi
- **Last Updated:** 2025-09-18
- **SPDX-License-Identifier:** MIT

## Pipeline Design
- Triggers: PRs, merges, tags
- Stages: validate → lint/test → plan → review → apply
- Quality gates: tflint, ansible-lint, packer validate, SAST/secret scan

## Layout
```
jenkins/
  Jenkinsfile.ci-cd-demo
  shared-libraries/
github-actions/
  ci-cd-demo.yml
demo-app/
scripts/
```
