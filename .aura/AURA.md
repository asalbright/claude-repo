# Aura Context — Claude Config Repo

This is a version-controlled Claude Code configuration repository. Skills, agents, and settings are symlinked into `~/.claude/` via `install.sh`.

## Working Here

Changes to files in `skills/`, `agents/`, and `settings.json` apply immediately via the symlinks — no restart needed.

To install or re-link:
```bash
bash install.sh
```

## Beads (Issue Tracking)

Use **bd** to track any improvements or additions to this repo.

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
```

Run `bd prime` to load context, or `/aura.init` to initialize beads for the first time.
