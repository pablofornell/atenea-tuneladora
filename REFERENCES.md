# References

## Examples of good work

A well-maintained machine folder looks like this:

```
machines/webserver-prod/
├── CLAUDE.md                          # "Always use apt. Never restart nginx without checking config first."
├── CONTEXT.md                         # "Ubuntu 22.04 LTS, runs nginx + Node.js app, 4GB RAM, disk at 60%"
├── REFERENCES.md                      # Links to the app's deploy docs
├── .env_webserver-prod                # Machine-specific environment variables (non-SSH)
├── vault_webserver-prod/
│   ├── 00_INDEX.md                    # Table of contents linking all vault notes
│   ├── 01_SYSTEM_INFO.md              # OS, hardware, IPs, admin users
│   ├── 02_SERVICES.md                 # Running services, ports, config paths
│   ├── 03_TASK_LOG.md                 # Append-only chronological task log
│   ├── 04_NOTES.md                    # Observations, warnings, tips
│   └── 05_SECURITY.md                 # SSH keys, user accounts, access policies
└── TOOLS/
    └── deploy.sh
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
