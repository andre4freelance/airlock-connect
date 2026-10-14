# Architecture & Security Model

`airlock-connect` bridges the gap between secure encrypted credential storage (standard UNIX `pass` + GPG) and legacy network infrastructure (switches, routers, firewalls, and PDUs) that strictly mandate password authentication.

---

## 1. Zero-Leak Memory Pipeline

Traditional approaches store passwords in plain text files or pass them inline via process arguments (`-p <password>`), leaking secrets to `/proc` and `ps aux`.

`airlock-connect` eliminates disk and process table leaks:

```
[ ~/.password-store/*.gpg ]
    │
    │  1. In-Memory Decryption via pass show
    ▼
[ Decrypted Secret in RAM ]
    │
    ├─────────────────────────────────────────┐
    │ Protocol: SSH                           │ Protocol: Telnet
    ▼                                         ▼
[ Process Substitution 3<<< "$PASS" ]     [ expect dynamic spawn ]
    │                                         │
    │ 2. Dedicated FD 3                       │ 2. Automated Handshake
    ▼                                         ▼
[ sshpass -d 3 ssh ... ]                  [ send "$user\r" / "$pass\r" ]
    │                                         │
    │ 3. Stdin (FD 0) untouched               │ 3. interact handoff
    ▼                                         ▼
[ Fully Interactive Remote Shell ]        [ Fully Interactive Remote Shell ]
```

### Why File Descriptor 3 (`-d 3`)?
- Standard piping (`cat secret | sshpass ssh ...`) binds secret input to Standard Input (FD 0).
- When FD 0 is consumed by a pipe, OpenSSH cannot allocate an interactive controlling terminal (TTY), causing the session to terminate or freeze.
- By streaming the password through inherited **File Descriptor 3** (`-d 3`), FD 0 remains 100% attached to the user's terminal keyboard, guaranteeing seamless interactive access.

---

## 2. Two-Tier Protection Boundary

`airlock-connect` establishes two distinct access tiers:

| Tier | Interface | Security Policy | User Experience |
| :--- | :--- | :--- | :--- |
| **Inspection Tier** | `pass show`, `pass edit`, `pass grep`, `pass -c` | **Strict Sudo Gate** | Requires local machine `sudo` password. Cache is flushed immediately (`sudo -k`) to prevent lingering exposure. |
| **Execution Tier** | `airlock-connect <entry>` (or `connect`) | **Unattended RAM Stream** | Passes internal bypass token (`_PASS_INTERNAL_BYPASS=1`). Directly decrypts in RAM and establishes connection without interrupting automated scripts or AI assistants. |

---

## 3. Metadata Structure

Entries inside `pass` are structured with the password on the first line, followed by optional YAML-like metadata:

```text
SuperSecretDevicePassword123
user: admin
host: 192.0.2.1
proto: ssh
port: 22
```

- **Line 1**: The raw secret.
- **Lines 2+**: Key-value pairs (`user`, `host`, `proto`, `port`).
- **Parsing Safety**: The parser operates case-insensitively, handles whitespace variations, and guards against script termination under strict shell error traps (`set -eo pipefail`).
