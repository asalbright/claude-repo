---
description: Execute Mode — orchestrate beads-worker subagents through existing ready beads issues. Handles one ID, a filter, or drains bd ready entirely.
argument-hint: [issue-id | epic-id | empty for all ready]
---

# Execute Mode

Target: `$ARGUMENTS`

You are the **orchestrator**. You dispatch `beads-worker` subagents to execute issues. You do NOT write code yourself — if you catch yourself drafting an Edit/Write call for a non-beads, non-reporting file, stop: that belongs in a subagent.

Refuse to proceed if SessionStart status is anything other than `beads: ready`.

## 1. Resolve the work queue

- If `$ARGUMENTS` is a single issue ID (matches `bd-...`): queue = `[that ID]`.
- If `$ARGUMENTS` is an epic ID (issue with `type=epic`): queue = all open descendants. Run `bd show <id> --children` and include any issue that appears in `bd ready` below the epic.
- If `$ARGUMENTS` is empty, `next`, or non-ID text: queue = `bd ready --limit 50` in priority order.

If the queue is empty, tell the user and stop — no work to do.

For transparency, print the resolved queue back to the user (IDs + one-line titles) before dispatching. Do not ask for confirmation in auto-mode sessions; just print and proceed.

## 2. Predict file scope per issue

For each issue in the queue, run `bd show <id> --long` and read Title, Context, Acceptance Criteria. Predict the set of files or directories this issue will touch. Be conservative:

- If the AC clearly names specific files → use those.
- If the AC implies a well-bounded area (e.g., "retry logic in webhook handler") → use that directory/file prefix.
- If the AC is cross-cutting, ambiguous, or touches many layers → mark the issue as **cross-cutting** (scope = `*`). Cross-cutting issues must run serially.

Store the prediction keyed by issue ID. These are best-effort — subagents still own the truth of what they edit.

## 3. Build batches (disjoint-file parallelism, cap 3)

Greedy grouping, highest priority first:

1. Start an empty batch.
2. Walk the queue in priority order. For each issue:
   - If the batch is empty → add it.
   - If the issue is cross-cutting → close this batch (even if smaller than 3) and dispatch it alone in its own batch of 1.
   - If the issue's predicted file set is disjoint from every issue already in the current batch → add it.
   - Otherwise → leave it for the next batch.
3. Cap batch size at 3.
4. Close the batch and dispatch. Start the next batch with the first unbatched issue.

## 4. Dispatch a batch

Use the Agent tool with `subagent_type: beads-worker`. For parallel batches, issue all Agent tool calls **in a single response message** — this is how Claude Code parallelizes them. Serial batches use one Agent call at a time.

Each Agent prompt should be minimal and self-contained:

```
Execute beads issue bd-42 end-to-end per your system prompt.
Report closed/blocked/aborted with the standard report format.
```

Do NOT pass extra context — the subagent reads the issue itself.

## 5. Collect reports and handle failures

When a batch returns:

- Record each subagent's outcome: `closed`, `blocked`, or `aborted`.
- **Continue on failure.** A blocked or aborted issue does not stop the orchestration — move to the next batch. (Per user policy: report everything at the end.)
- Record any Discovery-Rule follow-up issue IDs the subagent created.

## 6. Loop until queue is drained

After each batch, some issues may have been unblocked by newly-closed deps. If the original resolution was `bd ready`, re-run `bd ready` and append any newly-ready issues to the unbatched queue before building the next batch.

Stop when the queue is empty OR every remaining issue is `aborted`/`blocked` with no new progress possible.

## 7. Final report

Print a single summary to the user:

```
/vibe:execute summary
─────────────────────
Closed:  N issues (bd-42, bd-43, ...)
Blocked: M issues (bd-44 — <reason>, ...)
Aborted: K issues (bd-45 — <reason>, ...)
Follow-ups filed via Discovery Rule: bd-51, bd-52

Batches run: B (serial: X, parallel: Y)
```

If any issues aborted because their AC was bad, surface this prominently — those issues need user attention before they can close.
