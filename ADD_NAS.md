# Add a NAS / Appliance — Workflow

## Overview

NAS devices and other appliances run proprietary operating systems (UGOS, Synology DSM, TrueNAS, etc.) that impose restrictions not present in standard Linux. This document adapts the `ADD_MACHINE.md` workflow for these systems.

**Use this document instead of `ADD_MACHINE.md`** when the target machine is:
- A NAS (UGREEN, Synology, QNAP, TrueNAS, etc.)
- A router or managed switch with SSH
- Any appliance where the OS is proprietary or locked

---

## Key differences from standard Linux

| Aspect | Standard Linux | NAS / Appliance |
|--------|---------------|-----------------|
| Shell access | Any user with shell | May require specific group membership (e.g. `admin`) |
| rsync / SFTP / SCP | Works with any path | May be wrapped — restricted to registered shares |
| Package manager | apt / yum | Usually unavailable or restricted |
| Kernel updates | Via apt | Tied to OS firmware updates |
| sudoers | Direct edit | May be managed by appliance OS |
| File transfer destination | Any writable path | Must be a share registered in the appliance UI |

---

## Phases

### Phase 1 — I scaffold the structure

Same as `ADD_MACHINE.md` Phase 1: `tools/new_machine.sh <name> --type bare-metal`.

### Phase 2 — You verify SSH access

Connect with your personal user (admin account on the appliance):

```bash
ssh <admin-user>@<ip>
```

Most NAS systems use password auth by default. Confirm you can connect.

### Phase 3 — Create the `tuneladora` user

This varies by appliance. For UGOS (UGREEN NAS):

1. Open the UGOS admin panel (`http://<ip>`)
2. Go to **Control Panel → Users**
3. Create user `tuneladora` with a temporary password
4. Add `tuneladora` to the **`admin` group** (required for SSH interactive shell in UGOS)
5. Alternatively, via SSH as admin:
   ```bash
   sudo useradd -m -s /bin/bash tuneladora
   sudo passwd tuneladora
   sudo usermod -aG admin tuneladora
   sudo bash -c "echo 'tuneladora ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/tuneladora"
   sudo chmod 440 /etc/sudoers.d/tuneladora
   ```

For other appliances: check vendor documentation for creating a sudoer user with SSH access.

### Phase 4 — Install the dedicated SSH key

Same as `ADD_MACHINE.md` Phase 4:

```bash
ssh-copy-id -i ~/.ssh/tuneladora_<name>.pub tuneladora@<ip>
```

### Phase 5 — Harden and verify

```bash
# Discover subnet and harden authorized_keys
SUBNET=$(ip -4 addr show scope global | awk '/inet / {split($2,a,"."); print a[1]"."a[2]"."a[3]".*"}' | head -1)
PUBKEY=$(cat ~/.ssh/tuneladora_<name>.pub)
ssh tuneladora@<ip> "echo 'from=\"$SUBNET\",no-agent-forwarding,no-X11-forwarding $PUBKEY' > ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

# Test
ssh <name> "echo ok && whoami"
```

### Phase 6 — Discover system info and populate context

Same as `ADD_MACHINE.md` Phase 5 (steps 6–9): discover OS, hardware, network, populate vault.

> **Multi-agent note:** Once SSH connection is confirmed (step 5), launch discovery (01_SYSTEM_INFO.md), CONTEXT.md population, and 05_SECURITY.md update as parallel Haiku sub-agents. Log the full setup (03_TASK_LOG.md) after all three complete. See SPEC.md §12.

---

## UGOS-specific: File transfer restrictions

UGOS replaces rsync, SFTP, and SCP with proprietary wrappers (`ug_start_server`) that **only allow access to shares registered in the admin panel**. Raw paths like `/volume1/mydir` are rejected unless `mydir` is a registered share.

**Before setting up any backup or file transfer job targeting the NAS:**

1. Open the UGOS admin panel
2. Go to **Shared Folders** (or equivalent)
3. Create a new shared folder (e.g. `backups`)
4. Grant `tuneladora` read/write permissions on that share
5. The share will then be accessible at:
   - SFTP path: `/backups/`
   - rsync path: `/backups/` (via UGOS rsync module)

Document the share name and real filesystem path in `CONTEXT.md` and `vault/06_BACKUPS.md`.

### Verifying SFTP access after share creation

```bash
sftp -i ~/.ssh/tuneladora_<name> tuneladora@<ip>
# Inside sftp:
ls /          # should list registered shares
mkdir /backups/test
ls /backups/
rmdir /backups/test
```

### Which protocols are available via UGOS ForceCommand

| Protocol | Available | Notes |
|----------|-----------|-------|
| Interactive shell | Yes | Only if user is in `admin` group |
| SFTP | Yes | Only to registered shares |
| rsync | Yes | Only to registered shares (via UGOS module) |
| SCP | Yes | Only to registered shares |
| Arbitrary commands | Yes | Only if user is in `admin` group |

---

## Documenting the machine

Beyond the standard vault, always populate for NAS machines:

- `CONTEXT.md` → Known Quirks: document any ForceCommand, group requirements, share restrictions
- `vault/04_NOTES.md` → document every appliance-specific behavior discovered
- `vault/06_BACKUPS.md` → document backup destination role (which services back up here, share names, real paths)
- `CLAUDE.md` → Machine-Specific Rules: note that shares must be created in the admin UI before file transfer

---

## Tested appliances

| Appliance | OS | Notes |
|-----------|----|-------|
| UGREEN DXP4800 | UGOS 1.14.1 | Requires `admin` group for SSH; ForceCommand restricts all file ops to registered shares. See `machines/hef-nas-4800/` for reference. |
