# Current Project

## What we are building

Tuneladora — an SSH connection hub operated by an LLM to manage multiple remote servers. The LLM connects via SSH, executes tasks, and maintains persistent memory of each machine through Obsidian-compatible vaults.

## What good looks like

- Every task leaves a clear trail in the machine's vault.
- Credentials are never exposed in logs, output, or conversation.
- The LLM reads context before acting and updates context after acting.
- Machine folders are self-contained: everything needed to operate a machine lives in its folder.

## What to avoid

- Hardcoding or displaying SSH credentials in output.
- Acting on a machine without reading its context first.
- Forgetting to update the vault after a task.
- Making destructive changes without explicit user confirmation.
- Assuming machine state without verifying.
