---
name: aura.init
description: Initialize beads issue tracking and scaffold the .aura/ project structure
allowed-tools: Bash, Read, Write, Glob
---

# Aura Init

Set up beads (bd) issue tracking and create the `.aura/` scaffold for a project. Run this once when starting work in a new project.

## Phase 1: Check Prerequisites

1. **Check if bd is installed:**
   ```bash
   which bd
   ```
   If not found: report "bd not installed. Install beads to use issue tracking." and stop.

2. **Check if beads is already initialized:**
   ```bash
   ls .beads/beads.db 2>/dev/null && echo "EXISTS" || echo "NOT_FOUND"
   ```
   Also check the ephemeral path:
   ```bash
   ls /tmp/.beads/beads.db 2>/dev/null && echo "EXISTS" || echo "NOT_FOUND"
   ```

   If already initialized (either path): report which mode is active and ask if the user wants to continue with existing state or reset. If reset, delete `.beads/` or `/tmp/.beads/` accordingly and continue. If continue, skip to Phase 3.

## Phase 2: Choose Mode

Present two options clearly and ask the user to choose:

**A) Local / persistent**
- `.beads/` lives in the project root alongside the code
- Survives restarts, available across sessions
- Best for local development (macOS, Linux workstations)
- Optionally added to `.gitignore`

**B) Ephemeral**
- `.beads/` lives in `/tmp/.beads/`
- Wiped on reboot / container restart
- Best for Docker dev containers where you don't want bead state persisting to the host
- Requires running `.aura/setup.sh` at the start of each session

Ask: "How would you like to initialize beads for this project? (A) local/persistent or (B) ephemeral"

## Phase 3: Initialize Beads

### If local/persistent:

```bash
bd init --skip-hooks --skip-merge-driver --quiet
```

Then check `.gitignore`:
```bash
cat .gitignore 2>/dev/null | grep -q "\.beads" && echo "ALREADY_IGNORED" || echo "NOT_IGNORED"
```

If `.beads/` is not already gitignored, ask: "Add .beads/ to .gitignore? (recommended — keeps bead state out of git)"

If yes, append to `.gitignore`:
```bash
echo "" >> .gitignore
echo "# Beads issue tracking database" >> .gitignore
echo ".beads/" >> .gitignore
```

### If ephemeral:

Write `.aura/setup.sh`:

```bash
#!/usr/bin/env bash
# Ephemeral beads setup. Run at the start of each container session.
# Wipes any prior beads state and creates a fresh, local-only instance.

set -euo pipefail

export BEADS_DIR=/tmp/.beads

if [ -f "$BEADS_DIR/beads.db" ] && [ -s "$BEADS_DIR/beads.db" ]; then
    if [ -n "${CI:-}" ] || [ -n "${BEADS_FORCE_WIPE:-}" ]; then
        echo "CI: wiping existing beads session"
    else
        echo "WARNING: Existing beads session found at $BEADS_DIR."
        printf "Wipe it and start fresh? [y/N] "
        read -r response
        if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
            echo "Aborted. Save your work first, then restart."
            exit 1
        fi
    fi
fi

rm -rf "$BEADS_DIR"
(cd /tmp && bd init --skip-hooks --skip-merge-driver --quiet)

cat > "$BEADS_DIR/config.yaml" << 'YAML'
no-daemon: true
no-auto-flush: true
no-auto-import: true
YAML

echo "beads ready (ephemeral)"
```

Make it executable:
```bash
chmod +x .aura/setup.sh
```

Then run it to initialize the first session:
```bash
bash .aura/setup.sh
```

## Phase 4: Scaffold .aura/

Create `.aura/AURA.md` if it doesn't already exist:

```markdown
# Aura Context

<Describe this project in 2-3 sentences: what it does and why it exists.>

## Beads (Issue Tracking)

This project uses **bd** (beads) for issue tracking. Common commands:

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

Run `bd prime` to load context at the start of each session.
```

Create the vision queue directories:
```bash
mkdir -p .aura/visions/queue .aura/visions/processed .aura/plans/queue
touch .aura/visions/queue/.gitkeep .aura/visions/processed/.gitkeep .aura/plans/queue/.gitkeep
```

## Phase 5: Scaffold .claude/templates/

Check if `.claude/templates/` already exists:
```bash
ls .claude/templates/ 2>/dev/null && echo "EXISTS" || echo "NOT_FOUND"
```

If it doesn't exist, ask: "Add standard scope templates to .claude/templates/? These are needed for /aura.scope to plan features and chores."

If yes, create the templates directory and write the four standard templates:

**`.claude/templates/feature.md`** — feature scope template
**`.claude/templates/chore.md`** — chore/refactor scope template
**`.claude/templates/epic.md`** — multi-feature epic template
**`.claude/templates/bug.md`** — bug investigation template

Write these with full placeholder content using the standard structure:
- Feature: Description, Problem/Solution, Research Findings, Relevant Files, Implementation Plan, Verification, Acceptance Criteria
- Chore: Description, Current/Desired State, Relevant Files, Implementation Plan, Verification, Acceptance Criteria
- Epic: Overview, Vision Context, Specs, Execution Order, Path Dependencies, Implementation Notes, Success Metrics
- Bug: Description, Reproduction Steps, Expected/Actual Behavior, Root Cause, Tasks, Acceptance Criteria

## Phase 6: Report

```
## Aura Init Complete

**Mode:** local/persistent | ephemeral
**Beads:** .beads/ initialized | .aura/setup.sh created (run before each session)

**Created:**
- .aura/AURA.md — edit this to describe your project
- .aura/visions/queue/ — drop .txt vision files here for /aura.vision
- .aura/plans/queue/ — scope files written here by /aura.scope
[- .aura/setup.sh — run at the start of each container session]
[- .claude/templates/ — 4 templates for /aura.scope]

**Next steps:**
1. Edit .aura/AURA.md to describe this project
2. Run /aura.scope "<describe your feature>" to start planning work
3. Run /aura.execute <epic-id> to implement
```
