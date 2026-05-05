#!/bin/bash
# WorktreeCreate hook for Claude Code
# Reads JSON from stdin, creates the worktree via beads, symlinks .env files, prints path to stdout.

set -euo pipefail

INPUT=$(cat)
NAME=$(printf '%s' "$INPUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["name"])')
PROJECT_DIR=$(printf '%s' "$INPUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["cwd"])')

# NAME may be a bare label, a relative path, or an absolute path — honor whatever the user passed.
if [[ "$NAME" = /* ]]; then
  WORKTREE_PATH="$NAME"
else
  WORKTREE_PATH="$PROJECT_DIR/$NAME"
fi
BRANCH_NAME="worktree-$(basename "$NAME")"

# Route logging to the user's terminal when available, else stderr.
# stdout is reserved for the worktree path — anything else breaks Claude Code.
if { : >/dev/tty; } 2>/dev/null; then
  exec 3>/dev/tty
else
  exec 3>&2
fi

# Create the worktree via bd so it shares the main repo's beads database
(cd "$PROJECT_DIR" && bd worktree create "$WORKTREE_PATH" --branch "$BRANCH_NAME") >&3 2>&3

# Symlink any .env files from the main repo
for env_file in "$PROJECT_DIR"/.env; do
  [ -e "$env_file" ] || continue
  filename=$(basename "$env_file")
  ln -sf "$env_file" "$WORKTREE_PATH/$filename"
  echo "Symlinked $filename" >&3
done

# stdout must be ONLY the worktree path — Claude reads this
echo "$WORKTREE_PATH"
