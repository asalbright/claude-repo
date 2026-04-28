---
description: Express Mode — autonomously plan, file small beads, and execute them (via subagents when parallel helps). For small-to-medium tasks without prior planning.
argument-hint: [task description]
---

*Principles: 1, 2, 3, 4 all apply (most coding-heavy mode). See CLAUDE.md § First Principles.*

# Express Mode

Target: $ARGUMENTS

Autonomous end-to-end: plan briefly, file beads (maybe), execute. No stopping for approval mid-flow unless something blocks you.

## 0. Preflight

- If `$ARGUMENTS` is empty, ask the user for a one-line task description.
- Check SessionStart status. If not `beads: ready`, ask the user to install/initialize. Do not proceed until resolved.

## 1. Triage: trivial, quick, or too big? [P2]

Classify the task:

- **Trivial** (skip beads entirely): single-file edit under ~10 lines, typo/comment fix, one-line debug tweak, read-only investigation. → Go to step 4 (execute inline, no issues). You are permitted to write code.
- **Express-sized** (1–3 subtasks): proceed with this mode. You are no longer permitted to write code — you MUST file beads and dispatch to `beads-worker` subagents for execution.
- **Too big** (> 3 subtasks, multi-layer refactor, or cross-team dependencies): stop and tell the user `/vibe:engineer` is the right mode instead. Ask for confirmation before continuing under `/vibe:express`.

## 2. Light planning (no heavyweight hierarchy) [P2]

Break the task into 1–3 subtasks. Do NOT build an Epic > Story > Task > Subtask tree — that's Engineer Mode's job. A flat list is fine.

Predict the file scope for each subtask (same logic as `/vibe:execute` step 4). This informs whether execution can parallelize.

## 3. File beads

For each subtask, create a beads issue via `/vibe:bd-new` (or `bd create` directly if in a subagent context), **one at a time** (bd CLI lock — sequential only). Parallelism happens in step 4.

Every issue must ship with the full Issue Shape — title, context, AC, out-of-scope, verification. Link dependencies between subtasks with `--deps` or `bd dep add`; disjoint subtasks (no `--deps`) execute in parallel in step 4.

### Optional: model-routing hint

For each issue, classify per the rubric (see execute.md § Model-tier rubric) and (if confident) record via `bd create --labels model:<tier>`. See execute.md § Model-hint convention for orchestrator behavior.

## 4. Execute

**Trivial path [P3]:** do the work with Edit/Write directly. Touch only what the request requires. Run any obvious verification (compile, test, the specific behavior). Then commit:

```bash
git commit path/to/file1 path/to/file2 -m "$(cat <<'EOF'
<one-line description of what changed>
EOF
)"
```

Do NOT push. Report what changed and note "tracking skipped — trivial work."

**Non-trivial path [P4]:** execute the beads:

- Disjoint file scopes AND 2–3 subtasks → dispatch in parallel via `beads-worker` subagents (single response message with multiple Agent calls).
- Shared file scopes, cross-cutting, or single subtask → run serially.
- Respect dependency order: don't start a subtask whose blockers are open.

## 5. Collect or generate report(s)

**Trivial path:** report the change you made, any verification you ran, and that no beads were created.

**Non-trivial path:** collect reports from each subtask. Summarize into a concise report (next step).

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

If any subtask failed, surface what went wrong and what you'd suggest as next steps — don't leave it dangling.
