# Add a New Machine — Workflow

## Overview

Adding a new machine has **five phases**:
1. **I handle** — create the folder structure, vault, context files, and log the setup.
2. **You handle** — configure initial SSH access with your personal user (must have sudo).
3. **You handle** — create the `tuneladora` user on the server with sudo NOPASSWD.
4. **You handle** — install the dedicated `tuneladora` SSH key (one command, one password entry).
5. **I handle** — harden SSH, update config, discover system info, and finalize the vault.

---

## Phase 1 — I create the structure

When you tell me *"add machine `<name>`"* I will:

1. Create `machines/<name>/` folder.
2. Create context files: `CLAUDE.md`, `CONTEXT.md`, `REFERENCES.md`.
3. Create the vault directory `vault_<name>/` with the initial notes:
   - `00_INDEX.md`
   - `01_SYSTEM_INFO.md`
   - `02_SERVICES.md`
   - `03_TASK_LOG.md`
   - `04_NOTES.md`
4. Create `TOOLS/` with a `.gitkeep`.
5. Log the setup scaffolding in `03_TASK_LOG.md`.

Then **I stop and wait for you**. I will show you the exact steps for Phases 2–4.

---

## Phase 2 — You configure initial SSH (your personal user)

Generate an SSH key and copy it to the server using your personal user:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/<name> -C "<your-user>@<name>"
ssh-copy-id -i ~/.ssh/<name>.pub <your-user>@<host>
```

Add to `~/.ssh/config`:

```
Host <name>
    HostName <host>
    User <your-user>
    IdentityFile ~/.ssh/<name>
    IdentitiesOnly yes
```

Verify:

```bash
ssh <name> "echo ok"
```

When done, tell me *"SSH ready for `<name>`"*. I will give you the next steps.

---

## Phase 3 — You create the `tuneladora` user

I will tell you to run this on the server (via SSH or directly). It requires your sudo password:

```bash
ssh <name>
# Once inside the server:
sudo useradd -m -s /bin/bash tuneladora
sudo passwd tuneladora        # Set a temporary password (you won't need it after Phase 4)
sudo bash -c "echo 'tuneladora ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/tuneladora"
exit
```

When done, tell me *"tuneladora user created"*. I will proceed to Phase 4.

---

## Phase 4 — You install the dedicated SSH key

I will generate a dedicated keypair (`~/.ssh/tuneladora`) and tell you to run:

```bash
ssh-copy-id -i ~/.ssh/tuneladora.pub tuneladora@<host>
```

This asks for the temporary password you set in Phase 3. When done, tell me *"key installed"*.

---

## Phase 5 — I finalize

Once the `tuneladora` key is installed, I will:

1. **Harden SSH**: add `from="192.168.1.*"`, `no-agent-forwarding`, `no-X11-forwarding` to `authorized_keys`.
2. **Disable password login** for `tuneladora`: `sudo passwd -l tuneladora`.
3. **Update your `~/.ssh/config`** to use `User tuneladora` and `IdentityFile ~/.ssh/tuneladora`.
4. **Test the connection**: `ssh <name> "whoami"` → should return `tuneladora`.
5. **Discover system info** and populate `01_SYSTEM_INFO.md`.
6. **Update the vault** with admin user info and task log.

---

## Quick reference

| Step | Who | What |
|------|-----|------|
| Phase 1: Create folder + vault | Me | All scaffolding |
| Phase 2: Initial SSH (personal user) | You | SSH key, config entry |
| Phase 3: Create `tuneladora` user | You | `useradd`, `passwd`, sudoers (needs sudo password) |
| Phase 4: Install dedicated key | You | `ssh-copy-id` (needs temp password) |
| Phase 5: Harden + discover | Me | SSH hardening, config update, system discovery |
