# Claude Config Repo

Version-controlled Claude Code configuration: settings, skills, agents, and plugins — symlinked into `~/.claude/` so changes here apply instantly.

## What's Included

| Path | Purpose |
|------|---------|
| `settings.json` | Global permissions, hooks, and Claude Code preferences |
| `skills/` | Custom slash commands (`/commit`, `/review`, `/aura.*`, etc.) |
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
| `/aura.scope` | Scope a feature or chore into a beads epic |
| `/aura.execute` | Implement beads tasks from an epic using sub-agents with review gates |
| `/aura.graph` | Visualize task dependency graph for an epic |
| `/aura.vision` | Generate a visual overview of a system or feature |
| `/aura.rapid_dev` | Rapid prototyping workflow |
| `/aura.init` | Initialize beads issue tracking and scaffold `.aura/` for a project |
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

## Beads (Issue Tracking)

The aura skills (`/aura.scope`, `/aura.execute`, etc.) use **bd** (beads) for task tracking. Beads is a local-first issue tracker — no server, just a SQLite database next to your code.

### How it works

Each session, the `SessionStart` hook runs `bd prime` to load the project's bead graph into Claude's context. If beads isn't initialized, you'll see:

```
Beads not initialized. Run /aura.init to set up issue tracking for this project.
```

### Initializing a project

Run `/aura.init` once per project. It will ask you to choose a mode:

| Mode | Where `.beads/` lives | Survives reboot? | Best for |
|------|-----------------------|-----------------|----------|
| **Local/persistent** | `<project>/.beads/` | Yes | Local macOS/Linux dev |
| **Ephemeral** | `/tmp/.beads/` | No | Docker containers |

`/aura.init` also scaffolds:
- `.aura/AURA.md` — project context loaded at each session start
- `.aura/visions/queue/` — drop `.txt` files here for `/aura.vision`
- `.aura/setup.sh` — (ephemeral mode only) run before each container session
- `.claude/templates/` — scope templates for `/aura.scope` (feature, chore, epic, bug)

### Common bd commands

```bash
bd ready                              # Find available work
bd show <id>                          # View issue details
bd update <id> --status in_progress   # Claim work
bd close <id>                         # Complete work
bd sync                               # Sync with git
```

### Templates

`/aura.scope` uses `.claude/templates/` to structure scope files. These are **project-local** — each project that uses scoping needs its own templates. `/aura.init` will offer to create them. If missing, `/aura.scope` falls back to built-in structure.

## Settings

`settings.json` controls global Claude Code behavior:

- **Permissions** — pre-approved and denied shell commands (avoids confirmation prompts for safe ops like `mkdir`, `uv`, `ls`)
- **Hooks** — `SessionStart` hooks prime the beads task system and load project context at the start of each session

To modify permissions or hooks, edit `settings.json` in this repo — the symlink means the change takes effect immediately.
