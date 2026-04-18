# Add a New Machine — Workflow

## Overview

Adding a new machine has **five phases**:
1. **I handle** — run `tools/new_machine.sh` to create the canonical folder structure, vault, and context files.
2. **You handle** — configure initial SSH access with your personal user (must have sudo).
3. **You handle** — create the `tuneladora` user on the server with sudo NOPASSWD.
4. **You handle** — install the dedicated `tuneladora` SSH key (one command, one password entry).
5. **I handle** — discover the LAN subnet, harden SSH, update `~/.ssh/config`, discover system info, and finalize the vault.

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

## Phase 3 — You create the `tuneladora` user

Run this on the server via SSH. It requires your sudo password:

```bash
ssh <name> "
sudo useradd -m -s /bin/bash tuneladora &&
sudo passwd tuneladora &&
sudo tee /etc/sudoers.d/tuneladora <<< 'tuneladora ALL=(ALL) NOPASSWD: ALL'
"
```

When done, tell me *"tuneladora user created"*. I will proceed to Phase 4.

---

## Phase 4 — You install the dedicated SSH key

I will generate a dedicated keypair (`~/.ssh/tuneladora_<name>`) and tell you to run:

```bash
ssh-copy-id -i ~/.ssh/tuneladora_<name>.pub tuneladora@<host>
```

This asks for the temporary password you set in Phase 3. When done, tell me *"key installed"*.

---

## Phase 5 — I finalize

Once the `tuneladora` key is installed, I will:

> **Multi-agent note:** Steps 1–5 are sequential (each depends on the previous). Once step 5 (connection test) passes, steps 6–8 are independent and run as parallel Haiku sub-agents. See SPEC.md §12.

1. **Discover the LAN subnet and harden SSH** — run these locally (the subnet is discovered from the operator's current network interface):
   ```bash
   SUBNET=$(ip -4 addr show scope global | awk '/inet / {split($2,a,"."); print a[1]"."a[2]"."a[3]".*"}' | head -1)
   PUBKEY=$(cat ~/.ssh/tuneladora_<name>.pub)
   ssh <name> "echo 'from=\"$SUBNET\",no-agent-forwarding,no-X11-forwarding $PUBKEY' > ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
   ```
   > **Network change note:** if the operator later connects from a different LAN (e.g. office vs home), re-run this command from the new network to update the `from=` restriction. Otherwise SSH will be blocked.
2. **Disable password login** for `tuneladora`: `ssh <name> "sudo passwd -l tuneladora"`.
4. **Update `~/.ssh/config`** to use `User tuneladora` and `IdentityFile ~/.ssh/tuneladora_<name>`.
5. **Test the connection**: `ssh <name> "whoami"` → should return `tuneladora`.

   *(If this passes, launch steps 6–8 as parallel Haiku sub-agents.)*

6. **[PARALLEL]** **Discover system info** and populate `01_SYSTEM_INFO.md`.
7. **[PARALLEL]** **Populate `CONTEXT.md`** with OS, purpose, network, and any quirks found during discovery.
8. **[PARALLEL]** **Update `05_SECURITY.md`** with SSH key fingerprints and access policies.
9. **[SEQUENTIAL — after 6–8]** **Log the full setup** in `03_TASK_LOG.md`.

---

## Quick reference

| Step | Who | What |
|------|-----|------|
| Phase 1: Create folder + vault | Me | `tools/new_machine.sh <name>` |
| Phase 2: Initial SSH (personal user) | You | SSH key, config entry |
| Phase 3: Create `tuneladora` user | You | `useradd`, `passwd`, sudoers |
| Phase 4: Install dedicated key | You | `ssh-copy-id` (needs temp password) |
| Phase 5: Harden + discover + populate | Me | SSH hardening, config update, system discovery, fill CONTEXT.md |
