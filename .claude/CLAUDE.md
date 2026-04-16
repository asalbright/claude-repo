# Claude Config Repo

This is a version-controlled Claude Code configuration repository. Skills and settings are symlinked into `~/.claude/` via `install.sh` so they are globally available across all projects.

## Structure

```
settings.json          # Global config (permissions, hooks, plugins) → symlinked to ~/.claude/settings.json
skills/                # Custom slash commands → symlinked to ~/.claude/skills/
plugins/               # Plugin tracking (installed.txt, known_marketplaces.json)
```

## Working in This Repo

When adding or modifying skills, changes take effect immediately — no restart needed (Claude Code hot-reloads `~/.claude/skills/` via the symlink).

### Skills live in `skills/<name>/SKILL.md`

Frontmatter fields:
- `name` — the slash command trigger
- `description` — shown in `/skills` list and used for agent matching
- `allowed-tools` — restrict which tools the skill can use
- `disable-model-invocation: true` — skill runs as a prompt, not a model call (use for orchestrator skills)
- `argument-hint` — shown to user when invoking

## Install / Re-install

```bash
bash install.sh
```

Re-run after adding new symlink targets (e.g., a new top-level directory that should be linked).

