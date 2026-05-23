# Add a New Machine — Workflow

## Overview

Adding a new machine has **four phases**:
1. **I handle** — run `tools/new_machine.sh` to create the canonical folder structure, vault, and context files.
2. **You handle** — configure initial SSH access with your personal user (must have sudo).
3. **I prepare + You execute** — I generate the SSH key and transfer the setup script; you run one `sudo` command on the target.
4. **I handle** — discover the LAN subnet, harden SSH, update `~/.ssh/config`, discover system info, and finalize the vault.

---

## Phase 1 — I create the structure

When you tell me *"add machine `<name>`"* I will:

1. Run `tools/new_machine.sh <name> --type bare-metal` to generate:
   - `machines/<name>/` folder (bare-metal machines live directly under `machines/`)
   - Context files: `CLAUDE.md`, `CONTEXT.md`, `REFERENCES.md`
   - Vault: `vault/` with `00_INDEX.md` through `05_SECURITY.md`
   - `TOOLS/.gitkeep`
2. Log the scaffolding in `03_TASK_LOG.md`.

Then **I stop and wait for you**. I will show you the exact steps for Phases 2–4.

---

## Phase 2 — You configure initial SSH (your personal user)

Generate an SSH key and copy it to the server using your personal user:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/<name>-personal -C "<your-user>@<name>"
ssh-copy-id -i ~/.ssh/<name>-personal.pub <your-user>@<host>
```

Add to `~/.ssh/config` temporarily (just for setup):

```
Host <name>
    HostName <host>
    User <your-user>
    IdentityFile ~/.ssh/<name>-personal
    IdentitiesOnly yes
```

Verify:

```bash
ssh <name> "echo ok"
```

When done, tell me *"SSH ready for `<name>`"*. I will give you the next steps.

---

## Phase 3 — I prepare, you run one command

**I do first (agent):**

```bash
# Generate the dedicated keypair (skips if key already exists)
bash tools/setup_tuneladora_control.sh --machine <name>

# Transfer the setup script to the target via your personal SSH alias
scp tools/setup_tuneladora_target.sh <name>:/tmp/
```

The control script prints the public key and the exact command to give you.

**You do (one command on the target, with sudo):**

```bash
sudo bash /tmp/setup_tuneladora_target.sh --pubkey 'ssh-ed25519 AAAA...'
```

This single command: creates the `tuneladora` user, configures passwordless sudo, sets up `~/.ssh/`, installs the public key, and locks the password. No `ssh-copy-id` needed — the key is already in `authorized_keys`.

When done, tell me *"tuneladora user ready"*. I will connect directly as `tuneladora` and begin Phase 4.

---

## Phase 4 — I finalize

Once `tuneladora user ready` is confirmed, I will connect directly as `tuneladora` (the key is already in `authorized_keys`) and:

> **Multi-agent note:** Steps 1–4 are sequential (each depends on the previous). Once step 4 (connection test) passes, steps 5–7 are independent and run as parallel Haiku sub-agents. See CLAUDE.md for orchestration details.

1. **Discover the LAN subnet and harden SSH** — run locally (subnet is discovered from the operator's current network interface):
   ```bash
   SUBNET=$(ip -4 addr show scope global | awk '/inet / {split($2,a,"."); print a[1]"."a[2]"."a[3]".*"}' | head -1)
   PUBKEY=$(cat ~/.ssh/tuneladora_<name>.pub)
   ssh <name> "echo 'from=\"$SUBNET\",no-agent-forwarding,no-X11-forwarding $PUBKEY' > ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
   ```
   > **Network change note:** if the operator later connects from a different LAN (e.g. office vs home), re-run this command from the new network to update the `from=` restriction. Otherwise SSH will be blocked.
2. **Update `~/.ssh/config`** to use `User tuneladora` and `IdentityFile ~/.ssh/tuneladora_<name>`.
3. **Test the connection**: `ssh <name> "whoami"` → should return `tuneladora`.

   *(If this passes, launch steps 4–6 as parallel Haiku sub-agents.)*

4. **[PARALLEL]** **Discover system info** and populate `01_SYSTEM_INFO.md`.
5. **[PARALLEL]** **Populate `CONTEXT.md`** with OS, purpose, network, and any quirks found during discovery.
6. **[PARALLEL]** **Update `05_SECURITY.md`** with SSH key fingerprints and access policies.
7. **[SEQUENTIAL — after 4–6]** **Configure automatic security updates** using the OS-appropriate tool (e.g. `unattended-upgrades` on Debian/Ubuntu, `dnf-automatic` on RHEL). Populate `07_UPDATES.md` with the configuration.
8. **[SEQUENTIAL — after 7]** **Verify or configure a backup job**. If no backup is in scope for this machine, document it explicitly in `06_BACKUPS.md` (as "no backup — intentional"). If a backup is needed, set it up and populate `06_BACKUPS.md`.
9. **[SEQUENTIAL — after 7–8]** **Log the full setup** in `03_TASK_LOG.md` and update the `## Status` block in `00_INDEX.md` (`backup status` and `auto-updates` fields).

---

## Lost SSH Key Recovery

If the control machine loses `~/.ssh/tuneladora_<name>` (disk wipe, migration, etc.) and the `tuneladora` user already exists on the target:

**1. Generate a new key on the control machine:**

```bash
bash tools/setup_tuneladora_control.sh --machine <name> --replace-key
```

`--replace-key` forces a fresh keypair even if the key file already exists, and includes the flag in the output command so the target script knows to overwrite `authorized_keys` instead of appending.

**2. Get the new key onto the target.**

You need a way in — use whichever applies:

| Scenario | How to access |
|----------|--------------|
| Bare-metal — admin has personal SSH | `scp` the script, run as usual |
| LXC — parent tuneladora still works | Agent runs via `pct exec` autonomously |
| Bare-metal — only tuneladora SSH existed | Physical/console access, or Proxmox web shell |

**3. Run on target (bare-metal):**

```bash
sudo bash /tmp/setup_tuneladora_target.sh --pubkey 'ssh-ed25519 AAAA...' --replace-key
```

**3. Run on target (LXC via parent):**

```bash
ssh <parent-name> "bash /tmp/setup_tuneladora_target.sh \
  --pubkey '$(cat ~/.ssh/tuneladora_<name>.pub)' \
  --replace-key --lxc --vmid <vmid>"
```

**4. Once access is restored, run Phase 4 hardening** — connect as tuneladora, re-apply the `from=` restriction, and update `~/.ssh/config`.

> Without `--replace-key`, the script appends the new key alongside the old orphaned one. Phase 4 hardening will overwrite `authorized_keys` with only the new key anyway, so both modes produce the same end state — `--replace-key` just keeps things clean immediately.

---

## Quick reference

| Step | Who | What |
|------|-----|------|
| Phase 1: Create folder + vault | Me | `tools/new_machine.sh <name>` |
| Phase 2: Initial SSH (personal user) | You | SSH key, config entry |
| Phase 3: Create `tuneladora` user + install key | Me (prepare) + You (one sudo command) | `setup_tuneladora_control.sh` + `setup_tuneladora_target.sh` |
| Phase 4: Harden + discover + populate + updates + backups | Me | SSH hardening, config update, system discovery, auto-updates, backup baseline |
