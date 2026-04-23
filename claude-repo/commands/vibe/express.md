---
description: Express Mode — autonomously plan, file small beads, and execute them (via subagents when parallel helps). For small-to-medium tasks without prior planning.
argument-hint: [task description]
---

# Express Mode

Target: $ARGUMENTS

Autonomous end-to-end: plan briefly, file beads, execute. No stopping for approval mid-flow unless something blocks you.

## 0. Preflight

- If `$ARGUMENTS` is empty, ask the user for a one-line task description.
- Check SessionStart status. If not `beads: ready`, ask the user to install/initialize. Do not proceed until resolved.

## 1. Triage: trivial, quick, or too big?

Classify the task:

- **Trivial** (skip beads entirely): single-file edit under ~10 lines, typo/comment fix, one-line debug tweak, read-only investigation. → Go to step 4 (execute inline, no issues).
- **Express-sized** (1–3 subtasks): proceed with this mode.
- **Too big** (> 3 subtasks, multi-layer refactor, or cross-team dependencies): stop and tell the user `/vibe:engineer` is the right mode instead. Ask for confirmation before continuing under `/vibe:express`.

## 2. Light planning (no heavyweight hierarchy)

Break the task into 1–3 subtasks. Do NOT build an Epic > Story > Task > Subtask tree — that's Engineer Mode's job. A flat list is fine.

Predict the file scope for each subtask (same logic as `/vibe:execute` step 4). This informs whether execution can parallelize.

## 3. File beads

For each subtask, create a beads issue via `/vibe:bd-new` (or `bd create` directly if in a subagent context), **one at a time** — do NOT batch multiple creation calls into a single response, as the `bd` CLI lock will cause concurrent `bd create` invocations to fail. Parallelism happens in step 4 (execution), not here.

Every issue must ship with the full Issue Shape — title, context, AC, out-of-scope, verification. Link dependencies between subtasks with `--deps` or `bd dep add`; disjoint subtasks (no `--deps`) will be executed in parallel in step 4.

Skip this step if step 1 classified the task as trivial.

## 4. Execute

**Trivial path:** just do the work with Edit/Write directly. Run any obvious verification (compile, test, the specific behavior the user asked about). Then commit the changed files directly:

   ```bash
   git commit path/to/file1 path/to/file2 -m "$(cat <<'EOF'
   <one-line description of what changed>
   EOF
   )"
   ```

   Do NOT push. Report what changed and note "tracking skipped — trivial work."

**Non-trivial path:** execute using the same machinery as `/vibe:execute`:

- If subtasks have disjoint file scopes AND there are 2–3 of them → dispatch them in parallel via `beads-worker` subagents (single response message with multiple Agent tool calls).
- If subtasks share file scopes, are cross-cutting, or there's only one → run them serially. You can execute serial subtasks inline (as the main agent) if they're small, or dispatch a `beads-worker` if they're substantial enough to benefit from tool-scope isolation.
- Respect dependency order: don't start a subtask whose blockers are open.

## 5. Verify and close

For each non-trivial subtask, run the issue's Verification steps and close with `bd close <id> --reason "AC verified: <one-line>"`. Handle failures per `/vibe:execute` policy: continue with the remaining subtasks and report failures at the end.

## 6. Report

Concise summary to the user:

```text
/vibe:express summary
──────────────────────
Task: <original request>
Subtasks: N (closed: X, failed: Y)
Execution: <inline | N subagents serial | N subagents parallel>
Follow-ups via Discovery Rule: bd-51, bd-52
```

If any subtask failed, surface what went wrong and what you'd suggest as next steps — don't just leave it dangling.
