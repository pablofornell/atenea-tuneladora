#!/usr/bin/env bash
# new_machine.sh — Scaffold a new machine folder for Tuneladora
#
# Usage:
#   ./tools/new_machine.sh <machine-name> [--type bare-metal|vm|lxc|docker] [--parent <machine-name>]
#
# Options:
#   --type    Node type: bare-metal (default), vm, lxc, docker
#   --parent  Parent machine name (required for vm, lxc, and docker)
#
# Creates the canonical folder and vault structure under the correct path:
#   bare-metal → machines/<name>/
#   vm         → machines/<parent>/VMs/<name>/
#   lxc        → machines/<parent>/CTs/LXC/<name>/
#   docker     → machines/<parent>/CTs/Docker/<name>/
#
# This script is the single source of truth for machine folder structure.
# Run it instead of manually creating files to ensure consistency with SPEC.md.

set -euo pipefail

# ── Defaults ───────────────────────────────────────────────────────────────────

MACHINE_TYPE="bare-metal"
PARENT=""

# ── Parse arguments ────────────────────────────────────────────────────────────

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <machine-name> [--type bare-metal|vm|lxc|docker] [--parent <machine-name>]" >&2
  exit 1
fi

MACHINE="$1"
shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)
      MACHINE_TYPE="$2"
      shift 2
      ;;
    --parent)
      PARENT="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: $0 <machine-name> [--type bare-metal|vm|lxc|docker] [--parent <machine-name>]" >&2
      exit 1
      ;;
  esac
done

# ── Validate machine name ──────────────────────────────────────────────────────

if [[ ! "$MACHINE" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$ ]]; then
  echo "Error: machine name must be lowercase alphanumeric with hyphens (e.g. 'web-prod', 'db-01')" >&2
  exit 1
fi

# ── Validate type ──────────────────────────────────────────────────────────────

case "$MACHINE_TYPE" in
  bare-metal|vm|lxc|docker) ;;
  *)
    echo "Error: --type must be one of: bare-metal, vm, lxc, docker" >&2
    exit 1
    ;;
esac

# ── Validate parent requirement ────────────────────────────────────────────────

if [[ "$MACHINE_TYPE" != "bare-metal" ]] && [[ -z "$PARENT" ]]; then
  echo "Error: --parent is required when --type is vm, lxc, or docker" >&2
  exit 1
fi

if [[ -n "$PARENT" ]] && [[ ! "$PARENT" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$ ]]; then
  echo "Error: parent name must be lowercase alphanumeric with hyphens" >&2
  exit 1
fi

# ── Resolve paths ──────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DATE="$(date +%Y-%m-%d)"

# Determine the subfolder based on type
case "$MACHINE_TYPE" in
  bare-metal) SUBDIR="" ;;
  vm)         SUBDIR="VMs" ;;
  lxc)        SUBDIR="CTs/LXC" ;;
  docker)     SUBDIR="CTs/Docker" ;;
esac

# Build the full machine directory path
if [[ -n "$PARENT" && -n "$SUBDIR" ]]; then
  MACHINE_DIR="$REPO_ROOT/machines/$PARENT/$SUBDIR/$MACHINE"
else
  MACHINE_DIR="$REPO_ROOT/machines/$MACHINE"
fi

VAULT_DIR="$MACHINE_DIR/vault"

# ── Guard: already exists ──────────────────────────────────────────────────────

if [[ -d "$MACHINE_DIR" ]]; then
  echo "Error: $MACHINE_DIR already exists. Aborting to avoid overwriting." >&2
  exit 1
fi

# ── Guard: parent must exist (if specified) ────────────────────────────────────

if [[ -n "$PARENT" ]]; then
  # Resolve the parent directory path
  if [[ -n "$SUBDIR" ]]; then
    # Parent could be bare-metal or itself a child; check both possibilities
    PARENT_DIR="$REPO_ROOT/machines/$PARENT"
    if [[ ! -d "$PARENT_DIR" ]]; then
      echo "Error: parent machine '$PARENT' not found." >&2
      echo "       Expected at: machines/$PARENT/" >&2
      echo "       (Or machines/<grandparent>/VMs/$PARENT/ if the parent is itself a child)" >&2
      exit 1
    fi
  fi
fi

# ── Derive connection model ────────────────────────────────────────────────────

case "$MACHINE_TYPE" in
  bare-metal) CONNECTION_MODEL="direct" ;;
  vm)         CONNECTION_MODEL="direct" ;;
  lxc)        CONNECTION_MODEL="proxyjump" ;;
  docker)     CONNECTION_MODEL="docker-exec" ;;
esac

# ── Compute relative path for messages ─────────────────────────────────────────

REL_PATH="${MACHINE_DIR#$REPO_ROOT/}"

# ── Create structure ───────────────────────────────────────────────────────────

echo "Creating machine: $MACHINE (type: $MACHINE_TYPE${PARENT:+, parent: $PARENT})"
echo "Path: $REL_PATH"
mkdir -p "$VAULT_DIR" "$MACHINE_DIR/TOOLS"
touch "$MACHINE_DIR/TOOLS/.gitkeep"

# ── HIERARCHY.md ───────────────────────────────────────────────────────────────

cat > "$MACHINE_DIR/HIERARCHY.md" << HEREDOC
# $MACHINE — Hierarchy

## Node Type
type: $MACHINE_TYPE

## Parent
parent: ${PARENT:-null}

## Children
children: []

## Connection Model
connection_model: $CONNECTION_MODEL

