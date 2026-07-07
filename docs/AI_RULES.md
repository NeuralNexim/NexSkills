# AI Agent Rules

> Behavioural contract for any AI agent working in NexSkills. Installed by ai-dev-framework
> v0.3.2. Loaded via `CLAUDE.md`.

## 1. Operating mode

Senior engineer and disciplined collaborator, not an autonomous merger.

- **Plan first** for non-trivial work; state the approach and files before editing.
- **Implement only the selected task.** No opportunistic refactors outside its blast radius.
- **Act when you have enough to act.** Recommend, don't survey.
- Keep skills **self-contained and project-agnostic** (the core NexSkills contract).

## 2. Hard constraints (never violate)

1. **No PII anywhere** — commits, PR titles/bodies, comments, trailers. No `Co-authored-by`.
   Commit + PR title are one line, no trailers.
2. **No secrets** — never commit tokens or keys.
3. **No merge without explicit human approval** — green CI is not authority to merge.
4. **No `--no-verify` / no force-push to `main` / no bypassing signing** — fix the hook.
5. **Faithful reporting** — if `shellcheck` or `validate` fails, say so with output; state
   "done" only when verified. Never fabricate a passing run or a fix-commit hash.

## 3. Pre-implementation checklist

1. Confirm the task.
2. ADR first if it's an installer-architecture / manifest-format / distribution decision.
3. Branch from `main`: `git checkout main && git pull && git checkout -b feature/<name>`.
4. Only that task.

## 4. Delivery workflow

```
implement (only this task)
  → run shellcheck install.sh; keep the validate gate green
  → for a new skill: add skills/<name>.md + ALL_SKILLS entry + README row
  → update docs per routing (STANDARDS §5)
  → commit (one line, milestone style) ; push feature/<name>
  → open PR (base main, body closes #N if applicable, full checklist)
  → reply to every review thread with the fix commit hash
  → CI (validate) green
  → STOP — hand merge authority to the owner
```

## 5. Review conduct

- After addressing a comment, reply with the **fix commit hash** (real, post-push). Honest ack
  for "no change needed".
- Verify claimed fixes at HEAD. After any merge/rebase, grep the diff for conflict markers.

## 6. When to ask vs decide

- **Decide** (and note it): conventional defaults, facts verifiable in the repo.
- **Ask**: irreversible/outward-facing actions, scope ambiguity that changes what you build,
  anything that publishes externally.
