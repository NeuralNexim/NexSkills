# Engineering Standards & Policies

> Installed by ai-dev-framework v0.3.2. Portable core — project-agnostic process rules.
> Project facts live in `CLAUDE.md`; on conflict, `CLAUDE.md` wins for project facts, this
> file wins for process.

---

## 1. Commit convention (milestone style)

```
one-line summary (freeform / scope-prefixed; no ticket required)
```

Example: `installer: add uninstall support`. Always:

- **One line only** — no body, no blank lines, **no trailers**.
- **No PII** — no real names, no personal emails, no `Co-authored-by`, no tool-attribution
  trailers, in commits *or* PR bodies.
- `(closes #N)` inline when the change resolves a tracked issue.

## 2. Branch & PR flow (trunk)

```
feature/<name>  →  main
```

- Always branch **from `main`**; PR base is always `main`.
- Protected branch (never direct-push, never force-push): **main**.
- **0** required approvals (solo repo) — but a **PR is still required** and CI must be green.
  **Never merge without explicit human approval.**

## 3. Code quality

- Skills in `skills/` stay **self-contained and project-agnostic** — no hard-coded project
  paths or tool names (per `CLAUDE.md`).
- `install.sh` must pass **`shellcheck`** before commit/push (enforced by the git hooks).
- When adding a skill: add `skills/<name>.md`, register it in `ALL_SKILLS` in `install.sh`,
  and document it in `README.md` — CI (`validate`) enforces all three.
- No secrets in the repo. Comment **why**, not **what**; no commented-out code.

## 4. Testing / validation standard

- The `validate` CI job is the gate: `shellcheck install.sh` + every declared skill file
  exists + README documents each skill. Keep it green.
- Run `shellcheck install.sh` locally before pushing — the pre-commit/pre-push hooks do too.

## 5. Documentation routing

| What changed | Where |
|--------------|-------|
| Project-wide process rule | `CLAUDE.md` §Conventions |
| Architecture decision | `docs/adr/ADR-NNNN-*.md` |
| A skill's behaviour | the skill's own `skills/<name>.md` |
| User-facing install/usage | `README.md` |

## 6. ADR policy

- Required for: installer architecture change, multi-tool wrapper scheme, skill-manifest
  format change, a new distribution channel.
- Not required for: adding a skill, wording tweaks, docs updates.
- `docs/adr/ADR-NNNN-slug.md`; frozen on merge; supersede with a new ADR. Guide: `ADR_GUIDE.md`.

## 7. Session discipline (AI agents)

- Load `CLAUDE.md` + `docs/AI_RULES.md` before touching code.
- Branch from `main` before writing; keep a clean `git status` on shared branches.
- Never `--no-verify`, never force-push `main`, never bypass signing — fix the hook.

## 8. Enforcement (two layers)

1. **Local git hooks** (`.githooks/`, `core.hooksPath`) — block direct commit/push to `main`,
   validate branch name + one-line commit, run `shellcheck install.sh`. Bypassable with
   `--no-verify`.
2. **GitHub ruleset** (`.github/rulesets/protect-default.json`, `bypass_actors: []`) — the
   authoritative gate: PR required, `validate` green, threads resolved, force-push + deletion
   blocked. Nobody bypasses.
