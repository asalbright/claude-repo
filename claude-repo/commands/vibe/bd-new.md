---
description: Create a beads issue using the required Issue Shape (title, context, AC, out of scope, verification, deps).
argument-hint: [brief description of the work]
---

Create a beads issue for: $ARGUMENTS

If `$ARGUMENTS` is empty, ask the user for a one-line description before proceeding.

## Required Issue Shape

Every issue must be self-contained — an agent with no knowledge of this conversation must be able to execute it from the issue body alone.

- **Title** — imperative and scoped. "Add X to Y", "Fix Z in W", never "X stuff".
- **Context** — 1–2 sentences on why this work exists.
- **Acceptance criteria** — bulleted, concrete, verifiable outcomes. Checkable, not aspirational.
- **Out of scope** — nearby work this issue does NOT cover. Prevents scope creep.
- **Verification** — the exact command, test, or manual step that proves the change worked.
- **Dependencies** — other issue IDs that must close before this can start.

## Procedure

> If you are creating more than one issue in the current session, invoke this skill **sequentially** — never batch multiple `/vibe:bd-new` calls in a single response. The `bd` CLI holds a lock during `bd create`; concurrent calls will fail.

1. Draft the title and each section from `$ARGUMENTS` plus surrounding conversation context.
2. If any section would be empty or vague (especially AC and Verification), ask the user to clarify. Do not fabricate acceptance criteria.
3. Show the user the drafted issue and confirm before creating.
4. Create the issue using `bd create`. For single-line fields use flags; for multi-line descriptions use `--body-file -` with a heredoc to avoid shell-escape hazards:

   ```bash
   bd create \
     --title "Add retry policy to webhook handler" \
     --context "Webhook deliveries fail silently on transient upstream errors." \
     --acceptance "- Retries up to 3 times on 5xx
   - Backs off exponentially (1s, 2s, 4s)
   - Gives up and logs at level=error after the third failure" \
     --notes "## Out of scope
   retry for 4xx responses.

   ## Verification
   bun test test/webhook.retry.spec.ts" \
     --type task \
     --priority 2 \
     --silent
   ```

   Always use `## Out of scope` and `## Verification` as the exact section headers within `--notes`. The beads-worker locates the verification steps by scanning for `## Verification` in the notes field — inconsistent labels will cause it to abort.

   For dependencies, either pass `--deps "bd-abc,bd-def"` at creation time, or run `bd dep add <new-id> <blocker-id>` afterward.

5. Capture the issue ID from stdout (use `--silent` for ID-only output) and report it to the caller.

If the SessionStart status shows `beads: uninstalled` or `beads: uninitialized`, stop and resolve that first — do not proceed with issue creation.
