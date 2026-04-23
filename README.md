# Claude Config Repo

Version-controlled Claude Code configuration: global `CLAUDE.md`, `settings.json`, agents, commands, scripts, and skills — symlinked into `~/.claude/` so changes here apply instantly.

## Layout

Everything that installs into `~/.claude/` lives under the `claude-repo/` subdirectory, mirroring the target layout:

| Source | Symlinked to |
|--------|--------------|
| `claude-repo/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `claude-repo/settings.json` | `~/.claude/settings.json` |
| `claude-repo/agents/` | `~/.claude/agents/` |
| `claude-repo/commands/` | `~/.claude/commands/` |
| `claude-repo/scripts/` | `~/.claude/scripts/` |
| `claude-repo/skills/` | `~/.claude/skills/` |

The top-level `CLAUDE.md` and `README.md` document the repo itself and are **not** linked into `~/.claude/`.

## Install

```bash
git clone <this-repo> ~/Documents/Github/claude-repo
cd ~/Documents/Github/claude-repo
bash install.sh
```

`install.sh` backs up any existing real files at the target paths to `*.bak` and replaces them with symlinks into this repo. It's safe to re-run after pulling to pick up new entries.

## Plugins

Plugins are declared inline in `claude-repo/settings.json` under `enabledPlugins` and `extraKnownMarketplaces`. Add a plugin by editing that file and committing — no separate install step.

## Adding things

### A skill

Create `claude-repo/skills/<name>/SKILL.md` with frontmatter:

```markdown
---
name: my-skill
description: What this skill does
---

Instructions for the skill...
```

Available as `/my-skill` immediately — no restart.

### An agent

Create `claude-repo/agents/<name>.md` with frontmatter:

```markdown
---
name: my-agent
description: When to use this agent
tools: Read, Grep, Glob, Bash
model: sonnet
---

System prompt for the agent...
```

### A slash command

Drop a markdown file into `claude-repo/commands/` (or a namespaced subdirectory like `commands/vibe/`). The path becomes the command name (e.g. `commands/vibe/execute.md` → `/vibe:execute`).

### A hook script

Add the script to `claude-repo/scripts/` and reference it from `claude-repo/settings.json` as `~/.claude/scripts/<name>` — the symlink resolves the path at runtime.

## Settings

`claude-repo/settings.json` controls global Claude Code behavior: permissions, hooks, model, and enabled plugins. Because it's symlinked, edits take effect immediately.
