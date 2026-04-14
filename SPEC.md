# Tuneladora — Specification

## 1. Project Summary

**Tuneladora** is an SSH connection hub designed to be operated by an LLM with terminal access (such as Claude CLI or Qwen), orchestrated by a human user. It enables autonomous server management — maintenance, deployments, configuration, troubleshooting — across multiple remote machines via SSH, while maintaining a structured, persistent memory of each machine's history, configuration, and completed tasks.

The core problem it solves: managing many servers through an LLM assistant requires the LLM to remember machine-specific context across sessions, handle credentials safely, and leave an auditable trail of every action taken. Tuneladora provides the file-based scaffolding that makes this possible without any custom runtime or database.

---

## 2. Goals & Non-goals

### Goals

- Provide a convention-over-configuration structure that any LLM with terminal access can navigate.
- Enable secure SSH credential handling where the LLM never reads secret values directly.
- Maintain per-machine persistent memory via Obsidian-compatible vaults.
- Support a single-human-operator workflow: one user gives high-level instructions, the LLM executes.
- Keep the system entirely file-based — no daemons, no databases, no custom runtimes.
- Make it trivial to add new machines, tools, or vault templates.

### Non-goals

- **Multi-user access control.** Tuneladora assumes a single operator.
- **Real-time monitoring or alerting.** It is task-driven, not event-driven.
- **GUI or web interface.** All interaction happens through the terminal and files.
- **Secrets management system.** `.env` files are the boundary; integration with Vault/AWS Secrets Manager/etc. is out of scope.
- **Automated scheduling.** The LLM acts on demand, not on a cron.

---

## 3. Architecture Overview

### Root bare-metal machines

```
tuneladora/
├── CLAUDE.md              # Global AI identity and rules (single source of truth)
├── QWEN.md                # Stub — redirects to CLAUDE.md
├── CONTEXT.md             # Global project context
├── REFERENCES.md          # Global references and resources
├── SPEC.md                # This file
├── tools/
│   └── new_machine.sh     # Scaffolding script — generates a machine folder from templates
└── machines/
    └── <host-name>/       # bare-metal (root node)
        ├── CLAUDE.md                  # Machine-specific AI instructions
        ├── CONTEXT.md                 # Machine-specific context (OS, purpose, history)
        ├── REFERENCES.md              # Machine-specific resources and notes
        ├── .env_<host-name>           # Machine-specific environment variables (non-SSH)
        ├── vault/                     # Obsidian vault for persistent memory
        │   ├── 00_INDEX.md            # Vault table of contents
        │   ├── 01_SYSTEM_INFO.md      # OS, hardware, network details
        │   ├── 02_SERVICES.md         # Running services and their configs
        │   ├── 03_TASK_LOG.md         # Chronological log of all tasks performed
        │   ├── 04_NOTES.md            # Free-form notes and observations
        │   ├── 05_SECURITY.md         # SSH keys, access policies, user accounts
        │   └── 06_CONTAINERS.md       # Inventory of VMs and containers hosted here
        ├── TOOLS/                     # Machine-specific scripts and utilities
        │   └── .gitkeep
        ├── VMs/                       # Virtual machines hosted on this node
        │   └── <vm-name>/
        │       ├── CLAUDE.md
        │       ├── CONTEXT.md
        │       ├── REFERENCES.md
        │       ├── vault/
        │       │   ├── 00_INDEX.md
        │       │   ├── 01_SYSTEM_INFO.md
        │       │   ├── 02_SERVICES.md
        │       │   ├── 03_TASK_LOG.md
        │       │   ├── 04_NOTES.md
        │       │   └── 05_SECURITY.md
        │       └── TOOLS/
        │           └── .gitkeep
        └── CTs/                       # Containers hosted on this node
            ├── LXC/                   # Proxmox LXC containers
            │   └── <lxc-name>/
            │       └── ... (same structure)
            └── Docker/                # Docker containers
                └── <docker-name>/
                    └── ... (same structure)
```

