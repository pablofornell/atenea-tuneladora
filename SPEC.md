# Tuneladora — Specification

## 1. Project Summary

**Tuneladora** is an SSH connection hub designed to be operated by an LLM with terminal access (such as Claude CLI), orchestrated by a human user. It enables autonomous server management — maintenance, deployments, configuration, troubleshooting — across multiple remote machines via SSH, while maintaining a structured, persistent memory of each machine's history, configuration, and completed tasks.

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

```
tuneladora/
├── CLAUDE.md              # Global AI identity and rules
├── CONTEXT.md             # Global project context
├── REFERENCES.md          # Global references and resources
├── SPEC.md                # This file
├── machines/
│   └── <machine-name>/
│       ├── CLAUDE.md                  # Machine-specific AI instructions
│       ├── CONTEXT.md                 # Machine-specific context (OS, purpose, history)
│       ├── REFERENCES.md              # Machine-specific resources and notes
│       ├── .env_<machine-name>        # Machine-specific environment variables
│       ├── vault_<machine-name>/      # Obsidian vault for persistent memory
│       │   ├── 00_INDEX.md            # Vault table of contents
│       │   ├── 01_SYSTEM_INFO.md      # OS, hardware, network details
│       │   ├── 02_SERVICES.md         # Running services and their configs
│       │   ├── 03_TASK_LOG.md         # Chronological log of all tasks performed
│       │   └── 04_NOTES.md            # Free-form notes and observations
│       └── TOOLS/                     # Machine-specific scripts and utilities
│           └── .gitkeep
└── LICENSE
```

### How the pieces connect

