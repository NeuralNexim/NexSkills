# NexSkills

A collection of generic Copilot CLI skill files for software development
workflows, installable into any project via a single `curl | bash` command.

## Quick start

```bash
# Install all skills into .claude/commands/ in your project
curl -fsSL https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/install.sh | bash
```

Or install specific skills only:

```bash
curl -fsSL https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/install.sh | bash -s -- \
  --skills peer-review,implement-review
```

### Options

| Flag | Description |
|------|-------------|
| `--target DIR` | Install into a custom directory (default: `.claude/commands`) |
| `--skills NAMES` | Comma-separated skill names to install (default: all) |
| `--list` | Print available skills and exit |
| `--force` | Overwrite existing skill files |

## Available skills

### `/implement-next`
Reads `plan/status.md` to find the next pending task, then implements it
end-to-end: syncs with the integration branch, creates a feature branch,
executes the plan, runs tests, and triggers a peer review.

### `/peer-review`
Launches a `claude-opus-4.7` code-review agent against the current branch
diff and writes a structured review report to `plan/reviews/`. Uses
`plan/implementation-rules.md` for project-specific constraints.

### `/implement-review`
Reads the current branch's review file, implements all BLOCKING fixes,
adds tests to maintain ≥ 95% coverage, and updates the resolution log.
Re-runs peer review to confirm zero blocking issues remain.

### `/plan-milestone`
Analyses the project roadmap and produces a complete set of structured
implementation-detail plan files for the next milestone, split into
three sub-phases (a / b / c).

### `/show-changes`
Scans the current branch diff for new and updated public-facing symbols
(CLI commands, public functions, modules, API endpoints) and displays a
formatted human-readable changelog.

## How skills work

Each skill is a Markdown file that contains a structured prompt template.
The GitHub Copilot CLI reads `.claude/commands/*.md` and makes each file
available as a `/command-name` slash command in the chat interface.

Skills are project-agnostic — they detect the project's language and
conventions at runtime by reading `plan/implementation-rules.md` and the
existing codebase structure.

## Compatibility

- **GitHub Copilot CLI** (terminal agent)
- **VS Code Copilot** (with `.claude/commands/` support)
- Requires: `git`, internet access for `/implement-next` branch sync

## Updating

Re-run the installer with `--force` to pull the latest version of all skills:

```bash
curl -fsSL https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/install.sh | bash -s -- --force
```

## License

MIT — see [LICENSE](LICENSE).
