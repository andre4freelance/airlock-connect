#!/usr/bin/env bash
# ==============================================================================
# airlock-connect uninstaller
# ==============================================================================

set -eo pipefail

INSTALL_DIR="${HOME}/.local/bin"
ZSH_COMP_DIR="${HOME}/.zfunc"
BASH_COMP_DIR="${HOME}/.local/share/bash-completion/completions"

echo "Uninstalling airlock-connect..."

rm -f "${INSTALL_DIR}/airlock-connect"
rm -f "${INSTALL_DIR}/connect"
rm -f "${ZSH_COMP_DIR}/_airlock-connect"
rm -f "${BASH_COMP_DIR}/airlock-connect"

# Remove gate if it points to airlock-gate
if [[ -L "${INSTALL_DIR}/pass" ]]; then
    target=$(readlink "${INSTALL_DIR}/pass" || true)
    if [[ "$target" == *"airlock-gate"* ]]; then
        rm -f "${INSTALL_DIR}/pass"
    fi
fi
rm -f "${INSTALL_DIR}/airlock-gate"

echo "airlock-connect has been uninstalled."
