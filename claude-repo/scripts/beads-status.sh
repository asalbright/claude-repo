#!/usr/bin/env bash
set -euo pipefail

# SessionStart hook: probe the beads environment and inject a one-line status
# into Claude's session context so the model doesn't need to re-run
# `which bd` and check `.beads/` manually each session.

project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"

if ! command -v bd >/dev/null 2>&1; then
  status="uninstalled (bd CLI not found in PATH)"
elif [ ! -d "$project_dir/.beads" ]; then
  status="uninitialized (no .beads/ in $project_dir; run 'bd init' to track this repo)"
else
  status="ready"
fi

# JSON output lands in Claude's context via hookSpecificOutput.additionalContext.
# Escape the status for safe JSON embedding (double quotes + backslashes).
esc=${status//\\/\\\\}
esc=${esc//\"/\\\"}
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"beads: %s"}}\n' "$esc"
