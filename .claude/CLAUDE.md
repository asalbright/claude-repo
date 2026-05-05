# Project Instructions for AI Agents

This file describes **this repo** (the Claude config source of truth). For the personal workflow rules that get symlinked into `~/.claude/CLAUDE.md`, see `claude-repo/CLAUDE.md`.

## What this repo is

Version-controlled Claude Code configuration. The `claude-repo/` subdirectory mirrors the layout of `~/.claude/` — `install.sh` symlinks each entry into place so edits here apply instantly.

## Layout

```
.
├── install.sh             # Symlinks claude-repo/* into ~/.claude/
├── README.md
├── CLAUDE.md              # This file — instructions for agents editing this repo
└── claude-repo/           # The actual config; mirrors ~/.claude/
    ├── CLAUDE.md          # Symlinked to ~/.claude/CLAUDE.md (global workflow rules)
    ├── settings.json      # Symlinked to ~/.claude/settings.json
    ├── agents/            # Symlinked to ~/.claude/agents/
    ├── commands/          # Symlinked to ~/.claude/commands/
    ├── hooks/             # Symlinked to ~/.claude/hooks/
    ├── scripts/           # Symlinked to ~/.claude/scripts/
    └── skills/            # Symlinked to ~/.claude/skills/
```

## Editing rules

- Anything that should land in `~/.claude/` goes under `claude-repo/`, never at the repo root.
- `settings.json` hook commands reference paths under `~/.claude/scripts/` or `~/.claude/hooks/`, which resolve through the symlink — so scripts and hooks must stay inside `claude-repo/scripts/` and `claude-repo/hooks/` respectively.
- Plugins are declared via `enabledPlugins` in `claude-repo/settings.json`. Do NOT reintroduce `plugins/installed.txt`.
- After changing the layout of `claude-repo/`, update `install.sh`, `CLAUDE.md` and `README.md` in the same commit.

## Install / re-install

```bash
bash install.sh
```

Idempotent: existing non-symlink files are backed up to `*.bak`, stale symlinks are replaced.
