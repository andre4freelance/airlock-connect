# Multi-Device Keypair & Vault Migration

Because `airlock-connect` relies on standard UNIX `pass` backed by GPG, moving your encrypted inventory to a new laptop or workstation is completely portable.

---

## The Static Key vs Dynamic Vault Concept

- **GPG Private Key (`.asc`)**: **Static**. You only need to export this **once**. It acts as the master key and will decrypt all current and future devices.
- **Password Store (`~/.password-store/`)**: **Dynamic**. Contains your `.gpg` encrypted files. Sync or copy this whenever new devices are added.

---

## Migration Steps

### Phase 1: On Your Source Workstation (Export)

```bash
mkdir -p ~/airlock-migration && cd ~/airlock-migration

# 1. Export GPG secret key, public key, and ownertrust
GPG_ID=$(cat ~/.password-store/.gpg-id | head -n 1)
gpg --armor --export-secret-keys "$GPG_ID" > gpg-secret-key.asc
gpg --armor --export "$GPG_ID" > gpg-public-key.asc
gpg --export-ownertrust > gpg-ownertrust.txt

# 2. Archive the encrypted password store
tar -czvf password-store.tar.gz -C ~ .password-store

# 3. Create a single migration bundle
cd ~
tar -czvf airlock-migration-bundle.tar.gz -C ~/airlock-migration .
rm -rf ~/airlock-migration
```

Transfer `airlock-migration-bundle.tar.gz` securely to your destination machine (via SCP, encrypted drive, or direct local network transfer).

---

### Phase 2: On Your Target Workstation (Restore)

```bash
# 1. Install prerequisites
sudo apt update && sudo apt install -y pass expect sshpass gpg git

# 2. Extract migration bundle
mkdir -p ~/airlock-restore
tar -xzvf airlock-migration-bundle.tar.gz -C ~/airlock-restore
cd ~/airlock-restore

# 3. Import GPG keyring
gpg --import gpg-public-key.asc
gpg --import gpg-secret-key.asc
gpg --import-ownertrust gpg-ownertrust.txt

# 4. Restore the password store directory
tar -xzvf password-store.tar.gz -C ~

# 5. Install airlock-connect
git clone https://github.com/andre4freelance/airlock-connect.git ~/airlock-connect-src
cd ~/airlock-connect-src
./install.sh --with-gate

# 6. Cleanup sensitive restore files
cd ~
rm -rf ~/airlock-restore airlock-migration-bundle.tar.gz ~/airlock-connect-src
```

---

## Verification

Test the restored configuration:

```bash
# 1. Verify entries are visible
pass ls

# 2. Test strict sudo verification on plaintext view
pass show <your-entry>

# 3. Test automated connection
connect <your-entry>
```
