---
name: "Task / Feature"
about: "Add a skill, fix, or improvement in NexSkills"
title: "<short imperative description>"
labels: ""
assignees: ""
---

<!-- Header block — keep these lines at the very top of the issue body. -->
Model: <Haiku | Sonnet | Opus | None>
Reviewer Model: <Haiku | Sonnet | Opus | Fable | None>
**Priority**: <P0 | P1 | P2 | P3>
**Effort**: <S | M | L | XL>
**ADR required**: <no | yes → docs/adr/NNNN-slug.md>
**Related**: <#refs>

<!--
  Model = which Claude model should IMPLEMENT this (routing hint). None = no AI impl.
  Reviewer Model = which model conducts the INDEPENDENT review — spun off as a SEPARATE agent
    (fresh context, never the implementer reviewing itself; prefer a different model for independence).
    None = trivial change, no independent review. See docs/REVIEW_WORKFLOW.md.
  ADR required = yes for an installer-architecture / manifest-format / distribution decision
  (reserve the ADR path now; see docs/ADR_GUIDE.md). Priority/Effort mirror the issue labels.
-->

### Problem
<!-- One paragraph: what's wrong or needed, and why. Fold rationale in — no editorial prose. -->

### Proposed design
<!-- (installer/manifest issues) the approach to ratify; cite the reserved ADR path. Delete if trivial. -->

### Work
<!-- Concrete steps. New skill = skills/<name>.md + ALL_SKILLS entry + README row. -->

### Acceptance Criteria
- [ ] <!-- concrete, testable condition -->
- [ ] `validate` CI green (shellcheck + skill manifest checks)

### Blast radius
<!-- (refactors only) what could break. Delete if N/A. -->

### Related
<!-- #refs · ADR path -->
