# Epic: <EPIC_NAME>

## Epic Overview

<2-3 paragraphs describing the epic's purpose, scope, and expected outcome>

## Vision Context

**Source Vision**: [Vision: <name>](../vision-<name>.md) *(if applicable)*

### Key Points

**Current Pain Points Addressed:**
- <pain point 1>
- <pain point 2>

**Goals:**
1. <goal 1>
2. <goal 2>

**Architecture Decision:**
<key architectural decisions that inform this epic's approach>

## Specs in This Epic

### Phase 1: <phase name>
- [ ] [Chore: <name>](./1_chore.md) - <brief description>
- [ ] [Feature: <name>](./2_feature.md) - <brief description>

### Phase 2: <phase name>
- [ ] [Feature: <name>](./3_feature.md) - <brief description>
- [ ] [Chore: <name>](./4_chore.md) - <brief description>

### Phase 3: <phase name>
- [ ] [Feature: <name>](./5_feature.md) - <brief description>

<add more phases as needed>

## Execution Order

### Phase 1: <phase name> (<estimated effort>)
**Goal**: <what this phase achieves>

Execute in order:
1. [Chore: <name>](./1_chore.md) - <why this is first>
2. [Feature: <name>](./2_feature.md) - <why this follows>

**Success Criteria**:
- <criterion 1>
- <criterion 2>

**🔄 USER BREAKPOINT #1**: <what to validate before proceeding>

---

### Phase 2: <phase name> (<estimated effort>)
**Goal**: <what this phase achieves>

Execute in order:
3. [Feature: <name>](./3_feature.md) - <dependencies: 1, 2>
4. [Chore: <name>](./4_chore.md) - <dependencies: 3>

**Success Criteria**:
- <criterion 1>
- <criterion 2>

**🔄 USER BREAKPOINT #2**: <what to validate before proceeding>

---

### Phase 3: <phase name> (<estimated effort>)
**Goal**: <what this phase achieves>

<same structure as Phase 1>

---

<add more phases as needed>

## Path Dependencies Diagram

```
Phase 1
    1_chore.md (foundation)
        ↓
    2_feature.md (depends on 1)
        ↓
Phase 2
    3_feature.md (depends on 2)
        ↓
    4_chore.md (depends on 3)
        ↓
Phase 3
    5_feature.md (depends on 4)

Critical Path:
1 → 2 → 3 → 4 → 5
```

## Implementation Notes

### Cross-Cutting Concerns

**Architecture Decisions:**
- <key technical choice 1>
- <key technical choice 2>

**Shared Dependencies:**
- <library/tool 1>
- <library/tool 2>

**Testing Strategy:**
- <how to validate the epic as a whole>

**Rollout Plan:**
- <incremental adoption strategy>
- <rollback strategy>

### User Testing Breakpoints

This epic includes **<N> explicit user testing breakpoints** (marked with 🔄):
1. **After Phase 1**: <what to validate>
2. **After Phase 2**: <what to validate>
3. **After Phase 3**: <what to validate>

Each breakpoint is a decision point: proceed to next phase, iterate on current phase, or stop if goals are met.

## Success Metrics

- [ ] <measurable outcome 1>
- [ ] <measurable outcome 2>
- [ ] <measurable outcome 3>

## Future Enhancements

Ideas that came up during planning but are out of scope for this epic:

1. <future work item>
2. <future work item>

---

## Epic Structure

This epic lives in `specs/epic-<name>/` with the following files:

```
specs/epic-<name>/
├── README.md          # This file - epic overview and execution plan
├── 1_chore.md         # First spec (chore template)
├── 2_feature.md       # Second spec (feature template)
├── 3_feature.md       # Third spec (feature template)
├── 4_chore.md         # Fourth spec (chore template)
└── 5_feature.md       # Fifth spec (feature template)
```

### Creating Numbered Specs

Each numbered file (1_chore.md, 2_feature.md, etc.) should:
1. Use the corresponding template from `.claude/templates/`
2. Fill in all placeholders with specific details
3. Reference dependencies by number in the "Dependencies" section
4. Be fully self-contained and implementable

**Naming Convention:**
- `<N>_chore.md` for chore specs
- `<N>_feature.md` for feature specs
- `<N>_bug.md` for bug fixes (if applicable)

Where `<N>` is the execution order number (1, 2, 3, etc.)
