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
link "agents"
link "plugins/known_marketplaces.json"
link ".CLAUDE.md" "CLAUDE.md"

echo ""
echo "Done."
echo ""

# Print plugin install instructions if list exists
PLUGINS_FILE="$REPO_DIR/plugins/installed.txt"
if [[ -f "$PLUGINS_FILE" ]]; then
    plugins=$(grep -v '^\s*#' "$PLUGINS_FILE" | grep -v '^\s*$')
    if [[ -n "$plugins" ]]; then
        echo "Plugins to install — run these in Claude Code:"
        while IFS= read -r plugin; do
            echo "  /plugin install $plugin"
        done <<< "$plugins"
        echo ""
    fi
fi
