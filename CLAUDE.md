# NexSkills — Copilot CLI Instructions

NexSkills is a collection of generic Copilot CLI skill files for software
development workflows.  Skills are plain Markdown files stored in `skills/`
and installed into projects via `install.sh`.

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
