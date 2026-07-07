# NexSkills — Copilot CLI Instructions

NexSkills is a collection of generic Copilot CLI skill files for software
development workflows.  Skills are plain Markdown files stored in `skills/`
and installed into projects via `install.sh`.

<!-- ai-dev-framework:begin v0.8.1 -->

## 1. Read first

Before touching code, load:
- `docs/AI_RULES.md` — behavioural contract (no PII, no unauthorized merge, plan-first)
- `docs/STANDARDS.md` — commit / branch / PR / issue / ADR / CI standards

## 2. Environment

- **Default branch (PR base):** `main`
- **Release branch:** `main`
- **Stack:** other · source in `skills/` · tests in `tests/`

## 3. Commit convention (milestone)

```
one-line summary (project milestone/prefix style); no ticket required
```

Example: `M9: summit boss phase-2 attack pattern`. One line, no trailers, no PII.

## 4. Branch & PR (trunk)

- Feature branches: `feature/…`; always branch from `main`.
- PR base is always `main`; body must contain `closes #N`.
- Protected branches (never direct-push): main.
- ≥ 0 approval. **Never merge without explicit human approval.**

## 5. Local gates (all green before PR)

```
shellcheck install.sh
true   # no typecheck for this stack
true   # no test framework for this stack
true   # no security gate for this stack
```

Diff coverage ≥ 90%.

## 6. ADR

Required for new modules/stages, schema changes, algorithm/data-policy/infra decisions.
`docs/adr/ADR-NNNN-slug.md`; frozen on merge; guide in `docs/ADR_GUIDE.md`.

## 7. Subagents

| Task | Subagent |
|------|----------|
| First-pass PR review | `pr-review` |
| Log / failure triage | `log-triage` |

<!-- ai-dev-framework:end -->


## Repository structure

```
skills/          Skill Markdown files (one per /command)
install.sh       curl-installable installer script
README.md        User-facing documentation
CLAUDE.md        This file
.github/
  workflows/
    ci.yml       CI: shellcheck + markdown validation
```

## Conventions

- Each skill in `skills/` is named exactly `<command-name>.md` where
  `<command-name>` matches the slash command the user invokes.
- Skills must be self-contained and project-agnostic.  They may reference
  `plan/status.md`, `plan/implementation-rules.md`, and standard git commands,
  but must not hard-code project-specific paths or tool names.
- `install.sh` declares `ALL_SKILLS` — add new skill names there when adding
  a new skill file.
- Use `shellcheck` to validate `install.sh` before committing.

## Adding a new skill

1. Write `skills/<name>.md` — follow the section structure of existing skills.
2. Add `"<name>"` to the `ALL_SKILLS` array in `install.sh`.
3. Add a row to the "Available skills" table in `README.md`.
4. Push — CI will validate the script and confirm the file exists.

## Release tagging

Tag releases as `vMAJOR.MINOR.PATCH` with a matching GitHub Release.
The installer always pulls from `main` — tagged releases are for auditability.
