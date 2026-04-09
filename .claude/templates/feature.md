# Feature: <FEATURE_NAME>

## Description

<What this feature does and why it matters — 2-3 paragraphs>

## Problem Statement

<What problem exists today, who it affects, what the cost of not solving it is>

## Solution Statement

<How this feature solves the problem — approach, key design decisions>

## Research Findings

### Existing Patterns
<What patterns exist in the codebase that apply here>
<Include specific file paths and line numbers>

### Technical Constraints
<Dependencies, limitations, API restrictions, performance concerns>

## Relevant Files

- `path/to/file.py` - <what changes and why>
- `path/to/other.py` - <what changes and why>

## Implementation Plan

### Relevant Patterns
<Codebase patterns that implementation tasks should follow>
<Each entry references a concrete file path + line range>

- `path/to/file.py:L42-L80` — <Pattern name>: <How tasks should follow this pattern>
- `path/to/other.py:L10-L35` — <Pattern name>: <How tasks should follow this pattern>

### Phase 1: <Phase Name>
<What this phase accomplishes — 1-2 paragraphs with enough detail to guide bead creation>

### Phase 2: <Phase Name>
<What this phase accomplishes>

## Verification

### How to Test
<Specific commands to run, not vague "add unit tests">

```bash
# Example: run the feature and check output
python scripts/path/to/test.py --flag
```

### Expected Results
- <Concrete observable outcome 1>
- <Concrete observable outcome 2>

### Regression Checks
- <What existing behavior must not break>
- <Command to verify no regression>

## Acceptance Criteria

- [ ] <Testable criterion with observable outcome>
- [ ] <Testable criterion with observable outcome>
