#!/usr/bin/env bash
# new_machine.sh — Scaffold a new machine folder for Tuneladora
#
# Usage:
#   ./tools/new_machine.sh <machine-name>
#
# Creates:
#   machines/<machine-name>/
#     CLAUDE.md
#     CONTEXT.md
#     REFERENCES.md
#     vault_<machine-name>/
#       00_INDEX.md
#       01_SYSTEM_INFO.md
#       02_SERVICES.md
#       03_TASK_LOG.md
#       04_NOTES.md
#       05_SECURITY.md
#     TOOLS/
#       .gitkeep
#
# This script is the single source of truth for machine folder structure.
# Run it instead of manually creating files to ensure consistency with SPEC.md.

set -euo pipefail

# ── Validate input ─────────────────────────────────────────────────────────────

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <machine-name>" >&2
  exit 1
fi

MACHINE="$1"

if [[ ! "$MACHINE" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$ ]]; then
  echo "Error: machine name must be lowercase alphanumeric with hyphens (e.g. 'web-prod', 'db-01')" >&2
  exit 1
fi

# ── Resolve paths ──────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MACHINE_DIR="$REPO_ROOT/machines/$MACHINE"
VAULT_DIR="$MACHINE_DIR/vault_$MACHINE"
DATE="$(date +%Y-%m-%d)"

# ── Guard: already exists ──────────────────────────────────────────────────────

if [[ -d "$MACHINE_DIR" ]]; then
  echo "Error: $MACHINE_DIR already exists. Aborting to avoid overwriting." >&2
  exit 1
fi

# ── Create structure ───────────────────────────────────────────────────────────

echo "Creating machine: $MACHINE"
mkdir -p "$VAULT_DIR" "$MACHINE_DIR/TOOLS"
touch "$MACHINE_DIR/TOOLS/.gitkeep"

# ── CLAUDE.md ──────────────────────────────────────────────────────────────────

cat > "$MACHINE_DIR/CLAUDE.md" << HEREDOC
# $MACHINE — Machine Rules

## Identity

You are operating on **$MACHINE**.

## Machine-Specific Rules

- Add real machine-specific rules here during Phase E (after system discovery).
- These rules override the global CLAUDE.md when they conflict.
- Delete this placeholder block once real rules are in place.

## Key Paths

*(Populate during Phase E)*
HEREDOC

# ── CONTEXT.md ─────────────────────────────────────────────────────────────────

cat > "$MACHINE_DIR/CONTEXT.md" << HEREDOC
# $MACHINE — Context

> Populated during Phase E (post-SSH setup). Do not leave this as a template.

## OS

*(Populate during Phase E)*

## Purpose

*(What does this machine do?)*

## Network

*(IP, interfaces, NFS mounts, etc.)*

## Known Quirks

*(Any non-obvious behaviors, resource constraints, or operational warnings)*

## History

- $DATE: Machine scaffolded via new_machine.sh.
HEREDOC

# ── REFERENCES.md ──────────────────────────────────────────────────────────────

cat > "$MACHINE_DIR/REFERENCES.md" << HEREDOC
# $MACHINE — References

## Documentation Links

## Runbooks

## Vendor Contacts

## Tools
HEREDOC

# ── 00_INDEX.md ────────────────────────────────────────────────────────────────

cat > "$VAULT_DIR/00_INDEX.md" << HEREDOC
# $MACHINE — Vault Index

## Notes

| File | Contents |
|------|----------|
| [[01_SYSTEM_INFO]] | OS, kernel, hardware, IPs, admin users |
| [[02_SERVICES]] | Running services, ports, config paths |
| [[03_TASK_LOG]] | Chronological log of all tasks performed |
| [[04_NOTES]] | Free-form observations, warnings, scope limits |
| [[05_SECURITY]] | SSH access policies, user accounts, restrictions |

## Status

- Vault created: $DATE
- Setup status: awaiting Phase B–E
HEREDOC

# ── 01_SYSTEM_INFO.md ──────────────────────────────────────────────────────────

cat > "$VAULT_DIR/01_SYSTEM_INFO.md" << HEREDOC
# $MACHINE — System Info

> Last updated: $DATE (scaffolded — populate during Phase E)

