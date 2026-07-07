# ADR Guide

An **Architecture Decision Record** captures one significant engineering decision, its context,
and its consequences — so future readers (human or agent) understand *why*, not just *what*.

## When you need one

Required: installer architecture change, multi-tool wrapper scheme, skill-manifest/`ALL_SKILLS`
format change, a new distribution channel or versioning policy.
Not required: adding a skill, wording tweaks, docs updates.

## Rules

- One decision per ADR. Filename: `docs/adr/ADR-NNNN-short-slug.md`.
- **Frozen on merge.** To change a decision, write a new ADR that supersedes it; never edit a
  merged ADR's decision.
- Keep it short. Long rationale lives here so code can cite `# see ADR-NNNN`.

## Template

```markdown
# ADR-NNNN: <short decision title>

- **Status:** Proposed | Accepted | Superseded by ADR-MMMM
- **Date:** YYYY-MM-DD
- **Issue:** #N (if any)

## Context
What forces are at play? State the facts, not the conclusion.

## Decision
The choice made, stated plainly. "We will …".

## Consequences
What gets easier, what gets harder, what is now forbidden. Blast radius + follow-ups.

## Alternatives considered
Each rejected option in a sentence, with why it lost.
```
