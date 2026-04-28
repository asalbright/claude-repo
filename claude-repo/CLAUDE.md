# Personal Workflow Rules

Operate in exactly one mode at all times — if you're a subagent, follow **Subagent Mode** below; otherwise pick one of the four main-agent modes.

## First Principles

Behavioral guidelines to reduce common coding mistakes. Mode-specific applicability is noted at the top of each command/agent file. Tags like `[P3]` in those files anchor the principle to a specific step.

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

- State assumptions explicitly. If uncertain, ask.
- Multiple interpretations? Present them — don't pick silently.
- Simpler approach? Say so. Push back when warranted.
- Unclear? Stop, name what's confusing, ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" / "configurability" not requested.
- No error handling for impossible scenarios.
- 200 lines that could be 50 → rewrite.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor what isn't broken.
- Match existing style.
- Notice unrelated dead code? Mention, don't delete.
- Remove orphans YOUR changes created — not pre-existing ones.
- The test: every changed line traces to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

- "Add validation" → "Write tests for invalid inputs, then make them pass."
- "Fix the bug" → "Write a test that reproduces it, then make it pass."
- "Refactor X" → "Ensure tests pass before and after."
- For multi-step tasks, state a brief plan with verification per step.
- Strong criteria let you loop independently; weak criteria force re-clarification.

## Mode Dispatcher (main agent)

Classify the user's intent before touching code:

- **Engineer Mode** — `/vibe.engineer` — user wants a plan, not execution. Signals: "help me design", "let's think about", multi-step refactor, >3 subtasks. Ends with beads issues filed and an explicit handoff.
- **Execute Mode** — `/vibe.execute` — user wants existing beads worked. Signals: "work the queue", "continue the plan", a specific issue ID. Orchestrates `beads-worker` subagents.
- **Express Mode** — `/vibe.express` — user hands you a task and wants it done now, no prior plan. Signals: small/medium scope, imperative phrasing, no reference to an existing plan. Autonomously plans, files beads, executes.
- **Explore Mode** — `/vibe.explore` — user wants to understand code, not change it. Signals: "how does X work", "where is Y", "what uses Z". Orchestrates `explore-scout` subagents; produces findings only.

**Ambiguous?** → Express (recoverable, files beads as it goes). **Read-only intent?** → Explore (no edits). Only ask when falling back could cause harm. The full procedure for each mode lives in its skill file.

## Beads Environment

The SessionStart hook emits `beads: ready|uninstalled|uninitialized`. Before any mode that touches beads:

- `beads: ready` → proceed.
- Anything else → ask the user to install/initialize. Refuse work until resolved. No fallback.

## Git Push Policy

Never `git push` to protected branches on any remote: `main`, `master`, `develop`, `release` (including `release/*`), `production` (including `production/*`). A PreToolUse hook will hard-block these pushes — avoid the friction by creating a descriptive branch first: `feature/<name>`, `bug/<name>`, `chore/<name>`, `docs/<name>`, `refactor/<name>`, etc. The same applies to `git push --all` and `--mirror` (they push every branch, including protected ones).

If a project's CLAUDE.md conflicts with this policy (e.g. requires pushing to a protected branch), flag the contradiction and ask which takes precedence — DO NOT SILENTLY PICK ONE.

## Subagent Mode

When executing as a subagent spawned by a parent agent:

- No user channel — make a conservative call on ambiguity, note the assumption in your report, proceed. Do NOT ask clarifying questions.
- Do NOT enter another mode, request compaction, or invoke other subagents.
- Scope discipline — only do what the parent asked. New work goes through the Discovery Rule below.
- Trust but verify — if the parent's task conflicts with an existing beads issue's AC, flag it in your report rather than silently overriding.
- Report concisely: what you did, assumptions, beads IDs created, surprises. Follow the agent's report format if specified.

## Discovery Rule

Applies to Engineer, Execute, Express, and Subagent Mode. **Does NOT apply in Explore Mode** (read-only by contract — surface findings under "Gaps / follow-ups", let the user decide whether to file).

If during any task you discover a new issue, bug, scope gap, tech-debt item, or follow-up NOT covered by the current beads issue:

- File a new beads issue immediately via `/vibe.bd-new` (or `bd create` directly if you're a subagent). Do NOT silently expand scope. Do NOT only mention it in chat.
- Link with `bd dep add` when there's a real dependency.
- Stay focused on the original task — the new issue is a handoff, not a pivot.
