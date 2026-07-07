# GitHub Copilot Instructions — NexSkills

> Loaded automatically before every AI session in this repo.
> Full standards: `docs/AI_RULES.md` · `docs/STANDARDS.md`.

<!-- ai-dev-framework:begin v0.8.1 -->

## Before any code

1. Confirm the tracking issue exists (create with required labels + header block if not).
2. Create/confirm the ADR if the change is a new module/stage, schema, algorithm, data policy,
   or infra decision.
3. Branch from `main`:
   `git checkout main && git pull && git checkout -b feature/<name>`
4. Implement **only** the selected task.

## Non-negotiable

- No duplicate code; stream/batch large data; minimal scope; pinned deps.
- Tests ≥ 90% diff coverage, written with the code.
- No secrets; no PII in commits/PRs/comments/trailers; commit + PR title one line, no trailers.
- Commit style (milestone): `one-line summary (project milestone/prefix style); no ticket required` — e.g. `M9: summit boss phase-2 attack pattern`.

## PR

- Title matches the commit style above; base `main`; body has `closes #N`.
- All CI gates green: `lint`, `typecheck`, `tests`, `security-scan`.
- ≥ 0 approval. Never self-merge without explicit human approval.

## CI gates that must pass

| Job | Command |
|-----|---------|
| lint | `shellcheck install.sh` |
| typecheck | `true   # no typecheck for this stack` |
| tests | `true   # no test framework for this stack` |
| security-scan | `true   # no security gate for this stack` |

<!-- ai-dev-framework:end -->
