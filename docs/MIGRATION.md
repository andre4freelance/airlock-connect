# Multi-device keypair and vault migration

Moving an encrypted inventory to a secondary machine involves transferring your GPG keypair and the `~/.password-store` directory.

## Keypair vs password store

- GPG private key (`.asc`): Export this once. It acts as the master key to decrypt all entries.
- Password store (`~/.password-store/`): Contains the encrypted `.gpg` files. Copy or sync this whenever you add or modify entries.

## Migration procedure

### 1. Export from source machine

```bash
mkdir -p ~/airlock-migration && cd ~/airlock-migration

# Export GPG keys and trust database
GPG_ID=$(cat ~/.password-store/.gpg-id | head -n 1)
gpg --armor --export-secret-keys "$GPG_ID" > gpg-secret-key.asc
gpg --armor --export "$GPG_ID" > gpg-public-key.asc
gpg --export-ownertrust > gpg-ownertrust.txt

# Archive password store
tar -czvf password-store.tar.gz -C ~ .password-store

# Bundle files for transfer
cd ~
tar -czvf airlock-migration-bundle.tar.gz -C ~/airlock-migration .
rm -rf ~/airlock-migration
```

Transfer `airlock-migration-bundle.tar.gz` to your target machine using SCP, rsync, or a secure USB drive.

### 2. Restore on target machine

```bash
# Install system packages
sudo apt update && sudo apt install -y pass expect sshpass gpg git

# Extract bundle
mkdir -p ~/airlock-restore
tar -xzvf airlock-migration-bundle.tar.gz -C ~/airlock-restore
cd ~/airlock-restore

# Import GPG keyring
gpg --import gpg-public-key.asc
gpg --import gpg-secret-key.asc
gpg --import-ownertrust gpg-ownertrust.txt

# Restore password store directory
tar -xzvf password-store.tar.gz -C ~

# Install airlock-connect
curl -fsSL https://raw.githubusercontent.com/andre4freelance/airlock-connect/main/install.sh | bash -s -- --with-gate

# Clean up temporary archive files
cd ~
rm -rf ~/airlock-restore airlock-migration-bundle.tar.gz
```

### 3. Verify

Confirm the setup functions on the target machine:

```bash
# List vault entries
pass ls

# Test sudo verification on plaintext display
pass show <your-entry>

# Test automated connection
connect <your-entry>
```
