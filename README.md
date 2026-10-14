# airlock-connect

SSH and Telnet launcher for network hardware backed by standard UNIX pass and GPG.

## Background

Many switches, routers, and firewalls only support password authentication. Operators often work around this with plaintext files or `sshpass -p`, which exposes credentials in `/proc` and `ps`. Telnet presents a second issue: `sshpass` cannot handle remote login prompts (`Username:` and `Password:`), so Telnet sessions still require interactive entry or custom scripts.

`airlock-connect` addresses both cases:
- Credentials stay encrypted on disk via standard UNIX `pass` (GPG RSA-3072 or ECC).
- SSH passwords stream directly into memory through file descriptor 3 (`sshpass -d 3`), leaving standard input attached to your keyboard for normal interactive use.
- Telnet logins run through an embedded `expect` routine that negotiates login prompts automatically before returning the session to your terminal.
- An optional wrapper (`airlock-gate`) requires your sudo password before displaying credentials in plaintext via `pass show` or `pass edit`.
- Automated scripts and local CLI tools can launch sessions without interactive GPG passphrase prompts.
- Shell completions for Bash and Zsh are included, with optional `fzf` support for fuzzy selection when run without arguments.

## Architecture

```
                       [ ~/.password-store/*.gpg ]
                     (Encrypted RSA-3072 / AES-256)
                                   |
                                   v
                       [ pass show <entry> ]
                      (Decrypted in RAM stream)
                                   |
                                   v
                       [ airlock-connect (connect) ]
                                   |
            +----------------------+----------------------+
            |                                             |
    Protocol: SSH                                 Protocol: Telnet
            |                                             |
   [ sshpass -d 3 ]                              [ expect spawn telnet ]
   Streams pass via FD 3                         Handles Username and Password
   Leaves stdin (FD 0) intact                    Drops to interactive shell
            |                                             |
            v                                             v
   Remote SSH device                             Remote Telnet switch
```

For protocol details, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Installation

### Prerequisites

Install the required packages for your distribution:

```bash
# Ubuntu / Debian
sudo apt update && sudo apt install -y pass expect sshpass gpg git

# Fedora / RHEL
sudo dnf install -y pass expect sshpass gnupg2 git

# Arch Linux
sudo pacman -S pass expect sshpass gnupg git
```

Optional: install `fzf` for interactive terminal search when running `connect` without arguments:

```bash
sudo apt install -y fzf
```

### Install

Run the installer via curl:

```bash
# Install with strict sudo verification on plaintext viewing
curl -fsSL https://raw.githubusercontent.com/andre4freelance/airlock-connect/main/install.sh | bash -s -- --with-gate

# Or install standalone without the sudo wrapper
curl -fsSL https://raw.githubusercontent.com/andre4freelance/airlock-connect/main/install.sh | bash
```

The script installs:
1. `airlock-connect` and a `connect` alias to `~/.local/bin/`.
2. Shell completions for Zsh (`~/.zfunc/_airlock-connect`) and Bash (`~/.local/share/bash-completion/completions/`).
3. Optional `airlock-gate` as a wrapper for `pass`.

## Quickstart

### 1. Initialize password store

If you do not already use `pass`, generate an unattended GPG keypair and initialize your store:

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

### 2. Save a device

Use `pass insert -m` to store the password and connection metadata:

```bash
pass insert network/core-sw01 -m
```

Line 1 is always the password. Subsequent lines store metadata in `key: value` format:

```text
SuperSecretPass123!
user: admin
host: 192.168.1.1
proto: ssh
port: 22
```

Press `Enter` then `Ctrl+D` to save.

For Telnet:

```text
CiscoTelnetPass
user: cisco
host: 192.168.1.254
proto: telnet
```

### 3. Connect

Connect using `connect` or `airlock-connect`:

```bash
# Interactive shell
connect network/core-sw01

# Run a remote command
connect network/core-sw01 "/system/resource/print"

# Interactive search (fzf) or listing
connect
```

## Security model

`airlock-connect` uses two operational tiers:

1. Viewing plaintext credentials:
   Running `pass show network/core-sw01` triggers `airlock-gate`:
   ```text
   Enter sudo password to view/decrypt secret:
   ```
   Sudo cache is invalidated (`sudo -k`) before and after execution to prevent credentials from lingering in your session.

2. Automated session launch:
   Running `connect network/core-sw01` sets an internal token (`_PASS_INTERNAL_BYPASS=1`). The password decrypts into memory and streams directly to `sshpass` via file descriptor 3 without prompting for sudo.

## Multi-device migration

To move your keypair and password store to another machine, see [docs/MIGRATION.md](docs/MIGRATION.md).

## License

GPL-3.0. See [LICENSE](LICENSE) for details.
