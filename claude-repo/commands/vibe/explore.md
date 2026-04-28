---
description: Explore Mode — read-only codebase research. Orchestrates explore-scout subagents to answer questions; does NOT file beads or edit code.
argument-hint: [question or topic to investigate]
---

*Principles: 1 partial (scope before searching), 4 partial (lowest thoroughness that answers); 2, 3 n/a (read-only). See CLAUDE.md § First Principles.*

# Explore Mode

Target: $ARGUMENTS

For **understanding code, not changing it**. Output is a synthesized set of findings with file paths and line references — no beads, no edits.

If `$ARGUMENTS` is empty, ask the user for a one-line question or topic.

## 1. Scope the investigation [P1] [P4]

Restate the question in your own words and confirm with the user when scope is ambiguous. Decide thoroughness based on the ask:

- **quick** — single lookup, "where is X defined", one clear file expected.
- **medium** — "how does feature Y work", spans a handful of files.
- **very thorough** — "map the entire auth layer", cross-cutting, multiple conventions.

Pick the lowest thoroughness that will answer the question.

## 2. Dispatch explore-scout subagents

Use the `Agent` tool with `subagent_type: explore-scout` (the user-defined subagent — NOT the built-in `Explore`). Dispatch 1–3 agents **in a single response message** when the question has naturally disjoint sub-questions (parallel search). Use one agent for a single focused lookup.

Each agent prompt must be self-contained:

- The specific sub-question.
- The thoroughness level (`quick`, `medium`, or `very thorough`).
- Any known entry points (file paths the user mentioned, known symbols).

The `explore-scout` subagent is tool-scoped read-only (Read/Glob/Grep only) and produces a standard report shape. You don't need to re-specify output format.

## 3. Synthesize findings

When agents return, merge reports into a single answer:

- Lead with a **direct answer** (1–3 sentences).
- Follow with **key locations** as a bulleted list of clickable `[file:line](path#L)` refs with one-line explanations.
- Call out **gaps, surprises, or follow-up questions**.
- Do NOT dump raw subagent output — summarize.

## 4. Handoff

End with explicit next-step options:

> Findings above. Next step:
>
> 1. (small) File this as a code change via `/vibe:express`.
> 2. (multi-stage) Continue work with a `/vibe:engineer`.
> 3. Ask another explore question OR explore deeper.
> 4. Done — just wanted to understand.

Wait for direct instruction. Do NOT start `/vibe:engineer` or `/vibe:express` automatically.

## Non-goals

- Read-only — no edits, no builds, no beads creation.
- Discovery Rule does NOT apply (see CLAUDE.md). Surface findings under "Gaps / follow-ups"; the user decides whether to file via `/vibe:bd-new`.
