---
description: Express Mode — autonomously plan, file small beads, and execute them (via subagents when parallel helps). For small-to-medium tasks without prior planning.
argument-hint: [task description]
---

# Express Mode

Target: $ARGUMENTS

Autonomous end-to-end: plan briefly, file beads (maybe), execute. No stopping for approval mid-flow unless something blocks you.

## 0. Preflight

- If `$ARGUMENTS` is empty, ask the user for a one-line task description.
- Check SessionStart status. If not `beads: ready`, ask the user to install/initialize. Do not proceed until resolved.

## 1. Triage: trivial, quick, or too big?

Classify the task:

- **Trivial** (skip beads entirely): single-file edit under ~10 lines, typo/comment fix, one-line debug tweak, read-only investigation. → Go to step 4 (execute inline, no issues). You are permitted to write code.
- **Express-sized** (1–3 subtasks): proceed with this mode. You are no longer permitted to write code — you MUST file beads and dispatch to `beads-worker` subagents for execution.
- **Too big** (> 3 subtasks, multi-layer refactor, or cross-team dependencies): stop and tell the user `/vibe:engineer` is the right mode instead. Ask for confirmation before continuing under `/vibe:express`.

## 2. Light planning (no heavyweight hierarchy)

Break the task into 1–3 subtasks. Do NOT build an Epic > Story > Task > Subtask tree — that's Engineer Mode's job. A flat list is fine.

Predict the file scope for each subtask (same logic as `/vibe:execute` step 4). This informs whether execution can parallelize.

## 3. File beads

For each subtask, create a beads issue via `/vibe:bd-new` (or `bd create` directly if in a subagent context), **one at a time** — do NOT batch multiple creation calls into a single response, as the `bd` CLI lock will cause concurrent `bd create` invocations to fail. Parallelism happens in step 4 (execution), not here.

Every issue must ship with the full Issue Shape — title, context, AC, out-of-scope, verification. Link dependencies between subtasks with `--deps` or `bd dep add`; disjoint subtasks (no `--deps`) will be executed in parallel in step 4.

## 4. Execute

**Trivial path:** do the work with Edit/Write directly. Run any obvious verification (compile, test, the specific behavior the user asked about). Then commit the changed files directly:

   ```bash
   git commit path/to/file1 path/to/file2 -m "$(cat <<'EOF'
   <one-line description of what changed>
   EOF
   )"
   ```

   Do NOT push. Report what changed and note "tracking skipped — trivial work."

**Non-trivial path:** execute the beads as follows:

- If subtasks have disjoint file scopes AND there are 2–3 of them → dispatch them in parallel via `beads-worker` subagents (single response message with multiple Agent tool calls).
- If subtasks share file scopes, are cross-cutting, or there's only one → run them serially. Dispatch `beads-worker` subagents serially.
- Respect dependency order: don't start a subtask whose blockers are open.

## 5. Collect or generate report(s)

**Trivial path:** report back the change you made, any verification you ran, and that no beads were created.

**Non-trivial path:** collect the reports from each subtask. If you dispatched to `beads-worker` subagents, their final report should include what they did, assumptions made, beads IDs created, and any surprises. Summarize these into a concise report for the user (see next step).

## 6. Report

Concise summary to the user:

```text
/vibe:express summary
──────────────────────
Task: <original request>
Subtasks: N (closed: X, failed: Y)
Execution: <N subagents serial | N subagents parallel>
Commits: <list of commits made>
Follow-ups via Discovery Rule: bd-51, bd-52
```

If any subtask failed, surface what went wrong and what you'd suggest as next steps — don't just leave it dangling.
