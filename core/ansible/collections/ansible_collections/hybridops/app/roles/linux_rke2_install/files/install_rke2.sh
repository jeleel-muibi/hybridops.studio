#!/usr/bin/env bash
set -euo pipefail
CHANNEL="${1:-stable}"
curl -sfL https://get.rke2.io | INSTALL_RKE2_CHANNEL="${CHANNEL}" sh -