## OS

| Field | Value |
|-------|-------|
| OS | *(TBD)* |
| Kernel | *(TBD)* |
| Architecture | *(TBD)* |
| Hostname | *(TBD)* |

## Hardware

| Field | Value |
|-------|-------|
| CPU | *(TBD)* |
| RAM | *(TBD)* |

## Network

| Interface | IP | Notes |
|-----------|----|-------|
| *(TBD)* | *(TBD)* | *(TBD)* |

## Storage

| Filesystem | Size | Used | Avail | Use% | Mount |
|------------|------|------|-------|------|-------|
| *(TBD)* | *(TBD)* | *(TBD)* | *(TBD)* | *(TBD)* | / |

## Admin Users

| User | SSH Key | Sudo | Notes |
|------|---------|------|-------|
| tuneladora | \`~/.ssh/tuneladora\` | NOPASSWD | Dedicated admin user |
| *(personal)* | *(TBD)* | sudo (with password) | Personal fallback |
HEREDOC

# ── 02_SERVICES.md ─────────────────────────────────────────────────────────────

cat > "$VAULT_DIR/02_SERVICES.md" << HEREDOC
# $MACHINE — Services

> Last updated: $DATE (scaffolded — populate during Phase E)

## Active Services

| Service | Status | Port | Config Path | Notes |
|---------|--------|------|-------------|-------|
| *(TBD)* | *(TBD)* | *(TBD)* | *(TBD)* | *(TBD)* |
HEREDOC

# ── 03_TASK_LOG.md ─────────────────────────────────────────────────────────────

cat > "$VAULT_DIR/03_TASK_LOG.md" << HEREDOC
# $MACHINE — Task Log

> Append-only. Never delete or rewrite past entries.
> Format: see SPEC.md section 7.

## $DATE — Machine Scaffolded
**Requested by:** user
**Status:** success
**Summary:** Created machine folder structure via \`tools/new_machine.sh $MACHINE\`.
**Commands run:**
- \`tools/new_machine.sh $MACHINE\`
**Rollback:** \`rm -rf machines/$MACHINE\`
**Notes:** Awaiting user SSH setup (Phase B) before any server operations.
HEREDOC

# ── 04_NOTES.md ────────────────────────────────────────────────────────────────

cat > "$VAULT_DIR/04_NOTES.md" << HEREDOC
# $MACHINE — Notes

> Free-form observations, warnings, and tips.

## Setup Status

- [ ] Phase B: Personal SSH configured
- [ ] Phase C: tuneladora user created
- [ ] Phase D: tuneladora SSH key installed
- [ ] Phase E: SSH hardened, system discovered, context files populated
HEREDOC

# ── 05_SECURITY.md ─────────────────────────────────────────────────────────────

cat > "$VAULT_DIR/05_SECURITY.md" << HEREDOC
# $MACHINE — Security

> Last updated: $DATE (scaffolded — populate during Phase E)

## SSH Access

| User | Key File | Fingerprint | Restrictions | Status |
|------|----------|-------------|--------------|--------|
| tuneladora | \`~/.ssh/tuneladora\` | *(TBD — run \`ssh-keygen -lf ~/.ssh/tuneladora.pub\`)* | \`from="<subnet>"\`, no-agent-forwarding, no-X11-forwarding | Pending |
| *(personal)* | *(TBD)* | — | None | Fallback |

## User Accounts

| User | Shell | Sudo | Password Login | Notes |
|------|-------|------|----------------|-------|
| tuneladora | /bin/bash | NOPASSWD: ALL | Disabled | Primary admin — pending setup |
| *(personal)* | /bin/bash | sudo (with password) | Enabled | Personal fallback |

## Firewall

*(Not configured yet)*

## Audit Notes

- $DATE: Machine scaffolded. SSH setup pending.
HEREDOC

# ── Done ───────────────────────────────────────────────────────────────────────

echo ""
echo "Done. Structure created at: machines/$MACHINE/"
echo ""
echo "Next steps:"
echo "  1. Follow ADD_MACHINE.md Phase B: configure personal SSH access"
echo "  2. Tell Tuneladora: 'SSH ready for $MACHINE'"
