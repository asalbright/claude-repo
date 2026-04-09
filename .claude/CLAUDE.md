# Claude Config Repo

This is a version-controlled Claude Code configuration repository. Skills, agents, and settings are symlinked into `~/.claude/` via `install.sh` so they are globally available across all projects.

## Structure

```
settings.json          # Global config (permissions, hooks, plugins) → symlinked to ~/.claude/settings.json
skills/                # Custom slash commands → symlinked to ~/.claude/skills/
agents/                # Custom agent definitions → symlinked to ~/.claude/agents/
plugins/               # Plugin tracking (installed.txt, known_marketplaces.json)
.claude/templates/     # Scope templates for /aura.scope (project-local to this repo)
.aura/AURA.md          # Session context for working in this repo
```

## Working in This Repo

When adding or modifying skills/agents, changes take effect immediately — no restart needed (Claude Code hot-reloads `~/.claude/skills/` via the symlink).

### Skills live in `skills/<name>/SKILL.md`

Frontmatter fields:
- `name` — the slash command trigger
- `description` — shown in `/skills` list and used for agent matching
- `allowed-tools` — restrict which tools the skill can use
- `disable-model-invocation: true` — skill runs as a prompt, not a model call (use for orchestrator skills)
- `argument-hint` — shown to user when invoking

### Agents live in `agents/<name>.md`

Frontmatter fields:
- `name`, `description`, `tools`, `model`

## Install / Re-install

```bash
bash install.sh
```

Re-run after adding new symlink targets (e.g., a new top-level directory that should be linked).

## Aura Skills

The `aura.*` skills form a planning and execution workflow:

1. `/aura.vision` — Refine a raw idea into a structured vision document
2. `/aura.scope` — Research codebase, produce a scope file, create a beads epic with tasks
3. `/aura.execute <epic-id>` — Implement tasks via sub-agents with review gates
4. `/aura.graph` — Build a multi-phase task graph for large projects (10+ deliverables)
5. `/aura.rapid_dev` — Vision → beads → implementation in one pass (simple work only)
6. `/aura.init` — Initialize beads and scaffold `.aura/` for a new project
