#!/usr/bin/env bash
set -euo pipefail

# Source the library, then initialize env
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../tools/bash/lib" && pwd -P)/common.sh"
hybridops_env

# Now $REPO_ROOT and $ANSIBLE_CONFIG
echo "Repo root is: $REPO_ROOT"
ansible-playbook -i "$REPO_ROOT/deployment/inventories/bootstrap/hosts.ini" \
  "$REPO_ROOT/deployment/linux/playbooks/baseline.yml"
