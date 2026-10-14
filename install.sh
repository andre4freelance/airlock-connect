#!/usr/bin/env bash
# ==============================================================================
# airlock-connect installer
# ==============================================================================

set -eo pipefail

INSTALL_DIR="${HOME}/.local/bin"
ZSH_COMP_DIR="${HOME}/.zfunc"
BASH_COMP_DIR="${HOME}/.local/share/bash-completion/completions"

echo "============================================="
echo " Installing airlock-connect                  "
echo "============================================="

# Ensure target directories exist
mkdir -p "$INSTALL_DIR"
mkdir -p "$ZSH_COMP_DIR"
mkdir -p "$BASH_COMP_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Install main binary
cp "${SCRIPT_DIR}/bin/airlock-connect" "${INSTALL_DIR}/airlock-connect"
chmod +x "${INSTALL_DIR}/airlock-connect"
ln -sf "${INSTALL_DIR}/airlock-connect" "${INSTALL_DIR}/connect"

echo "[✓] Installed: ${INSTALL_DIR}/airlock-connect (and symlink 'connect')"

# 2. Install shell completions
cp "${SCRIPT_DIR}/completions/_airlock-connect" "${ZSH_COMP_DIR}/_airlock-connect"
cp "${SCRIPT_DIR}/completions/airlock-connect.bash" "${BASH_COMP_DIR}/airlock-connect"

echo "[✓] Installed shell completions"

# 3. Optional: Install airlock-gate (strict sudo wrapper for pass)
ENABLE_GATE=false
if [[ "$1" == "--with-gate" ]]; then
    ENABLE_GATE=true
elif [ -t 0 ]; then
    echo
    read -rp "Do you want to enable 'airlock-gate' (strict sudo check for 'pass show')? [y/N]: " choice
    case "$choice" in
        [yY][eE][sS]|[yY])
            ENABLE_GATE=true
            ;;
        *)
            ENABLE_GATE=false
            ;;
    esac
fi

if [[ "$ENABLE_GATE" == true ]]; then
    cp "${SCRIPT_DIR}/bin/airlock-gate" "${INSTALL_DIR}/airlock-gate"
    chmod +x "${INSTALL_DIR}/airlock-gate"
    ln -sf "${INSTALL_DIR}/airlock-gate" "${INSTALL_DIR}/pass"
    echo "[✓] Enabled airlock-gate as '${INSTALL_DIR}/pass' (strict sudo verification active)"
fi

echo
echo "============================================="
echo " Installation Complete!                      "
echo "============================================="
echo "Ensure ${INSTALL_DIR} is in your PATH. If not already added:"
echo '  export PATH="$HOME/.local/bin:$PATH"'
echo
echo "For Zsh completion, ensure ~/.zfunc is loaded in ~/.zshrc:"
echo '  fpath=(~/.zfunc $fpath)'
echo '  autoload -Uz compinit && compinit'
echo
echo "Try running:"
echo "  airlock-connect --help"
echo "  connect --help"
