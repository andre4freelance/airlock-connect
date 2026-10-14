#!/usr/bin/env bash
# ==============================================================================
# airlock-connect installer
# Supports both:
#   1. Standalone one-liner:
#      curl -fsSL https://raw.githubusercontent.com/andre4freelance/airlock-connect/main/install.sh | bash
#   2. Local execution:
#      ./install.sh
# ==============================================================================

set -eo pipefail

REPO_RAW_URL="https://raw.githubusercontent.com/andre4freelance/airlock-connect/main"

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

# Determine source location: local checkout or remote download
TMP_DIR=""
cleanup() {
    if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
        rm -rf "$TMP_DIR"
    fi
}
trap cleanup EXIT

SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]}" && -f "${BASH_SOURCE[0]}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [[ -n "$SCRIPT_DIR" && -f "${SCRIPT_DIR}/bin/airlock-connect" ]]; then
    SOURCE_DIR="$SCRIPT_DIR"
else
    echo "[*] Downloading components from GitHub..."
    TMP_DIR=$(mktemp -d)
    mkdir -p "${TMP_DIR}/bin" "${TMP_DIR}/completions"

    curl -fsSL "${REPO_RAW_URL}/bin/airlock-connect" -o "${TMP_DIR}/bin/airlock-connect"
    curl -fsSL "${REPO_RAW_URL}/bin/airlock-gate" -o "${TMP_DIR}/bin/airlock-gate"
    curl -fsSL "${REPO_RAW_URL}/completions/_airlock-connect" -o "${TMP_DIR}/completions/_airlock-connect"
    curl -fsSL "${REPO_RAW_URL}/completions/airlock-connect.bash" -o "${TMP_DIR}/completions/airlock-connect.bash"

    SOURCE_DIR="$TMP_DIR"
fi

# 1. Install main binary
cp "${SOURCE_DIR}/bin/airlock-connect" "${INSTALL_DIR}/airlock-connect"
chmod +x "${INSTALL_DIR}/airlock-connect"
ln -sf "${INSTALL_DIR}/airlock-connect" "${INSTALL_DIR}/connect"

echo "[✓] Installed: ${INSTALL_DIR}/airlock-connect"
echo "[✓] Created alias: ${INSTALL_DIR}/connect"

# 2. Install shell completions
cp "${SOURCE_DIR}/completions/_airlock-connect" "${ZSH_COMP_DIR}/_airlock-connect"
cp "${SOURCE_DIR}/completions/airlock-connect.bash" "${BASH_COMP_DIR}/airlock-connect"

echo "[✓] Installed shell completions (Zsh & Bash)"

# 3. Optional: Install airlock-gate (strict sudo wrapper for pass)
ENABLE_GATE=false
for arg in "$@"; do
    if [[ "$arg" == "--with-gate" ]]; then
        ENABLE_GATE=true
        break
    fi
done

if [[ "$ENABLE_GATE" == false ]]; then
    # Prompt user if running with interactive TTY available (even through curl | bash)
    if [ -r /dev/tty ] && [ -w /dev/tty ]; then
        echo
        read -rp "Do you want to enable 'airlock-gate' (strict sudo check for 'pass show')? [y/N]: " choice </dev/tty >/dev/tty 2>&1 || true
        case "$choice" in
            [yY][eE][sS]|[yY])
                ENABLE_GATE=true
                ;;
            *)
                ENABLE_GATE=false
                ;;
        esac
    fi
fi

if [[ "$ENABLE_GATE" == true ]]; then
    cp "${SOURCE_DIR}/bin/airlock-gate" "${INSTALL_DIR}/airlock-gate"
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
