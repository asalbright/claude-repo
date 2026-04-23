---
description: Engineer Mode — produce a set of well-shaped beads issues for multi-step work. Does NOT execute; ends with a handoff to /vibe:execute.
argument-hint: [brief description of the work to plan]
---

# Engineer Mode

Target: $ARGUMENTS

Engineer Mode is for work that requires more than 3 subtasks. Its output is **beads issues**, not code. Execution happens in a separate mode — `/vibe:execute` — which can be invoked in this session or a future one.

Refuse to proceed if SessionStart status is anything other than `beads: ready`. Resolve the environment first.

## 1. Clarify before planning

Ask the user clarifying questions until the scope, constraints, and definition of done are unambiguous. Specifically confirm:

- What problem is being solved and why now.
- The boundary between in-scope and out-of-scope.
- Any hard constraints (deadlines, compatibility, dependencies on other teams).
- What "done" looks like — the user-observable outcome.

Do not skip this step. Vague Engineer Mode input produces vague beads issues, which is the failure mode we're trying to prevent.

## 2. Break down using the Epic > Story > Task > Subtask hierarchy

- **Epic** — the whole effort. One per plan.
- **Story** — a coherent user-facing or system-facing capability within the epic.
- **Task** — a unit of work that ships independently, roughly 1 PR worth.
- **Subtask** — a small implementation step within a task.

For small efforts, not every layer is needed. Use the minimum depth that captures the structure.

## 3. Verify the plan with the user

Show the full hierarchy with proposed titles and dependency links. Get explicit approval before creating issues. Iterate if the user pushes back.

## 4. Create beads issues

Create the beads issues **one at a time** — invoke `/vibe:bd-new` sequentially, waiting for each to return its issue ID before starting the next. Do NOT batch multiple `/vibe:bd-new` calls into a single response: the `bd` CLI takes a lock on its store and parallel `bd create` calls will fail.

Parallelism belongs in the **dependency graph**, not the creation step. Shape the graph so that independent leaves have no `--deps` between them — `/vibe:execute` will later fan them out across `beads-worker` subagents in parallel automatically.

Each issue must ship with the full Issue Shape (context, AC, out of scope, verification, dependencies). Do not batch-create skeleton issues and backfill fields later.

Link dependencies with `bd dep add` as you go, or pass `--deps` at creation time.

For the Epic, use `--type epic`. For Stories, consider `--type feature`. For Tasks, `--type task` (the default). Use parent relationships (`--parent <epic-id>`) to build the hierarchy.

Beads must be created sufficiently so that a new agent could `/vibe:execute` to pick up and execute without further clarification.

## 5. Hand off

Once the plan and issues exist, do NOT start implementation in this session. Ask the user:

> The plan is filed as `{epic-id}` with N child issues. My current context is at `{/context}`, would you like to: 
> 1. Invoke `/vibe:execute` now?
> 2. Compact, and then let me invoke `/vibe:execute`?
> 3. Pause here so a future session can pick up from the beads queue?

Wait for a direct instruction before writing any code.
