#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Setting up Claude config symlinks from: $REPO_DIR"

# Backup a real file/dir and replace with symlink
link() {
    local src="$REPO_DIR/$1"
    local dst="$CLAUDE_DIR/${2:-$1}"

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
link "skills"
link "plugins/known_marketplaces.json"

echo ""
echo "Done. Run 'git -C $REPO_DIR remote add origin <url>' to connect to a remote."
