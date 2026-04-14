# Tuneladora — Machine Registry

> This file shows the full hierarchy of all managed machines.
> Update it whenever a machine is added, removed, or re-parented.
> Authoritative source for each node: `<machine-folder>/HIERARCHY.md`.

## Hierarchy Tree

```
hef-minipc-proxmox  [bare-metal]  — Proxmox VE production hypervisor
└── VMs/
    └── hef-pam     [vm/VMID 100] — Ubuntu 24.04, Ollama LLM inference
```

## Machine Index

| Machine | Type | Parent | Connection | Folder Path | Status | Notes |
|---------|------|--------|------------|-------------|--------|-------|
| hef-minipc-proxmox | bare-metal | — | direct | `machines/hef-minipc-proxmox/` | ⚠️ migration pending | Root node. tuneladora user not yet configured. Accessed as root (legacy). |
| hef-pam | vm (VMID 100) | hef-minipc-proxmox | direct | `machines/hef-minipc-proxmox/VMs/hef-pam/` | ✅ operational | 192.168.1.63. Ollama v0.17.7 (qwen3.5:4b, qwen2.5:7b). OpenClaw inactive. Kernel 6.17.0-20. |

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

## Folder Convention

| Type | Folder path |
|------|-------------|
| bare-metal | `machines/<name>/` |
| vm | `machines/<host>/VMs/<name>/` |
| lxc | `machines/<host>/CTs/LXC/<name>/` |
| docker | `machines/<host>/CTs/Docker/<name>/` |
