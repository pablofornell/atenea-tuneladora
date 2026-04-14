# References

## Examples of well-maintained machines

A bare-metal host with a nested VM:

```
machines/
├── MACHINE_NAME/                    # bare-metal (root node)
│   ├── CLAUDE.md                    # Proxmox-specific rules
│   ├── CONTEXT.md                   # Proxmox VE, production hypervisor
│   ├── vault/                       # Obsidian vault
│   │   ├── 00_INDEX.md
│   │   ├── 01_SYSTEM_INFO.md
│   │   ├── 02_SERVICES.md
│   │   ├── 03_TASK_LOG.md
│   │   ├── 04_NOTES.md
│   │   ├── 05_SECURITY.md
│   │   └── 06_CONTAINERS.md         # Inventory: hef-pam (VMID 100)
│   ├── TOOLS/
│   └── VMs/                         # Virtual machines
│       └── MACHINE_NAME/
│           ├── CLAUDE.md            # "Always use apt. Never restart openclaw without confirmation."
│           ├── CONTEXT.md           # Ubuntu 24.04, Ollama + OpenClaw
│           ├── vault/
│           │   ├── 00_INDEX.md
│           │   ├── 01_SYSTEM_INFO.md
│           │   └── ...
│           └── TOOLS/
```

> Generate new machines with `tools/new_machine.sh <machine-name>` — never create the folder structure manually.

## Scaffolding

```bash
# Add a new machine (from repo root)
tools/new_machine.sh my-server
```

Then follow `ADD_MACHINE.md` for the full 5-phase workflow.

## Naming Conventions

- Machine names: lowercase, hyphens as separators — e.g., `web-prod`, `db-staging`, `hef-pam`
- Vault notes: numbered prefix, uppercase — e.g., `06_BACKUPS.md`
- Each machine's vault is independent — no cross-machine links

## Relevant links

- [Obsidian](https://obsidian.md) — The note-taking format used for vaults
- [SPEC.md](SPEC.md) — Full system specification
- [ADD_MACHINE.md](ADD_MACHINE.md) — Step-by-step workflow for adding a new machine
