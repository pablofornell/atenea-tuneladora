# References

## Examples of good work

A well-maintained machine folder looks like this:

```
machines/webserver-prod/
├── CLAUDE.md                          # "Always use apt. Never restart nginx without checking config first."
├── CONTEXT.md                         # "Ubuntu 22.04 LTS, runs nginx + Node.js app, 4GB RAM"
├── REFERENCES.md                      # Links to the app's deploy docs
├── .env_webserver-prod                # Machine-specific environment variables
├── vault_webserver-prod/
│   ├── 00_INDEX.md
│   ├── 01_SYSTEM_INFO.md
│   ├── 02_SERVICES.md
│   ├── 03_TASK_LOG.md
│   └── 04_NOTES.md
└── TOOLS/
    └── deploy.sh
```

## Relevant links

- [Obsidian](https://obsidian.md) — The note-taking format used for vaults

## Notes

- Machine names should be lowercase, use hyphens for separators (e.g., `web-prod`, `db-staging`).
- Each machine's vault is independent — no cross-machine links.
