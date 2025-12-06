#!/usr/bin/env bash
# HybridOps.Studio - Python Environment Installer
# Maintainer: HybridOps.Studio
# Last Modified: 2025-01-23

set -euo pipefail

# Script is in control/tools/setup/, so go up 3 levels to reach repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "${REPO_ROOT}"

VENV_DIR=".venv"
REQUIREMENTS_FILE="control/requirements.txt"

if [ -f "${VENV_DIR}/.installed" ] && [ "${VENV_DIR}/.installed" -nt "${REQUIREMENTS_FILE}" ]; then
    echo "Python environment already up to date"
    exit 0
fi

echo "Setting up Python virtual environment..."
python3 -m venv "${VENV_DIR}"

echo "Upgrading pip..."
"${VENV_DIR}/bin/python3" -m pip install --upgrade pip

echo "Installing Python dependencies from ${REQUIREMENTS_FILE}..."
"${VENV_DIR}/bin/python3" -m pip install -r "${REQUIREMENTS_FILE}"

touch "${VENV_DIR}/.installed"
echo "Python environment ready at ${VENV_DIR}/"
echo "To activate: source ${VENV_DIR}/bin/activate"