1. **Root-level files** (`CLAUDE.md`, `CONTEXT.md`, `REFERENCES.md`) define the global identity and context the LLM operates under.
2. **Per-machine folders** under `machines/` each contain their own context files that extend (not replace) the root ones.
3. **SSH connections** are configured via `~/.ssh/config`. The LLM connects using `ssh <machine-name>` — no credential variables needed.
4. **Obsidian vaults** (`vault_<machine-name>/`) serve as the machine's long-term memory. The LLM reads them before acting and writes to them after completing a task.
5. **TOOLS/** holds executable scripts specific to a machine (backup scripts, deploy helpers, health checks, etc.).

---

## 4. Folder & File Reference

### Root level

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Defines the LLM's identity, tone, and global behavioral rules. |
| `CONTEXT.md` | Describes what the project is, what success looks like, and what to avoid. |
| `REFERENCES.md` | Links, examples, and supplementary notes for the LLM. |
| `SPEC.md` | This specification document. |
| `machines/` | Parent directory for all machine-specific folders. |

### Per-machine level (`machines/<machine-name>/`)

| File / Folder | Purpose |
|---------------|---------|
| `CLAUDE.md` | Machine-specific AI instructions. Extends the root `CLAUDE.md` with rules scoped to this machine (e.g., "always use `apt` not `yum`"). |
| `CONTEXT.md` | Machine-specific context: OS, purpose, installed services, known quirks. |
| `REFERENCES.md` | Machine-specific documentation links, runbooks, vendor contacts. |
| `.env_<machine-name>` | Machine-specific environment variables (non-SSH). Managed by the human operator. |
| `vault_<machine-name>/` | Obsidian-compatible vault. The machine's persistent memory. |
| `vault_<machine-name>/00_INDEX.md` | Table of contents linking to all vault notes. |
| `vault_<machine-name>/01_SYSTEM_INFO.md` | OS version, hardware specs, IP addresses, network config. |
| `vault_<machine-name>/02_SERVICES.md` | List of services, their status, config file paths, ports. |
| `vault_<machine-name>/03_TASK_LOG.md` | Chronological log of every task performed on this machine. |
| `vault_<machine-name>/04_NOTES.md` | Free-form observations, warnings, and tips. |
| `TOOLS/` | Scripts and utilities specific to this machine. |

---

## 5. Workflows

### 5.1 New Connection Setup

When the user says *"Add machine X"* or references a machine that doesn't exist yet:

1. **Create the machine folder:** `machines/<machine-name>/`
2. **Create the context files** from templates:
   - `CLAUDE.md` — pre-filled with machine-name placeholder.
   - `CONTEXT.md` — empty sections for OS, purpose, etc.
   - `REFERENCES.md` — empty sections.
3. **Prompt the user** to configure `~/.ssh/config` with a Host entry for the machine (see README for setup steps).
4. **Create the vault** directory with initial template notes (`00_INDEX.md` through `04_NOTES.md`).
5. **Create the `TOOLS/` directory** with a `.gitkeep`.
6. **Test the connection** by running `ssh -o ConnectTimeout=5 <machine-name> "echo ok"`.
7. **If successful**, populate `01_SYSTEM_INFO.md` by running basic discovery commands (`uname -a`, `cat /etc/os-release`, `df -h`, `free -h`, etc.).
8. **Log the setup** in `03_TASK_LOG.md`.

### 5.2 Task Execution

When the user says *"On machine X, do Y"*:

1. **Navigate** to `machines/<machine-name>/`.
2. **Read context**: load `CLAUDE.md`, `CONTEXT.md`, `REFERENCES.md`, and relevant vault notes.
3. **Connect via SSH** and execute the task:
   ```bash
   ssh <machine-name> "<commands>"
   ```
4. **Verify** the result (check exit codes, confirm expected output).
5. **Update the vault** (see 5.3).

### 5.3 Vault Update Loop

After every task:

1. **Append to `03_TASK_LOG.md`** with a new entry:
   ```markdown
   ## YYYY-MM-DD HH:MM — <Task Title>
   **Requested by:** user
   **Status:** success | partial | failed
   **Summary:** What was done.
   **Commands run:**
   - `command 1`
   - `command 2`
   **Notes:** Anything notable.
   ```
2. **Update `01_SYSTEM_INFO.md`** if the task changed system state (e.g., installed a package, changed network config).
3. **Update `02_SERVICES.md`** if a service was added, removed, or reconfigured.
4. **Add to `04_NOTES.md`** any observations, warnings, or tips for future tasks.
5. **Update `00_INDEX.md`** if new notes were created.

---

## 6. SSH Connection Model

### Principles

1. **SSH connections use `~/.ssh/config`.** Each machine has a Host entry configured by the human operator with hostname, user, key, and any other options.
2. **The LLM connects using `ssh <machine-name>`.** No credential variables or `.env` sourcing is needed for SSH.
3. **The LLM must never hardcode or display SSH credentials** (hosts, users, keys) in its output.
4. **The human operator manages `~/.ssh/config`** exclusively. The LLM may remind the user to configure it but must not modify it.

### Safe usage pattern

```bash
# Correct — connect using the SSH config alias
ssh <machine-name> "uptime"

# FORBIDDEN — never hardcode credentials
ssh root@192.168.1.2 "uptime"
```

---

## 7. Obsidian Vault Usage

### Structure

Each machine's vault (`vault_<machine-name>/`) uses a flat numbering scheme:

| Note | Purpose |
|------|---------|
| `00_INDEX.md` | Links to all other notes in the vault. Acts as a table of contents. |
| `01_SYSTEM_INFO.md` | Static system information: OS, kernel, hardware, IPs. Updated when system state changes. |
| `02_SERVICES.md` | Running services, their ports, config paths, and current status. |
| `03_TASK_LOG.md` | Append-only chronological log of every action taken on the machine. |
| `04_NOTES.md` | Free-form notes, warnings, observations. |

### Rules

- **All notes are Markdown.** Compatible with Obsidian but readable by any text editor.
- **`03_TASK_LOG.md` is append-only.** Never delete or rewrite past entries.
- **Other notes are update-in-place.** When system info changes, update the relevant note rather than appending.
- **Use Obsidian-style links** (`[[note-name]]`) when cross-referencing within the vault.
- **New notes can be added** beyond the initial four. Follow the numbering scheme (`05_`, `06_`, etc.) and add them to `00_INDEX.md`.

---

## 8. AI Behavior Contract

When operating within Tuneladora, the LLM must:

1. **Always read context before acting.** Load the machine's `CLAUDE.md`, `CONTEXT.md`, and relevant vault notes before executing any task.
2. **Connect using `ssh <machine-name>`.** Never hardcode or display SSH credentials (hosts, users, keys) in output.
3. **Always update the vault after a task.** At minimum, append to `03_TASK_LOG.md`.
5. **Ask before destructive actions.** Any command that deletes data, stops a production service, or modifies firewall rules requires explicit user confirmation.
6. **Verify before reporting success.** Check exit codes and expected output before marking a task as complete.
7. **Stay within scope.** Only operate on the machine the user has specified. Do not hop between machines unless explicitly instructed.
8. **Document uncertainty.** If something is unclear or a command produces unexpected output, note it in `04_NOTES.md` and inform the user.
9. **Prefer idempotent commands.** When possible, use commands that can be safely re-run.
10. **Respect the machine's `CLAUDE.md`.** Machine-specific rules override general rules when they conflict.

---

## 9. Extension Points

### Adding a new machine

1. Follow Workflow 5.1 (New Connection Setup). The LLM handles this autonomously when a new machine name is referenced.
2. Alternatively, manually create the folder structure and fill in the files.

### Adding new tools

1. Place scripts in `machines/<machine-name>/TOOLS/`.
2. Document each tool with a comment header explaining its purpose, usage, and any dependencies.
3. Reference the tool in the machine's `REFERENCES.md`.

### Adding new vault templates

1. Create a new numbered note (e.g., `05_BACKUPS.md`) in the vault.
2. Add it to `00_INDEX.md`.
3. Follow the same Markdown conventions as existing notes.

### Customizing the vault structure

The default vault ships with four notes. Each machine can extend this with domain-specific notes:
- `05_BACKUPS.md` — backup schedules, retention policies, restore procedures.
- `05_CRON_JOBS.md` — scheduled tasks and their purposes.
- `05_DEPLOY_HISTORY.md` — deployment log with versions and rollback notes.

Number them sequentially and register them in `00_INDEX.md`.

---

## 10. Open Questions / Future Work

| Topic | Status | Notes |
|-------|--------|-------|
| **SSH key passphrase handling** | Open | Currently assumes unencrypted keys or `ssh-agent`. No mechanism for passphrase entry. |
| **Multi-hop SSH / bastion hosts** | Open | Some machines may require `ProxyJump` in `~/.ssh/config`. |
| **Vault search** | Idea | As vaults grow, a search or tagging mechanism may be needed. |
| **Task rollback** | Idea | Storing rollback commands alongside task log entries for undo capability. |
| **Parallel execution** | Out of scope | Running tasks on multiple machines simultaneously is not currently supported. |
| **Notifications** | Out of scope | No mechanism for alerting the user of task completion or failure outside the terminal. |
| **Vault sync / backup** | Idea | Vaults are local files. A git-based sync or backup strategy would improve durability. |
