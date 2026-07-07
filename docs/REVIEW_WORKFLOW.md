# Review Workflow — NexSkills

The canonical PR-review process. Reviewers post **COMMENT-event** inline reviews; **approval + merge
stay with the owner** — never auto-approve or merge.
_(Wiki mode: this lives at `_wiki/Reviewer-Workflow.md`.)_

## Who reviews — an INDEPENDENT agent

The review is conducted by a **separate agent, spun off fresh**, per the issue's `Reviewer Model:`
header — **not the implementer reviewing its own work.** Prefer a *different model* from the one that
implemented (`Model:`) for genuine independence — a fresh perspective catches what self-review
structurally can't. `Reviewer Model: None` is only for trivial changes that need no independent pass.
The implementer's job is to *trigger* this review and *address* its findings, not to perform it.

## Step 0 — Triage the lane (from the *actual diff*)

| Lane | The PR is… | Signals |
|------|-----------|---------|
| **A — Code** | any change that can alter runtime behaviour | edits under `skills/` or entry points; new/changed logic; tests asserting new behaviour; config/schema feeding code paths |
| **B — Docs-only** | text with no behavioural effect | only `.md` / `docs/` / ADRs / `CLAUDE.md`; comment- or docstring-only edits |
| **C — Small mechanical** | small, fully-prescribed, low-judgment | move a hardcoded value into config; find/replace a symbol; add an already-specified clause/flag; dependency bump — bounded blast radius, **no design decision** |

When unsure, go heavier.

## Lane A — Code (full 3 stages)
1. **Mechanical review** — run `/code-review` (or the `pr-review` subagent) on the PR head.
2. **Conformance** — does it match the issue's intent + acceptance criteria, and any governing ADR?
3. **Inline comments** — post every concrete in-diff finding as an inline COMMENT anchored to
   `file:line`. PR-scope / out-of-diff observations go in a single summary banner comment.

## Lane B — Docs-only
1. Content accuracy & consistency · 2. Issue/ADR conformance · 3. Inline comments.

## Lane C — Small mechanical
1. Completeness & correctness sweep · 2. Issue conformance · 3. Inline comments.

## Verification checklist (run in every lane)

- [ ] Commit/PR title matches the repo's commit convention; one line; no trailers; no PII
- [ ] PR base + branch correct; body has `closes`/`refs #N`
- [ ] Required CI checks green; **claimed fixes verified at HEAD**, not from the commit message
- [ ] After any merge/rebase: grepped the diff for conflict markers; both sides survived
- [ ] No secrets; ADR present if this is an architecture change

## Output — the review deliverable

**1. Findings table**

| # | Sev | File:Line | Finding | Recommended action |
|---|-----|-----------|---------|--------------------|
|   |     |           |         |                    |

**2. Implementation prompt** — a concise prompt the implementer can act on to resolve the blocking
findings (so the fix round is unambiguous).

## Fix rounds & implementer disagreement (the loop must close)

Review is a **two-way loop**, not a one-shot verdict.

- **Implementer addresses a finding:** reply on that thread with the **fix commit hash** (real,
  post-push), then re-request review. Don't resolve the thread yourself — the reviewer does, after
  re-checking at HEAD.
- **Implementer DISAGREES with a finding:** do **not** silently dismiss or unilaterally "diverge."
  Reply on the thread with your **rationale + the design intent/constraint the reviewer may not have
  had** (e.g. "this is intentional because X"). This goes **back to the reviewer**, whose job is to
  **update their understanding and re-assess** — either withdraw/soften the finding, or restate it
  with a sharper argument. The finding isn't closed until reviewer + implementer converge.
- **Reviewer, on receiving a disagreement:** treat it as new information, re-review that point with
  the corrected understanding, and respond explicitly (accept / refine / maintain-with-reason). A
  finding you drop should say *why* it no longer holds.
- **Partial acceptance / deferral:** if a finding is valid but out of scope, say so explicitly, file
  a follow-up issue, and record the deferral + reason — don't leave it as a silent non-fix.

Escalate to the owner only when reviewer and implementer can't converge after exchanging rationale.

## Session-end reviewer handover

Append a dated entry to `docs/REVIEWER_LOG.md` (or `_wiki/Reviewer-Handover.md` in wiki mode):
PRs reviewed, verdicts, open follow-ups. **Reviewers write the reviewer log, not the handover log.**
