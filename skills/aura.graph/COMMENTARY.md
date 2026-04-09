# Commentary: aura.graph vs aura.scope

## What They Share

Both skills produce beads graphs. Both start with research, create epics with child tasks, wire dependencies, and verify the result. The output is a task graph that agents can execute.

## Where They Diverge

### aura.scope — Single-epic, code-first

Scope is purpose-built for code changes. It assumes:
- One epic with 5-7 child tasks
- Tasks are implementation work (write code, run tests)
- Research phase explores a codebase to find files to change
- Every task has a `Verification` section with a runnable command
- Output is a scope file from a template + a flat epic

Scope works well for: adding a feature, fixing a bug, refactoring a module, writing tests. Anything where the work is "change these files, verify with these commands." The ceiling is ~7 tasks under one epic.

### aura.graph — Multi-epic, domain-agnostic

Graph is purpose-built for large, phased work that exceeds a single epic. It assumes:
- Multiple tiered epics (master → phase → tasks)
- Tasks may not be code at all (documentation, research, design, migration)
- Research phase identifies deliverables and phases, not just files to change
- Tasks have self-sufficient descriptions so sub-agents can work independently
- Output is a multi-layer graph with write/review pairs and phase sequencing

Graph works well for: writing 10 Confluence pages, migrating a database across 3 stages, building a multi-service deployment pipeline, any project where you'd naturally say "first we plan, then we execute in parallel, then we finalize."

## Decision Guide

| Signal | Use scope | Use graph |
|--------|-----------|-----------|
| Work fits in 5-7 tasks | Yes | No |
| Work has 10+ deliverables | No | Yes |
| Every task is code change | Yes | Probably scope |
| Tasks include writing, review, design | No | Yes |
| Need write/review loops per deliverable | No | Yes |
| Need parallel sub-agent dispatch | Maybe | Yes |
| Need phase gating (plan → execute → finalize) | No | Yes |
| One agent can do all the work | Yes | No |
| Multiple agents/sub-agents needed | No | Yes |

**Rule of thumb:** If you'd describe the work as "implement X," use scope. If you'd describe it as "orchestrate the production of X across multiple stages," use graph.

## How to Use aura.graph

### Invocation

```
/aura.graph "Write 10 API reference pages for each service endpoint"
/aura.graph .aura/plans/queue/my-project/graph-plan.md
```

### What Happens

1. Agent reads the input and identifies all deliverables (e.g., 10 pages)
2. Agent proposes phases (A: concept, B: page generation, C: finalization)
3. Agent creates the full graph: master epic → phase epics → task beads
4. Agent verifies the graph structure

### After Graph Creation

The graph is a plan, not an execution. To execute:
- An orchestrator agent claims Phase A, works through A.1 → A.2 → A.3
- When Phase A closes, Phase B unblocks
- The Phase B agent dispatches write/review pairs to sub-agents in parallel
- When all Phase B children close, Phase B closes, Phase C unblocks
- A finalization agent handles C.1

This orchestration is currently manual (the user or a top-level agent drives it). A future `aura.execute` enhancement could handle multi-epic orchestration automatically.

## Could You Use Graph for Code?

Yes, but you probably shouldn't for most code work. Graph's strength is structural — it shines when you have many deliverables that follow a repeating pattern (write/review, implement/test, draft/approve). For a typical code feature with 5-7 tasks, scope is simpler and faster.

Where graph IS useful for code:
- Large migrations (10+ services to update)
- Multi-module refactors where each module needs independent review
- Platform work that spans plan → implement → rollout phases
- Any code project where you'd naturally create multiple PRs in sequence

## Evolution Notes

The graph skill was born from a real session where we iteratively built a 28-bead graph for a multi-deliverable documentation project. The key lessons were:

1. **Epics are containers, not pipeline nodes** — this took 3 iterations to get right
2. **Parent-child and blocking deps serve different purposes** — conflating them creates cycles
3. **Phase-to-phase sequencing should be epic-to-epic** — not child-to-child across phases
4. **Write/review pairing scales mechanically** — odd=write, even=review is a pattern that works for any deliverable count

These lessons are encoded in the skill's structural rules (Phase 2) so future agents don't repeat the same misunderstandings.
