# Tuneladora

SSH connection hub operated by an LLM assistant to manage multiple remote servers. The LLM connects via SSH, executes tasks, and maintains persistent memory of each machine through Obsidian-compatible vaults.

See [SPEC.md](SPEC.md) for the full specification.

## SSH Setup

### Overview

Tuneladora operates through a dedicated `tuneladora` user on each server — not your personal user. This keeps a clean audit trail and separates your daily work from server administration.

The setup has **two phases**:
1. **You** — one-time manual setup (creates the `tuneladora` user with sudo access).
2. **Tuneladora** — automated migration and initialization.

---

### Phase 1 — Manual Setup (you do this once)

**1. Set up SSH access for your personal user**

```bash
ssh-keygen -t ed25519 -f ~/.ssh/<machine-name> -C "<user>@<machine-name>"
ssh-copy-id -i ~/.ssh/<machine-name>.pub <user>@<host>
```

Add to `~/.ssh/config` (temporary, just for the setup):

```
Host <machine-name>
    HostName <host>
    User <user>
    IdentityFile ~/.ssh/<machine-name>
    IdentitiesOnly yes
```

Verify:

```bash
ssh <machine-name> "echo ok"
```

**2. Create the `tuneladora` user**

Run this on the server (via SSH or directly). It will ask for a password — pick a temporary one:

```bash
ssh <machine-name> "
sudo useradd -m -s /bin/bash tuneladora &&
sudo passwd tuneladora &&
sudo tee /etc/sudoers.d/tuneladora <<< 'tuneladora ALL=(ALL) NOPASSWD: ALL'
"
```

Then install an SSH key so Tuneladora can connect. You can either:
- Let Tuneladora generate and install the key (recommended — see Phase 2), or
- Do it manually:
  ```bash
  ssh-keygen -t ed25519 -f ~/.ssh/tuneladora -C "tuneladora@<machine-name>"
  ssh <machine-name> "
    sudo -u tuneladora mkdir -p /home/tuneladora/.ssh &&
    sudo -u tuneladora chmod 700 /home/tuneladora/.ssh &&
    sudo tee /home/tuneladora/.ssh/authorized_keys <<< \"$(cat ~/.ssh/tuneladora.pub)\" &&
    sudo -u tuneladora chmod 600 /home/tuneladora/.ssh/authorized_keys &&
    sudo -u tuneladora chown tuneladora:tuneladora /home/tuneladora/.ssh/authorized_keys
  "
  ```

---

### Phase 2 — Tell Tuneladora to take over

Once the `tuneladora` user exists and has an SSH key installed, say:

> **"Initialize hef-pam"** (or any machine name)

Tuneladora will:

1. Create the machine folder, vault, and context files.
2. Test the SSH connection as the `tuneladora` user.
3. Harden the SSH setup (source restrictions, disable password login).
4. Update your `~/.ssh/config` to use the `tuneladora` user by default.
5. Discover system info and populate the vault.
6. Log the setup in the task log.

## Project Structure

```
machines/
├── <host>/                        # bare-metal host (root node)
│   ├── CLAUDE.md                  # Machine-specific AI rules
│   ├── CONTEXT.md                 # OS, purpose, known quirks
│   ├── REFERENCES.md              # Docs, runbooks, vendor links
│   ├── .env_<host>                # Non-SSH env variables
│   ├── vault/                     # Obsidian vault — persistent memory
│   │   ├── 00_INDEX.md
│   │   ├── 01_SYSTEM_INFO.md
│   │   ├── 02_SERVICES.md
│   │   ├── 03_TASK_LOG.md
│   │   ├── 04_NOTES.md
│   │   ├── 05_SECURITY.md
│   │   └── 06_CONTAINERS.md       # Inventory of VMs and containers
│   ├── TOOLS/                     # Machine-specific scripts
│   ├── VMs/                       # Virtual machines
│   │   └── <vm-name>/
│   │       ├── CLAUDE.md
│   │       ├── CONTEXT.md
│   │       ├── vault/
│   │       │   └── ...
│   │       └── TOOLS/
│   └── CTs/                       # Containers
│       ├── LXC/                   # Proxmox LXC containers
│       │   └── <lxc-name>/
│       │       └── ...
│       └── Docker/                # Docker containers
│           └── <docker-name>/
│               └── ...
```

## License

[MIT](LICENSE)
