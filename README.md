# airlock-connect

<p align="center">
  <b>Zero-leak, unattended SSH & Telnet launcher for network infrastructure backed by standard UNIX <code>pass</code> and GPG.</b>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#quickstart">Quickstart</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#security-model">Security Model</a> •
  <a href="#license">License</a>
</p>

---

## The Problem

Managing switches, routers, firewalls, and legacy appliances often means dealing with devices that **do not support SSH public key authentication**.

Engineers traditionally resort to:
- Storing passwords in insecure plaintext files (`.txt`, `.env`).
- Using `sshpass -p <password>` which leaks secrets into the process table (`ps aux` / `/proc`).
- Struggling with **Telnet**, which `sshpass` cannot handle because Telnet relies on remote dynamic login prompts (`Username:` and `Password:`).
- Getting blocked by interactive GPG passphrase prompts during automated scripting or AI-assisted operations.

## The Solution: `airlock-connect`

`airlock-connect` combines the cryptographic power of standard UNIX [`pass`](https://www.passwordstore.org/) with an in-memory streaming pipeline:

- 🔒 **Encrypted At-Rest**: Passwords and device metadata are encrypted using RSA-3072 / AES-256 via GPG.
- ⚡ **Zero-Leak RAM Streaming**: Streams passwords to OpenSSH via dedicated **File Descriptor 3** (`-d 3`), leaving standard input (FD 0) untouched for fully interactive TTY sessions without disk caching.
- 📟 **Telnet Automation**: Dynamically negotiates remote Telnet authentication via `expect` before handing interactive control over to your terminal.
- 🛡️ **Strict Sudo Gate (`airlock-gate`)**: Viewing plaintext secrets (`pass show`, `pass edit`) strictly requires your machine's `sudo` password with instant cache invalidation.
- 🤖 **Automation & AI-Agent Ready**: Automated scripts and AI CLIs can establish connections seamlessly without hitting interactive passphrase walls.
- 🔍 **Interactive Fuzzy Search**: Autocompletes entry names via `Tab` (Zsh/Bash) or provides an interactive selector if [`fzf`](https://github.com/junegunn/fzf) is installed.

---

## Architecture

```
                       [ ~/.password-store/*.gpg ]
                     (Encrypted RSA-3072 / AES-256)
                                   │
                                   ▼
                       [ pass show <entry> ]
                      (Decrypted in RAM stream)
                                   │
                                   ▼
                       [ airlock-connect (connect) ]
                                   │
            ┌──────────────────────┴──────────────────────┐
            ▼                                             ▼
    Protocol: SSH                                 Protocol: Telnet
            │                                             │
   [ sshpass -d 3 ]                              [ expect spawn telnet ]
   Streams pass via FD 3                         Handles Username: & Password:
   Leaves stdin (FD 0) intact                    Drops to interact shell
            │                                             │
            ▼                                             ▼
   Remote SSH Device                             Remote Telnet Switch
```

For in-depth details, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## Installation

### Prerequisites

Install core dependencies on your Linux system:

```bash
# Ubuntu / Debian
sudo apt update && sudo apt install -y pass expect sshpass gpg git

# Fedora / RHEL
sudo dnf install -y pass expect sshpass gnupg2 git

# Arch Linux
sudo pacman -S pass expect sshpass gnupg git
```

*(Optional)* Install `fzf` for interactive terminal selection:
```bash
sudo apt install -y fzf
```

### Install `airlock-connect`

Clone and install using the included installer:

```bash
git clone https://github.com/andre4freelance/airlock-connect.git
cd airlock-connect
./install.sh --with-gate
```

The installer configures:
1. `airlock-connect` (and convenient alias `connect`) in `~/.local/bin/`.
2. Shell tab-completion for **Zsh** and **Bash**.
3. Optional `airlock-gate` protection as `pass` wrapper.

---

## Quickstart

### 1. Initialize your Password Store (If not already set up)

Generate an unattended machine GPG keypair and initialize `pass`:

```bash
gpg --batch --generate-key << 'EOF'
Key-Type: RSA
Key-Length: 3072
Key-Usage: sign
Subkey-Type: RSA
Subkey-Length: 3072
Subkey-Usage: encrypt
Name-Real: Admin
Name-Email: admin@local
Expire-Date: 0
%no-protection
%commit
EOF

pass init admin@local
```

### 2. Save a Network Device

Use `pass insert -m` to store the device password and connection metadata:

```bash
pass insert network/core-sw01 -m
```

Input format (**Line 1 is always the password**; subsequent lines are key-value pairs):

```text
SuperSecretPass123!
user: admin
host: 192.168.1.1
proto: ssh
port: 22
```
*Press `Enter` then `Ctrl+D` when finished.*

For a Telnet device:

```text
CiscoTelnetPass
user: cisco
host: 192.168.1.254
proto: telnet
```

### 3. Connect to the Device

Connect instantly using `connect` (or `airlock-connect`):

```bash
# Launch interactive shell
connect network/core-sw01

# Run remote command non-interactively
connect network/core-sw01 "/system/resource/print"

# Interactive menu (if fzf installed) or vault tree
connect
```

---

## Security Model

`airlock-connect` implements a dual-tier security boundary:

1. **Viewing Plaintext Secrets**:
   When you run `pass show network/core-sw01`, the `airlock-gate` wrapper triggers:
   ```text
   Enter sudo password to view/decrypt secret:
   ```
   Sudo cache is invalidated (`sudo -k`) both before and after execution, ensuring secrets cannot be exposed without active authentication.

2. **Automated Connection Execution**:
   When running `connect network/core-sw01`, the internal bypass token allows immediate decryption into memory, piping the password directly to `sshpass` via File Descriptor 3 without user prompts.

---

## Multi-Device Migration

To replicate your encrypted inventory and keys to a secondary laptop or workstation, follow the step-by-step guide in [docs/MIGRATION.md](docs/MIGRATION.md).

---

## License

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)** — see the [LICENSE](LICENSE) file for details.
