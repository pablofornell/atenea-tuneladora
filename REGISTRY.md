# Tuneladora — Machine Registry

> This file shows the full hierarchy of all managed machines.
> Update it whenever a machine is added, removed, or re-parented.
> Authoritative source for each node: `machines/<name>/HIERARCHY.md`.

## Hierarchy Tree

```
hef-minipc-proxmox  [bare-metal]  — Proxmox VE production hypervisor
└── hef-pam         [vm]          — Ubuntu 24.04, OpenClaw AI gateway
```

## Machine Index

| Machine | Type | Parent | Connection | Status | Notes |
|---------|------|--------|------------|--------|-------|
| hef-minipc-proxmox | bare-metal | — | direct | ⚠️ migration pending | Root node. tuneladora user not yet configured. |
| hef-pam | vm | hef-minipc-proxmox | direct | ✅ operational | 192.168.1.63. OpenClaw gateway. |

## Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Fully operational under Tuneladora model |
| ⚠️ | Partially set up — see machine's CLAUDE.md for blockers |
| 🔴 | Decommissioned or unreachable |

## Connection Model Reference

| Model | Used by | SSH config pattern |
|-------|---------|--------------------|
| `direct` | bare-metal, vm | Standard `Host` entry with `HostName` and `IdentityFile` |
| `proxyjump` | lxc | Standard `Host` entry with `ProxyJump <parent>` |
| `docker-exec` | docker | `Host` entry with `ProxyCommand ssh <parent> docker exec -i <container> /bin/sh` |
