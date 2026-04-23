---
description: Explore Mode — read-only codebase research. Orchestrates explore-scout subagents to answer questions; does NOT file beads or edit code.
argument-hint: [question or topic to investigate]
---

# Explore Mode

Target: $ARGUMENTS

Explore Mode is for **understanding code, not changing it**. Output is a synthesized set of findings with file paths and line references — no beads issues, no edits.

If `$ARGUMENTS` is empty, ask the user for a one-line question or topic before proceeding.

## 1. Scope the investigation

Restate the question in your own words and confirm with the user when the scope is ambiguous. Decide thoroughness based on the ask:

- **quick** — a single lookup, "where is X defined", one clear file expected.
- **medium** — "how does feature Y work", spans a handful of files.
- **very thorough** — "map the entire auth layer", cross-cutting, multiple conventions.

Pick the lowest thoroughness that will answer the question.

## 2. Dispatch explore-scout subagents

Use the `Agent` tool with `subagent_type: explore-scout` (the user-defined subagent — NOT the built-in `Explore`). Dispatch 1–3 agents **in a single response message** when the question has naturally disjoint sub-questions (parallel search). Use one agent when the question is a single focused lookup.

Each agent prompt must be self-contained:

- The specific sub-question.
- The thoroughness level (`quick`, `medium`, or `very thorough`).
- Any known entry points (file paths the user mentioned, known symbols).

The `explore-scout` subagent is tool-scoped read-only (Read/Glob/Grep only) and produces a standard report shape with clickable refs. You do not need to re-specify the output format in the prompt — the subagent's system prompt handles that.

## 3. Synthesize findings

When agents return, merge their reports into a single answer for the user:

- Lead with a **direct answer** to the original question (1–3 sentences).
- Follow with **key locations** as a bulleted list of clickable `[file:line](path#L)` references with one-line explanations.
- Call out **gaps, surprises, or follow-up questions** the investigation surfaced.
- Do NOT dump raw subagent output — summarize.

## 4. Handoff

End with explicit options for next steps:

> Findings above. Next step:
> 1. File this as beads work via `/vibe:engineer` (multi-step) or `/vibe:express` (small).
> 2. Ask another explore question.
> 3. Done — just wanted to understand.

Wait for a direct instruction. Do NOT start `/vibe:engineer` or `/vibe:express` automatically.

## Non-goals

- Explore Mode does NOT create beads issues. If the investigation reveals a bug or tech-debt item, mention it in the findings and let the user decide whether to file via `/vibe:bd-new` — the Discovery Rule does not apply here because Explore is read-only by contract.
- Explore Mode does NOT edit files, run build/test commands, or make network calls beyond what subagents need for search.
