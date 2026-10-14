# Architecture and security model

`airlock-connect` connects standard UNIX `pass` and GPG with network devices that require password authentication instead of SSH public keys.

## In-memory execution pipeline

Storing passwords in plaintext files risks unauthorized access, while passing them via CLI arguments (`-p <password>`) exposes them to `/proc` and `ps`.

`airlock-connect` handles authentication entirely in memory:

```
[ ~/.password-store/*.gpg ]
    |
    |  1. Decrypt into memory via pass show
    v
[ Secret in memory ]
    |
    +-----------------------------------------+
    | Protocol: SSH                           | Protocol: Telnet
    v                                         v
[ Process substitution 3<<< "$PASS" ]     [ expect dynamic spawn ]
    |                                         |
    | 2. Dedicated FD 3                       | 2. Automated handshake
    v                                         v
[ sshpass -d 3 ssh ... ]                  [ send "$user\r" / "$pass\r" ]
    |                                         |
    | 3. Stdin (FD 0) untouched               | 3. interact handoff
    v                                         v
[ Interactive remote shell ]              [ Interactive remote shell ]
```

### File descriptor 3 (`-d 3`)

Piping standard output (`cat secret | sshpass ssh ...`) ties the secret to standard input (FD 0). When FD 0 is consumed by a pipe, OpenSSH cannot allocate an interactive controlling terminal (TTY), which freezes or terminates the session.

Passing the password through inherited file descriptor 3 (`-d 3`) leaves FD 0 connected to your terminal keyboard, allowing a normal interactive shell session.

## Two-tier access model

`airlock-connect` separates secret inspection from session execution:

| Operation | Command | Security rule | Behavior |
| :--- | :--- | :--- | :--- |
| Secret inspection | `pass show`, `pass edit`, `pass grep`, `pass -c` | Strict sudo gate | Requires local sudo password. Sudo cache is cleared immediately (`sudo -k`) after display. |
| Session launch | `airlock-connect <entry>` (or `connect`) | Internal bypass | Sets `_PASS_INTERNAL_BYPASS=1` to decrypt in memory and connect directly without human prompt. |

## Metadata format

Entries in `pass` store the raw password on the first line, followed by optional metadata in key-value format:

```text
SuperSecretDevicePassword123
user: admin
host: 192.0.2.1
proto: ssh
port: 22
```

- Line 1: Raw password.
- Lines 2+: Metadata fields (`user`, `host`, `proto`, `port`).
- Parser rules: Key lookups are case-insensitive and tolerate missing fields without triggering shell error traps.
