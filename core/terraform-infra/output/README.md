# Terraform Output

## Overview
Contains generated output files from Terraform runs, including structured JSON for Ansible consumption.

## Structure
- `terraform_outputs.json`: Latest output from Terraform
- `.gitignore`: Prevents committing sensitive data

## Integration
Consumed by Ansible roles (e.g., ip_mapper) to generate dynamic inventories and configuration logic.

## Purpose
To bridge Terraform provisioning with Ansible orchestration and maintain clean separation of concerns.
