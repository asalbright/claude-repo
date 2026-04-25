---
description: Execute Mode — orchestrate beads-worker subagents through existing ready beads issues. Handles one ID, a filter, or drains bd ready entirely.
argument-hint: [issue-id | epic-id | empty for all ready]
---

# Execute Mode

Target: `$ARGUMENTS`

You are the **orchestrator**. You dispatch `beads-worker` subagents to execute work nodes. You do NOT write code yourself — if you catch yourself drafting an Edit/Write call for a non-beads, non-reporting file, STOP: that belongs in a subagent.

Refuse to proceed if SessionStart status is anything other than `beads: ready`.

## 1. Resolve scope

Determine the full set of in-scope issues:

- If `$ARGUMENTS` is a single issue ID: run `bd show <id> --long`. If its type is `epic` or `feature`, collect all descendants by iterating `bd show <id> --children` recursively until no children remain. Otherwise scope = `[that ID]`.
- If `$ARGUMENTS` is empty, `next`, or non-ID text: scope = all issues returned by `bd ready --exclude-type=epic --limit 50`, plus the parent epic of each (if one exists) for context.

## 2. Read all in-scope issues and categorize

For each in-scope issue, run `bd show <id> --long`. Classify each as:

- **Context node** — type is `epic` or `feature`, OR has children but no concrete Verification step. Read for understanding; do NOT dispatch to a worker.
- **Work node** — has concrete AC and a Verification step. Candidate for dispatch.

While reading, also capture any **model-routing hint** from the issue's labels: exactly one of `model:haiku`, `model:sonnet`, or `model:opus` may be present. This is metadata recorded by the shaper (Engineer or Express) and means the issue is suggested to run on at least that tier. If no `model:*` label is present, that is the default — there is no error, no warning, and the orchestrator falls back to its normal model inheritance for that issue. Record the hint (or its absence) alongside each work node for use in step 6.

Do this silently — do not surface the context analysis to the user. Use it to inform sequencing and batching decisions.

### Model-hint convention (advisory floor)

The `model:<tier>` label is an **advisory floor**, not a ceiling:

- The orchestrator MAY escalate above the hint — for example, promote `sonnet` → `opus` for an issue that turns out to be cross-cutting per the step-4 file-scope check, or that lands in a batch with an opus-tier sibling.
- The orchestrator MUST NOT downgrade below the hint. Never run a `model:opus` issue on sonnet, never run a `model:sonnet` issue on haiku. Mis-routing down aborts the worker cycle; mis-routing up only costs more compute, so the asymmetry is intentional.
- When **no model label** is present on an issue, behavior is unchanged: do not pass a `model` parameter to the Agent tool, and let the subagent inherit the default. Treat the absence as "shaper had no opinion," not as an error.

Tiers map to Claude model families: `haiku` → Haiku, `sonnet` → Sonnet, `opus` → Opus. The exact model ID is whatever the Agent tool resolves for that family in the current environment.

## 3. Build the work queue

Filter work nodes to those currently in `bd ready` (open, no active blockers). These are the candidates for dispatch this pass.

If the work queue is empty after categorization, tell the user and stop — no work to do.

For transparency, print the resolved work queue (IDs + one-line titles) before dispatching. Do not ask for confirmation; just print and proceed.

## 4. Predict file scope per work node

For each work node, read its Title, Context, and Acceptance Criteria. Predict the set of files or directories it will touch. Be conservative:

- If the AC clearly names specific files → use those.
- If the AC implies a well-bounded area (e.g., "retry logic in webhook handler") → use that directory/file prefix.
- If the AC is cross-cutting, ambiguous, or touches many layers → mark as **cross-cutting** (scope = `*`). Cross-cutting issues must run serially.

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

Use the Agent tool with `subagent_type: beads-worker`. For parallel batches, issue all Agent tool calls **in a single response message** — this is how Claude Code parallelizes them. Serial batches use one Agent call at a time.

Each Agent prompt should be minimal and self-contained:

```
Execute beads issue bd-42 end-to-end per your system prompt.
Report closed/blocked/aborted with the standard report format.
```

Do NOT pass extra context — the subagent reads the issue itself.

**Per-issue model routing.** When you captured a `model:<tier>` hint for an issue in step 2, pass the matching `model` parameter on that issue's Agent tool call (`haiku`, `sonnet`, or `opus`). When no hint was captured, omit the `model` parameter entirely so the subagent inherits the orchestrator's default — do not invent a tier. Apply the floor rule from the convention block: if step 4 marked the issue cross-cutting and the hint is `sonnet`, escalate to `opus`; if a parallel batch contains a mix of tiers, dispatch each issue at its own (post-escalation) tier rather than downgrading any of them.

## 7. Collect reports, handle failures, and auto-close context nodes

When a batch returns:

- Record each outcome: `closed`, `blocked`, or `aborted`.
- **Continue on failure.** A blocked or aborted issue does not stop orchestration — move to the next batch.
- Record any Discovery-Rule follow-up issue IDs the subagent created.
- **Auto-close context nodes.** For each work node that closed, check its parent: if the parent is a context node and all its children are now closed, close it with `bd close <id> --reason "All child work complete"`. Repeat up the tree until no more parents qualify.

## 8. Loop until queue is drained

After each batch, re-run `bd ready --exclude-type=epic --limit 50` (or re-filter scoped descendants) and append newly-ready work nodes to the unbatched queue.

Stop when the queue is empty OR every remaining issue is `aborted`/`blocked` with no new progress possible.

## 9. Final report

Print a single summary to the user:

```
/vibe:execute summary
─────────────────────
Closed:  N issues (bd-42, bd-43, ...)
Blocked: M issues (bd-44 — <reason>, ...)
Aborted: K issues (bd-45 — <reason>, ...)
Commits: <list of commits made>
Follow-ups filed via Discovery Rule: bd-51, bd-52

Batches run: B (serial: X, parallel: Y)
```

If any issues aborted because their AC was bad, surface this prominently — those issues need user attention before they can close.
