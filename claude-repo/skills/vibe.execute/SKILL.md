---
name: vibe.execute
description: Execute Mode — orchestrate beads-worker subagents through existing ready beads issues. Handles one ID, a filter, or drains bd ready entirely.
argument-hint: [issue-id | epic-id | empty for all ready]
allowed-tools: Bash, Read, Glob, Grep, Agent
---

*Principles: 4 strong; 1 partial (when escalating tier or marking cross-cutting); 2, 3 n/a (orchestrator does not code). See CLAUDE.md § First Principles.*

# Execute Mode

Target: `$ARGUMENTS`

You are the **orchestrator**. You dispatch `beads-worker` subagents. You do NOT write code yourself — if you catch yourself drafting an Edit/Write call for a non-beads, non-reporting file, STOP: that belongs in a subagent.

Refuse to proceed if SessionStart status ≠ `beads: ready`.

## 1. Resolve scope

- Single issue ID: `bd show <id> --long`. If type is `epic` or `feature`, collect descendants by iterating `bd show <id> --children` recursively. Otherwise scope = `[that ID]`.
- Empty / `next` / non-ID text: scope = `bd ready --exclude-type=epic --limit 50`, plus parent epics for context.

## 2. Read all in-scope issues and categorize

For each in-scope issue, run `bd show <id> --long`. Classify:

- **Context node** — type is `epic` or `feature`, OR has children but no concrete Verification. Read for understanding; do NOT dispatch.
- **Work node** — has concrete AC and a Verification step. Candidate for dispatch.

Capture any **model-routing hint** from the issue's labels: exactly one of `model:haiku|sonnet|opus` may be present (metadata recorded by the shaper). Record the hint or its absence alongside each work node.

Do this silently — use it for sequencing decisions.

### Model-hint convention (advisory floor)

The `model:<tier>` label is an **advisory floor**, not a ceiling:

- MAY escalate above the hint (e.g., `sonnet` → `opus` for cross-cutting issues, or to match an opus-tier batch sibling).
- MUST NOT downgrade below the hint. Mis-routing down aborts the worker; mis-routing up only costs compute — asymmetry is intentional.
- No label = inherit default. Do not pass a `model` parameter; treat absence as "shaper had no opinion," not as an error.

Tiers map to Claude families: `haiku` → Haiku, `sonnet` → Sonnet, `opus` → Opus.

### Model-tier rubric (for shapers)

Used by Engineer and Express modes when applying `bd create --labels model:<tier>`. When uncertain, **omit the hint** — missing is strictly safer than wrong.

- **`model:haiku`** — trivially mechanical. Doc/config tweaks, one-liners, AC names exact files and the change is essentially dictated. No design judgment required.
- **`model:sonnet`** — default. Well-bounded single-file or single-directory work. Clear AC, normal reasoning load.
- **`model:opus`** — cross-cutting, ambiguous AC, multi-file architectural reasoning, or anything where a wrong call cascades.

## 3. Build the work queue

Filter work nodes to those currently in `bd ready` (open, no active blockers). If the queue is empty after categorization, tell the user and stop.

Print the resolved work queue (IDs + one-line titles) before dispatching. Do not ask for confirmation.

## 4. Predict file scope per work node

Read each node's Title, Context, and AC. Predict the set of files/directories it will touch. Be conservative:

- AC names specific files → use those.
- AC implies a well-bounded area (e.g., "retry logic in webhook handler") → use that directory/file prefix.
- AC is cross-cutting / ambiguous / multi-layer → mark **cross-cutting** (scope = `*`). Cross-cutting issues run serially. **[P1]** Surface the assumption that drove the cross-cutting call in your dispatch comment.

## 5. Build batches (disjoint-file parallelism, cap 3)

Greedy grouping, highest priority first:

1. Start an empty batch.
2. Walk the queue in priority order. For each issue:
   - If the batch is empty → add it.
   - If cross-cutting → close this batch (even if smaller than 3) and dispatch it alone in its own batch of 1.
   - If the issue's predicted file set is disjoint from every issue already in the current batch → add it.
   - Otherwise → leave it for the next batch.
3. Cap batch size at 3.
4. Close the batch and dispatch. Start the next batch with the first unbatched issue.

## 6. Dispatch a batch

Use the Agent tool with `subagent_type: beads-worker`. For parallel batches, issue all Agent calls **in a single response message** — that's how Claude Code parallelizes them. Serial batches use one Agent call at a time.

Each Agent prompt is minimal and self-contained:

```
Execute beads issue bd-42 end-to-end per your system prompt.
Report closed/blocked/aborted with the standard report format.
```

Do NOT pass extra context — the subagent reads the issue itself.

**Per-issue model routing.** When you captured a `model:<tier>` hint in step 2, pass the matching `model` parameter on that issue's Agent tool call. When no hint was captured, omit the parameter so the subagent inherits the default. Apply the floor rule: if step 4 marked the issue cross-cutting and the hint is `sonnet`, escalate to `opus`. In a mixed-tier parallel batch, dispatch each issue at its own (post-escalation) tier rather than downgrading.

## 7. Collect reports, handle failures, auto-close context nodes [P4]

When a batch returns:

- Record each outcome: `closed`, `blocked`, or `aborted`. Verification is the close-gate — do not record `closed` unless the worker confirmed AC verified.
- **Continue on failure.** A blocked or aborted issue does not stop orchestration.
- Record any Discovery-Rule follow-up issue IDs the subagent created.
- **Auto-close context nodes.** For each work node that closed, check its parent: if the parent is a context node and all children are now closed, close it with `bd close <id> --reason "All child work complete"`. Repeat up the tree.

## 8. Loop until queue is drained

After each batch, re-run `bd ready --exclude-type=epic --limit 50` (or re-filter scoped descendants) and append newly-ready work nodes.

Stop when the queue is empty OR every remaining issue is `aborted`/`blocked` with no progress possible.

## 9. Final report

Print a single summary:

```
/vibe.execute summary
─────────────────────
Closed:  N issues (bd-42, bd-43, ...)
Blocked: M issues (bd-44 — <reason>, ...)
Aborted: K issues (bd-45 — <reason>, ...)
Commits: <list of commits made>
Follow-ups filed via Discovery Rule: bd-51, bd-52

Batches run: B (serial: X, parallel: Y)
```

If any issues aborted because their AC was bad, surface this prominently — those issues need user attention before they can close.
