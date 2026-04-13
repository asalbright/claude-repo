# Claude Config Repo

Version-controlled Claude Code configuration: settings, skills, agents, and plugins — symlinked into `~/.claude/` so changes here apply instantly.

## What's Included

| Path | Purpose |
|------|---------|
| `settings.json` | Global permissions, hooks, and Claude Code preferences |
| `skills/` | Custom slash commands (`/commit`, `/review`, etc.) |
| `agents/` | Custom agent definitions (e.g., `researcher`) |
| `plugins/installed.txt` | Canonical list of plugins to install |

## Install

```bash
git clone <this-repo> ~/Documents/claude-repo
cd ~/Documents/claude-repo
bash install.sh
```

The script backs up any existing `~/.claude` files and replaces them with symlinks into this repo. Run it again after pulling to pick up new entries.

### Plugins

After running `install.sh`, the script prints the plugins you need to install. Run each one inside Claude Code:

```
/plugin install commit-commands@claude-plugins-official
```

To add a plugin to the canonical list so others pick it up:

1. Add the plugin name to `plugins/installed.txt`
2. Commit and push
3. Anyone who pulls and re-runs `install.sh` will see the install prompt

## Usage

### Skills (slash commands)

Skills live in `skills/` and are immediately available as `/skill-name` in Claude Code.

| Skill | Description |
|-------|-------------|
| `/commit` | Create a well-formatted conventional commit |
| `/review` | Review recent changes for quality, security, and style issues |
| `/confluence.read` | Read a Confluence page |
| `/confluence.upload` | Upload markdown to Confluence |

### Agents

Custom agents live in `agents/` and are available to Claude Code sub-agent spawning.

| Agent | Description |
|-------|-------------|
| `researcher` | Deep codebase research — traces data flow, maps dependencies, returns file-referenced summaries |

### Adding a Skill

1. Create `skills/<name>/SKILL.md` with a frontmatter header and prompt body:

```markdown
---
name: my-skill
description: What this skill does
---

Instructions for the skill...
```

2. It's immediately available as `/my-skill` — no restart needed.

### Adding an Agent

Create `agents/<name>.md` with frontmatter:

```markdown
---
name: my-agent
description: When to use this agent
tools: Read, Grep, Glob, Bash
model: sonnet
---

System prompt for the agent...
```

## Settings

`settings.json` controls global Claude Code behavior:

- **Permissions** — pre-approved and denied shell commands (avoids confirmation prompts for safe ops like `mkdir`, `uv`, `ls`)

To modify permissions or hooks, edit `settings.json` in this repo — the symlink means the change takes effect immediately.
