# Tuneladora

SSH connection hub operated by an LLM assistant to manage multiple remote servers. The LLM connects via SSH, executes tasks, and maintains persistent memory of each machine through Obsidian-compatible vaults.

See [SPEC.md](SPEC.md) for the full specification.

## SSH Setup

### 1. Generate an SSH key

```bash
ssh-keygen -t ed25519 -f ~/.ssh/<machine-name> -C "<user>@<machine-name>"
```

### 2. Copy the public key to the server

```bash
ssh-copy-id -i ~/.ssh/<machine-name>.pub <user>@<host>
```

### 3. Add an SSH config entry (recommended)

Append to `~/.ssh/config`:

```
Host <machine-name>
    HostName <host>
    User <user>
    IdentityFile ~/.ssh/<machine-name>
    IdentitiesOnly yes
```

### 4. Verify the connection

```bash
ssh <machine-name>
```

Should connect without a password prompt.

## Project Structure

```
machines/
└── <machine-name>/
    ├── CLAUDE.md                  # Machine-specific AI rules
    ├── CONTEXT.md                 # OS, purpose, known quirks
    ├── REFERENCES.md              # Docs, runbooks, vendor links
    ├── .env_<machine-name>        # SSH credentials (sourced, never read)
    ├── vault_<machine-name>/      # Obsidian vault — persistent memory
    │   ├── 00_INDEX.md
    │   ├── 01_SYSTEM_INFO.md
    │   ├── 02_SERVICES.md
    │   ├── 03_TASK_LOG.md
    │   └── 04_NOTES.md
    └── TOOLS/                     # Machine-specific scripts
```

## License

[MIT](LICENSE)