#!/usr/bin/env bash
# Installs all system dependencies in one operation
# Maintainer: HybridOps.Studio
# Last Modified: 2025-11-23

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${SCRIPT_DIR}/install-base.sh"
"${SCRIPT_DIR}/install-cloud-azure.sh"
"${SCRIPT_DIR}/install-cloud-gcp.sh"