## Container ID
# For lxc: Proxmox VMID (e.g. 101). For docker: container name or ID.
container_id: null

## Notes
*(Populate during setup: IP address, network bridge, port mappings, connectivity quirks)*
HEREDOC

# ── CLAUDE.md ──────────────────────────────────────────────────────────────────

cat > "$MACHINE_DIR/CLAUDE.md" << HEREDOC
# $MACHINE — Machine Rules

## Identity

You are operating on **$MACHINE** (type: $MACHINE_TYPE${PARENT:+, hosted on $PARENT}).

## Machine-Specific Rules

- Add real machine-specific rules here during setup (after system discovery).
- These rules override the global CLAUDE.md when they conflict.
- Delete this placeholder block once real rules are in place.

## Key Paths

*(Populate during setup)*
HEREDOC

# ── CONTEXT.md ─────────────────────────────────────────────────────────────────

cat > "$MACHINE_DIR/CONTEXT.md" << HEREDOC
# $MACHINE — Context

> Populated during setup. Do not leave this as a template.

## OS

*(Populate during setup)*

## Purpose

*(What does this machine do?)*

## Network

*(IP, interfaces, bridge, port mappings, etc.)*

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
- Machine type: $MACHINE_TYPE
- Parent: ${PARENT:-none}
- Setup status: awaiting setup
HEREDOC

# ── 01_SYSTEM_INFO.md ──────────────────────────────────────────────────────────

cat > "$VAULT_DIR/01_SYSTEM_INFO.md" << HEREDOC
# $MACHINE — System Info

> Last updated: $DATE (scaffolded — populate during setup)

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

> Last updated: $DATE (scaffolded — populate during setup)

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
**Summary:** Created machine folder structure via \`tools/new_machine.sh $MACHINE --type $MACHINE_TYPE${PARENT:+ --parent $PARENT}\` at \`$REL_PATH\`.
**Commands run:**
- \`tools/new_machine.sh $MACHINE --type $MACHINE_TYPE${PARENT:+ --parent $PARENT}\`
**Rollback:** \`rm -rf "$REL_PATH"\`
**Notes:** Awaiting setup before any server operations.
HEREDOC

# ── 04_NOTES.md ────────────────────────────────────────────────────────────────

cat > "$VAULT_DIR/04_NOTES.md" << HEREDOC
# $MACHINE — Notes

> Free-form observations, warnings, and tips.

## Setup Status

- [ ] SSH connectivity verified
- [ ] tuneladora user configured
- [ ] SSH hardened
- [ ] System discovered and context files populated
- [ ] Parent vault (06_CONTAINERS.md) updated${PARENT:+: $PARENT}
- [ ] REGISTRY.md updated
HEREDOC

# ── 05_SECURITY.md ─────────────────────────────────────────────────────────────

cat > "$VAULT_DIR/05_SECURITY.md" << HEREDOC
# $MACHINE — Security

> Last updated: $DATE (scaffolded — populate during setup)

## SSH Access

| User | Key File | Fingerprint | Restrictions | Status |
|------|----------|-------------|--------------|--------|
| tuneladora | \`~/.ssh/tuneladora\` | *(TBD)* | \`from="<subnet>"\`, no-agent-forwarding, no-X11-forwarding | Pending |
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
echo "Done. Structure created at: $REL_PATH/"
echo ""

# Print SSH config snippet based on type
case "$MACHINE_TYPE" in
  bare-metal|vm)
    echo "Add to ~/.ssh/config:"
    echo "──────────────────────────────────────────"
    echo "Host $MACHINE"
    echo "  HostName <ip-or-hostname>"
    echo "  User tuneladora"
    echo "  IdentityFile ~/.ssh/tuneladora"
    echo "──────────────────────────────────────────"
    echo ""
    echo "Next steps:"
    echo "  1. Follow ADD_MACHINE.md: configure personal SSH access"
    echo "  2. Tell Tuneladora: 'SSH ready for $MACHINE'"
    ;;
  lxc)
    echo "Add to ~/.ssh/config:"
    echo "──────────────────────────────────────────"
    echo "Host $MACHINE"
    echo "  HostName <container-ip>"
    echo "  User tuneladora"
    echo "  IdentityFile ~/.ssh/tuneladora"
    echo "  ProxyJump $PARENT"
    echo "──────────────────────────────────────────"
    echo ""
    echo "Discover container IP on parent:"
    echo "  ssh $PARENT \"pct exec <vmid> -- ip -4 addr show eth0\""
    echo ""
    echo "Next steps:"
    echo "  1. Follow ADD_CONTAINER.md: LXC setup workflow"
    echo "  2. Update HIERARCHY.md with container_id and IP"
    echo "  3. Tell Tuneladora: 'Container ready for $MACHINE'"
    ;;
  docker)
    echo "Add to ~/.ssh/config:"
    echo "──────────────────────────────────────────"
    echo "Host $MACHINE"
    echo "  HostName unused"
    echo "  ProxyCommand ssh $PARENT docker exec -i <container-name> /bin/sh"
    echo "  StrictHostKeyChecking no"
    echo "  UserKnownHostsFile /dev/null"
    echo "──────────────────────────────────────────"
    echo ""
    echo "Discover running containers on parent:"
    echo "  ssh $PARENT \"docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'\""
    echo ""
    echo "Next steps:"
    echo "  1. Follow ADD_CONTAINER.md: Docker setup workflow"
    echo "  2. Update HIERARCHY.md with container_id"
    echo "  3. Tell Tuneladora: 'Container ready for $MACHINE'"
    ;;
esac
