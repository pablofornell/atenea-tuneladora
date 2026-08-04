# Add Container — Workflow

This document describes the 4-phase workflow for adding an **LXC container** or **Docker container** as a child machine in Tuneladora. It complements `ADD_MACHINE.md`, which covers bare-metal and VM setup.

**Prerequisites:**
- The parent machine must already exist and be fully operational (SSH working, tuneladora user configured). Bare-metal hosts live at `machines/<host>/`, VMs at `machines/<grandparent>/VMs/<host>/`.
- For LXC: the container must already exist in Proxmox (`pct list` on the parent to verify).
- For Docker: the container must already be running (`docker ps` on the parent to verify).

---

## Phase A — Scaffolding (LLM)

1. **Run `tools/new_machine.sh`** with the appropriate type and parent:

   ```bash
   # For LXC containers — creates machines/<parent>/CTs/LXC/<container-name>/
   tools/new_machine.sh <container-name> --type lxc --parent <parent-name>

   # For Docker containers — creates machines/<parent>/CTs/Docker/<container-name>/
   tools/new_machine.sh <container-name> --type docker --parent <parent-name>
   ```

2. The script creates the canonical folder structure under the correct subfolder and prints the **SSH config snippet** to add to `~/.ssh/config`.

3. **Do not add the SSH config snippet yet** — wait until Phase B confirms the container's IP / name.

---

## Phase B — Discover the Container (LLM)

Connect to the parent and identify the container.

### For LXC containers

```bash
# List all LXC containers
ssh <parent-name> "pct list"

# Get the container's IP address
ssh <parent-name> "pct exec <vmid> -- ip -4 addr show eth0 | grep inet"

# Check if SSH is running inside the container
ssh <parent-name> "pct exec <vmid> -- systemctl is-active ssh"
```

Record the **VMID** and **container IP** — these go into `HIERARCHY.md`.

### For Docker containers

```bash
# List running containers
ssh <parent-name> "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'"

# Inspect a specific container (network, environment)
ssh <parent-name> "docker inspect <container-name> --format '{{json .NetworkSettings.Networks}}'"
```

Record the **container name or ID** — this goes into `HIERARCHY.md`.

---

## Phase C — Configure Access (LLM for LXC, Human for Docker)

### For LXC containers

The agent handles the full setup autonomously via `pct exec` on the parent — no human action needed. The parent already has `tuneladora` with `sudo`, so the agent can run all commands directly.

**Step C1 — Generate the SSH key (agent, locally):**
```bash
bash tools/setup_tuneladora_control.sh --machine <container-name> --lxc --vmid <vmid>
```
This generates `~/.ssh/tuneladora_<container-name>` and prints the command to run on the parent.

**Step C2 — Bootstrap the container (agent, via SSH to parent):**
```bash
scp tools/setup_tuneladora_target.sh <parent-name>:/tmp/

ssh <parent-name> "bash /tmp/setup_tuneladora_target.sh \
  --pubkey '$(cat ~/.ssh/tuneladora_<container-name>.pub)' \
  --lxc --vmid <vmid>"
```

This single command: creates the `tuneladora` user inside the container, configures passwordless sudo, sets up `~/.ssh/`, installs the public key, installs `openssh-server` if missing, and locks the password.

**Step C3 — Add SSH config snippet (agent):**

Add the snippet printed by Phase A to `~/.ssh/config` so the container is reachable as `<container-name>` via `ProxyJump`.

### For Docker containers

Docker containers use `ProxyCommand + docker exec` — no SSH daemon or credentials needed inside the container.

**Step C1 — Verify shell access (Human):**
```bash
# Add the SSH config snippet from Phase A to ~/.ssh/config, then test:
ssh <container-name> "whoami"
```

The ProxyCommand routes the connection through `docker exec -i <container-name> /bin/sh` on the parent. If the container has `/bin/bash`, update the ProxyCommand accordingly.

**Step C2 — Verify the container has the expected tools (LLM):**
```bash
ssh <container-name> "which bash python3 curl 2>/dev/null || true"
```

> Note: Docker containers accessed via `docker exec` do not use the `tuneladora` user model. Commands run as the container's default user (typically `root` in server images). Document the actual user in `HIERARCHY.md` under Notes.

---

## Phase D — Finalize (LLM)

Once access is confirmed:

> **Multi-agent note:** Step 1 is sequential (needs Phase B data). Steps 2 and 3 are independent and run as parallel Haiku sub-agents. Steps 4 and 5 are sequential after 2 and 3 complete. See CLAUDE.md for orchestration details.

1. **[SEQUENTIAL]** **Update `HIERARCHY.md`** with the real container_id and any connectivity notes:
   ```markdown
   container_id: 101   # (LXC VMID) or my-app-container (Docker)
   ```

2. **[PARALLEL]** **Populate `CONTEXT.md`** and vault notes via discovery:
   ```bash
   # For LXC (standard SSH):
   ssh <container-name> "uname -a && cat /etc/os-release && df -h && free -h && ip -4 addr show scope global"

   # For Docker (via docker exec):
   ssh <container-name> "uname -a 2>/dev/null; cat /etc/os-release 2>/dev/null; df -h 2>/dev/null"
   ```

3. **[PARALLEL]** **Harden SSH for LXC** — discover the subnet from the operator's current network, then apply:
   ```bash
   SUBNET=$(ip -4 addr show scope global | awk '/inet / {split($2,a,"."); print a[1]"."a[2]"."a[3]".*"}' | head -1)
   PUBKEY=$(cat ~/.ssh/tuneladora_<container-name>.pub)
   ssh <container-name> "echo 'from=\"$SUBNET\",no-agent-forwarding,no-X11-forwarding $PUBKEY' > ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
   ssh <container-name> "sudo passwd -l tuneladora"
   ```
   Test: `ssh -o ConnectTimeout=5 <container-name> "whoami"` → expects `tuneladora`.

4. **[SEQUENTIAL — after 2 and 3]** **Update the parent's vault** — add the container to `06_CONTAINERS.md` in the parent's vault:
   ```markdown
   | <container-name> | lxc | 101 | 192.168.0.X (or the actual subnet) | ProxyJump | running | machines/<host>/CTs/LXC/<container-name> |
   ```

5. **[SEQUENTIAL — after 2 and 3]** **Log the setup** in both `<container-folder>/vault/03_TASK_LOG.md` and the parent's `vault/03_TASK_LOG.md`.

---

## Quick Reference: Connection Models

| Type | SSH Config Pattern | Notes |
|------|-------------------|-------|
| `lxc` | `ProxyJump <parent>` | Standard SSH through parent as jump host |
| `docker` | `ProxyCommand ssh <parent> docker exec -i <container> /bin/sh` | No SSH daemon needed inside container |

## Quick Reference: Which ADD_ doc to use

| Machine kind | Workflow |
|-------------|---------|
| Physical server or bare-metal | `ADD_MACHINE.md` |
| VM (KVM/QEMU) | `ADD_MACHINE.md` |
| LXC container | `ADD_CONTAINER.md` (this file) |
| Docker container | `ADD_CONTAINER.md` (this file) |
