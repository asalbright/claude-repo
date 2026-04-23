# Personal Workflow Rules

Operate in exactly one mode at all times — if you're a subagent, follow **Subagent Mode** below; otherwise pick one of the four main-agent modes.

## Mode Dispatcher (main agent)

Classify the user's intent before touching code:

- **Engineer Mode** — `/vibe:engineer` — the user wants a plan, not execution. Signals: "help me design", "let's think about", multi-step refactor, >3 subtasks. Ends with beads issues filed and an explicit handoff.
- **Execute Mode** — `/vibe:execute` — the user wants existing beads issues worked. Signals: "work the queue", "start on the backlog", "continue the plan", a specific issue ID. Orchestrates `beads-worker` subagents.
- **Express Mode** — `/vibe:express` — the user hands you a task and wants it done now, no prior plan. Signals: small/medium scope, imperative phrasing ("add X", "fix Y"), no reference to an existing plan. Autonomously plans, files beads, and executes.
- **Explore Mode** — `/vibe:explore` — the user wants to understand code, not change it. Signals: "how does X work", "where is Y", "what uses Z", "explain this module". Orchestrates `explore-scout` subagents; produces findings, not beads issues or edits.

If the user's intent is genuinely ambiguous between modes, fall back to **Express Mode** — it's the lowest-commitment path and will file beads as it goes, so a wrong guess is recoverable. Only ask when falling back could cause harm (e.g., the user might actually want a multi-hour plan and you're about to start coding). If the user is clearly asking a read-only question ("how does X work"), prefer Explore Mode over Express Mode — Explore will not touch files. The full procedure for each mode lives in its slash command file.

## Beads Environment

The SessionStart hook emits `beads: ready|uninstalled|uninitialized` into context. Before any mode that creates or touches beads issues:

- If `beads: ready` → proceed.
- Otherwise → ask the user to install/initialize
  - THERE IS NO FALLBACK. REFUSE TO DO ANY WORK UNLESS THE ENVIRONMENT IS READY. DO NOT PROCEED WITH ISSUE CREATION OR EXECUTION UNTIL IT'S RESOLVED.

## Git Push Policy

Never `git push` to protected branches on any remote: `main`, `master`, `develop`, `release` (including `release/*`), `production` (including `production/*`). A PreToolUse hook will hard-block these pushes — avoid the friction by creating a descriptive branch first: `feature/<name>`, `bug/<name>`, `chore/<name>`, `docs/<name>`, `refactor/<name>`, etc. The same applies to `git push --all` and `--mirror` (they push every branch, including protected ones).

If a local project's CLAUDE.md contains session-close or push instructions that conflict with this policy (e.g. require pushing to a protected branch), flag the contradiction to the user and ask which takes precedence — DO NOT SILENTLY PICK ONE.

## Subagent Mode

When executing as a subagent spawned by a parent agent:

- Do NOT ask clarifying questions — you have no user channel. If instructions are ambiguous, make a reasonable, conservative judgment, note the assumption in your report, and proceed.
- Do NOT enter Engineer Mode or Explore Mode or request conversation compaction — main-agent concerns only.
- Do NOT invoke other subagents — execute the work yourself with the tools you have.
- Scope discipline: only do what the parent asked. For additional work you discover, follow the Discovery Rule below.
- Trust but verify: if the parent's task conflicts with an existing beads issue's AC, flag it in your report rather than silently overriding.
- Report back concisely: what you did, assumptions made, beads IDs created, and any surprises. If the agent definition specifies a report format, follow it.

## Discovery Rule (applies to Engineer, Execute, Express, and Subagent Mode)

If during any task you discover a new issue, bug, scope gap, tech-debt item, or follow-up that is NOT covered by the current beads issue:

- Create a new beads issue for it immediately via `/vibe:bd-new` (or `bd create` directly if you're a subagent). Do NOT silently expand the current task's scope, and do NOT only mention it in chat/report output.
- Link with `bd dep add` when there's a real dependency.
- Stay focused on the original task — the new issue is a handoff, not an invitation to pivot.
- Subagents: create the issue yourself before returning and include its ID in your report.

**Does NOT apply in Explore Mode.** Explore Mode is read-only by contract — findings are reported back to the user, who decides whether to file anything via `/vibe:bd-new`, `/vibe:engineer`, or `/vibe:express`. Do not silently spawn beads issues during `/vibe:explore`; surface discoveries under "Gaps / follow-ups" in the summary instead.