> **Single source of truth:** `CLAUDE.md` contains all behavioral rules. `QWEN.md` is a redirect stub. Never duplicate rule content between them.

> **Folder convention:** bare-metal machines live directly under `machines/`. Children are classified by type: VMs under `VMs/`, containers under `CTs/LXC/` or `CTs/Docker/`.

### How the pieces connect

1. **Root-level files** (`CLAUDE.md`, `CONTEXT.md`, `REFERENCES.md`) define the global identity and context the LLM operates under.
2. **Per-machine folders** are nested hierarchically: a VM lives under its host's `VMs/` folder, an LXC container under its host's `CTs/LXC/` folder, and a Docker container under its host's `CTs/Docker/` folder. The LLM resolves the path by reading `REGISTRY.md` or the parent's `HIERARCHY.md`.
3. **SSH connections** are configured via `~/.ssh/config`. The LLM connects using `ssh <machine-name>` — no credential variables needed.
4. **Obsidian vaults** (`vault/`) serve as the machine's long-term memory. Each machine has its own `vault/` folder inside its directory. The LLM reads it before acting and writes to it after completing a task.
5. **TOOLS/** holds executable scripts specific to a machine (backup scripts, deploy helpers, health checks, etc.).

---

## 4. Folder & File Reference

### Root level

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Defines the LLM's identity, tone, and global behavioral rules. Single source of truth. |
| `QWEN.md` | Redirect stub — points to `CLAUDE.md`. |
| `CONTEXT.md` | Describes what the project is, what success looks like, and what to avoid. |
| `REFERENCES.md` | Links, examples, and supplementary notes for the LLM. |
| `SPEC.md` | This specification document. |
| `tools/new_machine.sh` | Script that generates a machine folder from canonical templates. |
| `machines/` | Parent directory for all machine-specific folders. |

### Per-machine level (folder path depends on type)

| Type | Path |
|------|------|
| bare-metal | `machines/<name>/` |
| vm | `machines/<host>/VMs/<name>/` |
| lxc | `machines/<host>/CTs/LXC/<name>/` |
| docker | `machines/<host>/CTs/Docker/<name>/` |

| File / Folder | Purpose |
|---------------|---------|
| `CLAUDE.md` | Machine-specific AI instructions. Extends the root `CLAUDE.md` with rules scoped to this machine (e.g., "always use `apt` not `yum`"). Must be populated with real rules, not placeholders. |
| `CONTEXT.md` | Machine-specific context: OS, purpose, installed services, known quirks. Must be populated during Phase E of setup. |
| `REFERENCES.md` | Machine-specific documentation links, runbooks, vendor contacts. |
| `.env_<machine-name>` | Machine-specific environment variables (non-SSH). Managed by the human operator. |
| `vault/` | Obsidian-compatible vault. The machine's persistent memory. |
| `vault/00_INDEX.md` | Table of contents linking to all vault notes. |
| `vault/01_SYSTEM_INFO.md` | OS version, hardware specs, IP addresses, network config. |
| `vault/02_SERVICES.md` | List of services, their status, config file paths, ports. |
| `vault/03_TASK_LOG.md` | Chronological log of every task performed on this machine. |
| `vault/04_NOTES.md` | Free-form observations, warnings, and tips. |
| `vault/05_SECURITY.md` | SSH key fingerprints, access policies, user accounts, SSH restrictions. |
| `TOOLS/` | Scripts and utilities specific to this machine. |

---

## 5. Workflows

### 5.1 New Connection Setup

When the user says *"Add machine X"* or references a machine that doesn't exist yet, use `tools/new_machine.sh <machine-name>` to generate the folder structure, then follow the phases below.

**Phase A — Scaffolding (automated):**

1. **Run `tools/new_machine.sh <machine-name>`** to create the canonical folder and file structure.
2. **Prompt the user** to configure initial SSH access with their personal user (see Phase B below).

**Phase B — User configures initial SSH (manual, personal user):**

The user sets up SSH access with their personal user (must have sudo). See `ADD_MACHINE.md` for detailed steps.

**Phase C — User creates the `tuneladora` user (manual):**

The user creates the dedicated `tuneladora` user on the server with sudo NOPASSWD:
```bash
sudo useradd -m -s /bin/bash tuneladora
sudo passwd tuneladora
sudo bash -c "echo 'tuneladora ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/tuneladora"
```

**Phase D — User installs the dedicated SSH key (manual):**

Tuneladora generates a dedicated keypair (`~/.ssh/tuneladora`). The user copies it to the server:
```bash
ssh-copy-id -i ~/.ssh/tuneladora.pub tuneladora@<host>
```

**Phase E — Finalize (automated):**

Once the user confirms the key is installed:

1. **Discover the operator's LAN subnet** by inspecting the local network interface:
   ```bash
   ip route | awk '/default/ {print $3}' | head -1
   # or: ip -4 addr show scope global | awk '/inet / {print $2}' | head -1
   ```
   Use the discovered subnet (e.g., `192.168.1.*`) for all SSH restrictions below.
2. **Harden SSH**: add `from="<discovered-subnet>"`, `no-agent-forwarding`, `no-X11-forwarding` to `~tuneladora/.ssh/authorized_keys`.
3. **Disable password login** for `tuneladora`: `sudo passwd -l tuneladora`.
4. **Update `~/.ssh/config`** to use `User tuneladora` and `IdentityFile ~/.ssh/tuneladora`. The LLM is authorized to modify `~/.ssh/config` as part of machine setup and migration.
5. **Test the connection**: `ssh -o ConnectTimeout=5 <machine-name> "whoami"` → expects `tuneladora`.
6. **If successful**, populate `01_SYSTEM_INFO.md` by running basic discovery commands (`uname -a`, `cat /etc/os-release`, `df -h`, `free -h`, `lscpu | head -15`, `ip -4 addr show scope global`).
7. **Populate `CONTEXT.md`** with a summary of OS, purpose, network, and known quirks derived from discovery.
8. **Record admin users** in `01_SYSTEM_INFO.md` (tuneladora as primary, personal user as fallback).
9. **Log the full setup** in `03_TASK_LOG.md`.

### 5.2 Task Execution

When the user says *"On machine X, do Y"*:

1. **Resolve the path**: read `REGISTRY.md` or `machines/<host>/HIERARCHY.md` to find the machine's folder location. Navigate to it (e.g., `machines/<host>/VMs/<name>/` or `machines/<host>/CTs/LXC/<name>/`).
2. **Read context**: load `CLAUDE.md`, `CONTEXT.md`, `REFERENCES.md`, and relevant vault notes.
3. **Connect via SSH** and execute the task:
   ```bash
   ssh <machine-name> "<commands>"
   ```
4. **Verify** the result (check exit codes, confirm expected output).
5. **Update the vault** (see 5.3).

### 5.3 Vault Update Loop

After every task:

1. **Append to `03_TASK_LOG.md`** with a new entry (see format in Section 7).
2. **Update `01_SYSTEM_INFO.md`** if the task changed system state (e.g., installed a package, changed network config).
3. **Update `02_SERVICES.md`** if a service was added, removed, or reconfigured.
4. **Add to `04_NOTES.md`** any observations, warnings, or tips for future tasks.
5. **Update `05_SECURITY.md`** if the task changed user accounts, SSH keys, access policies, or firewall rules.
6. **Update `00_INDEX.md`** if new notes were created.

---

## 6. SSH Connection Model

### Principles

1. **SSH connections use `~/.ssh/config`.** Each machine has a Host entry configured with hostname, user, key, and any other options.
2. **The LLM connects using `ssh <machine-name>`.** No credential variables or `.env` sourcing is needed for SSH.
3. **The LLM must never hardcode or display SSH credentials** (hosts, users, raw keys) in its output.
4. **The LLM may and should update `~/.ssh/config`** as part of machine setup (Phase E) and user migration workflows. This is an authorized automated action, not a manual-only step.
5. **Never connect as `root`.** All connections must use the dedicated `tuneladora` user. Root access is obtained via `sudo` when needed.

### Safe usage pattern

```bash
# Correct — connect using the SSH config alias
ssh <machine-name> "uptime"

# Correct — escalate via sudo when needed
ssh <machine-name> "sudo systemctl restart nginx"

# FORBIDDEN — never hardcode credentials
ssh root@192.168.1.2 "uptime"
```

### LAN subnet discovery

When hardening SSH (Phase E), discover the operator's subnet dynamically rather than hardcoding:

```bash
# On the operator's machine, find the LAN interface's subnet
ip -4 addr show scope global | awk '/inet / {split($2,a,"."); print a[1]"."a[2]"."a[3]".*"}' | head -1
```

Use the result (e.g., `10.0.0.*`) in the `authorized_keys` `from=` restriction.

---

## 7. Obsidian Vault Usage

### Structure

Each machine's vault (`vault/`) uses a flat numbering scheme:

| Note | Purpose |
|------|---------|
| `00_INDEX.md` | Links to all other notes in the vault. Acts as a table of contents. |
| `01_SYSTEM_INFO.md` | Static system information: OS, kernel, hardware, IPs, admin users. Updated when system state changes. |
| `02_SERVICES.md` | Running services, their ports, config paths, and current status. |
| `03_TASK_LOG.md` | Append-only chronological log of every action taken on the machine. |
| `04_NOTES.md` | Free-form notes, warnings, observations. |
| `05_SECURITY.md` | SSH key fingerprints, access policies, user accounts, SSH restrictions. |

### Rules

- **All notes are Markdown.** Compatible with Obsidian but readable by any text editor.
- **`03_TASK_LOG.md` is append-only.** Never delete or rewrite past entries.
- **Other notes are update-in-place.** When system info changes, update the relevant note rather than appending.
- **Use Obsidian-style links** (`[[note-name]]`) when cross-referencing within the vault.
- **New notes can be added** beyond the initial set. Follow the numbering scheme (`06_`, `07_`, etc.) and add them to `00_INDEX.md`.

### Task log format

Every entry in `03_TASK_LOG.md` follows this structure:

```markdown
## YYYY-MM-DD HH:MM — <Task Title>
**Requested by:** user
**Status:** success | partial | failed
**Summary:** What was done.
**Commands run:**
- `command 1`
- `command 2`
**Rollback:**
- `rollback command 1`  ← omit section if not applicable
**Notes:** Anything notable, unexpected output, or warnings for future tasks.
```

### Task log rotation

`03_TASK_LOG.md` is append-only and will grow over time. To prevent it from exceeding the LLM's context window:

- When `03_TASK_LOG.md` exceeds ~200 entries or ~300 KB, rotate it:
  1. Rename `03_TASK_LOG.md` to `03_TASK_LOG_YYYY-MM.md` (e.g., `03_TASK_LOG_2026-04.md`).
  2. Create a fresh `03_TASK_LOG.md` with a header noting the rotation.
  3. Add links to archived logs in `00_INDEX.md`.
- When reading context before a task, load only the current `03_TASK_LOG.md`. Load archived logs only if the task explicitly requires historical context.

---

## 8. AI Behavior Contract

When operating within Tuneladora, the LLM must:

1. **Always read context before acting.** Load the machine's `CLAUDE.md`, `CONTEXT.md`, and relevant vault notes before executing any task.
2. **Connect using `ssh <machine-name>`.** Never hardcode or display SSH credentials (hosts, users, keys) in output.
3. **Never connect as root.** All SSH connections use the `tuneladora` user. Use `sudo` for privileged operations.
4. **Always update the vault after a task.** At minimum, append to `03_TASK_LOG.md`.
5. **Ask before destructive actions.** Any command that deletes data, stops a production service, or modifies firewall rules requires explicit user confirmation.
6. **Verify before reporting success.** Check exit codes and expected output before marking a task as complete.
7. **Stay within scope.** Only operate on the machine the user has specified. Do not hop between machines unless explicitly instructed.
8. **Document uncertainty.** If something is unclear or a command produces unexpected output, note it in `04_NOTES.md` and inform the user.
9. **Prefer idempotent commands.** When possible, use commands that can be safely re-run.
10. **Respect the machine's `CLAUDE.md`.** Machine-specific rules override general rules when they conflict.
11. **Populate context files during setup.** `CONTEXT.md` and vault notes must be filled with real data during Phase E, not left as empty templates.
12. **Discover subnets dynamically.** Never hardcode IP ranges. Discover the operator's LAN subnet before applying SSH restrictions.

---

## 9. Extension Points

### Adding a new machine

1. Run `tools/new_machine.sh <machine-name>` to generate the canonical folder structure.
2. Follow Workflow 5.1 (New Connection Setup).
3. See `ADD_MACHINE.md` for the detailed step-by-step workflow.

### Adding new tools

1. Place scripts in the machine's `TOOLS/` folder (e.g., `machines/<host>/VMs/<name>/TOOLS/`).
2. Document each tool with a comment header explaining its purpose, usage, and any dependencies.
3. Reference the tool in the machine's `REFERENCES.md`.

### Adding new vault notes

1. Create a new numbered note (e.g., `06_BACKUPS.md`) in the vault.
2. Add it to `00_INDEX.md`.
3. Follow the same Markdown conventions as existing notes.

### Common additional vault notes

- `06_BACKUPS.md` — backup schedules, retention policies, restore procedures.
- `06_CRON_JOBS.md` — scheduled tasks and their purposes.
- `06_DEPLOY_HISTORY.md` — deployment log with versions and rollback notes.

---

## 10. Open Questions / Future Work

| Topic | Status | Notes |
|-------|--------|-------|
| **SSH key passphrase handling** | Open | Currently assumes unencrypted keys or `ssh-agent`. No mechanism for passphrase entry. |
| **Multi-hop SSH / bastion hosts** | Resolved | Implemented via `ProxyJump` (LXC) and `ProxyCommand + docker exec` (Docker). See §11. |
| **Vault search** | Idea | As vaults grow, a search or tagging mechanism may be needed. |
| **Task rollback** | Partial | Rollback commands are now captured per-task in `03_TASK_LOG.md`. Automated rollback execution is not yet implemented. |
| **Parallel execution** | Out of scope | Running tasks on multiple machines simultaneously is not currently supported. |
| **Notifications** | Out of scope | No mechanism for alerting the user of task completion or failure outside the terminal. |
| **Vault sync / backup** | Idea | Vaults are local files. A git-based sync or backup strategy would improve durability. |
| **Minimum-privilege sudo** | Idea | `tuneladora ALL=(ALL) NOPASSWD: ALL` is convenient but broad. Scoping to specific commands improves security posture. |

---

## 11. Hierarchy Model

### Node Types

Every machine has a **type** declared in its `HIERARCHY.md` file:

| Type | Description | Examples |
|------|-------------|---------|
| `bare-metal` | Physical server with direct network access | Home server, dedicated host |
| `vm` | Virtual machine with its own IP (KVM/QEMU) | Proxmox QEMU VM |
| `lxc` | Linux container hosted on a Proxmox node | Any `pct`-managed container |
| `docker` | Docker container running on a parent host | Any `docker run`/compose container |

### Parent–Child Relationships

- Every node except root bare-metal nodes declares a `parent` in `HIERARCHY.md`.
- A parent node tracks all its children in `vault/06_CONTAINERS.md`.
- Children are stored in subfolders by type: `VMs/<name>/` for VMs, `CTs/LXC/<name>/` for LXC containers, `CTs/Docker/<name>/` for Docker containers.
- The global `REGISTRY.md` at the repo root shows the full tree.
- `children: []` in `HIERARCHY.md` lists child machine names for quick lookup.

### HIERARCHY.md Structure

Each machine folder contains a `HIERARCHY.md` file:

```markdown
# <machine-name> — Hierarchy

## Node Type
type: lxc             # bare-metal | vm | lxc | docker

## Parent
parent: hef-minipc-proxmox   # null if root node

## Children
children: []          # list of machine-names this node hosts

## Connection Model
connection_model: proxyjump   # direct | proxyjump | docker-exec

## Container ID
container_id: 101     # Proxmox VMID for lxc; container name/ID for docker; null otherwise

## Notes
*(connectivity quirks, port mappings, network bridge)*
```

### Connection Models

#### `direct` — bare-metal and vm

Standard SSH entry. The machine is reachable at its own IP:

```
Host <machine-name>
  HostName <ip-or-hostname>
  User tuneladora
  IdentityFile ~/.ssh/tuneladora
```

#### `proxyjump` — lxc

The LXC container has its own IP on the parent's bridge (e.g., `vmbr0`). SSH reaches it by jumping through the parent:

```
Host <container-name>
  HostName <container-ip>
  User tuneladora
  IdentityFile ~/.ssh/tuneladora
  ProxyJump <parent-name>
```

Discover the container IP:
```bash
ssh <parent-name> "pct exec <vmid> -- ip -4 addr show eth0 | grep inet"
```

#### `docker-exec` — docker

Docker containers typically have no SSH daemon. Tuneladora connects by piping a shell through `docker exec` on the parent host. No SSH key or user setup is required inside the container:

```
Host <container-name>
  HostName unused
  ProxyCommand ssh <parent-name> docker exec -i <container-name> /bin/sh
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
```

Commands issued via `ssh <container-name> "..."` are transparently routed through `docker exec`. The LLM uses this identically to any other machine connection.

> **Security note:** `StrictHostKeyChecking no` is necessary because `docker exec` does not present an SSH host key. Scope the parent's `tuneladora` user to only the containers it needs to exec into if minimum-privilege is required.

### AI Behavior Rules for Hierarchy

When operating on a **child machine** (lxc or docker):

1. **Read the parent's context first.** Load the parent's `HIERARCHY.md` (at `machines/<host>/HIERARCHY.md` for bare-metal, or `machines/<grandparent>/VMs/<host>/HIERARCHY.md` if the parent is itself a child) and `vault/06_CONTAINERS.md` before acting on the child.
2. **Never manage a container's lifecycle through the child's connection.** Use the parent to start/stop/destroy containers (`pct start`, `docker restart`, etc.).
3. **After adding or removing a child**, update the parent's `vault/06_CONTAINERS.md` and the root `REGISTRY.md`.
4. **For Docker containers**, commands run as the container's default user (typically `root`). Document the actual user in `HIERARCHY.md` Notes.

### Scaffolding Containers

Use `tools/new_machine.sh` with the `--type` and `--parent` flags. The script places the new machine in the correct subfolder automatically:

```bash
# VM — creates machines/<parent>/VMs/<name>/
tools/new_machine.sh my-vm --type vm --parent hef-minipc-proxmox

# LXC container — creates machines/<parent>/CTs/LXC/<name>/
tools/new_machine.sh my-lxc --type lxc --parent hef-minipc-proxmox

# Docker container — creates machines/<parent>/CTs/Docker/<name>/
tools/new_machine.sh my-app --type docker --parent hef-minipc-proxmox
```

Follow `ADD_CONTAINER.md` for the complete setup workflow.
