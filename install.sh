#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$REPO_DIR/claude-repo"
CLAUDE_DIR="$HOME/.claude"

echo "Setting up Claude config symlinks from: $SRC_DIR"

# Backup a real file/dir and replace with symlink
link() {
    local src="$SRC_DIR/$1"
    local dst="$CLAUDE_DIR/${2:-$1}"

    if [[ ! -e "$src" ]]; then
        echo "  Skipping (missing source): $src"
        return
    fi

    # Backup existing real file/dir (skip if already a symlink)
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        echo "  Backing up: $dst -> ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi

    # Remove stale symlink
    [[ -L "$dst" ]] && rm "$dst"

    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    echo "  Linked: $dst -> $src"
}

link "settings.json"
link "CLAUDE.md"
link "skills"
link "agents"
link "commands"
link "scripts"
link "hooks"

echo ""
echo "Done."
