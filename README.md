# NexSkills

A collection of generic AI skill files for software development workflows,
installable into any project in seconds. Skills are installed for **Claude**,
**VS Code Copilot**, **Copilot CLI**, **Gemini**, and **Gemini CLI**
simultaneously.

## Installation

### Linux / macOS

```bash
# Install all skills
curl -fsSL https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/install.sh | bash
```

Install specific skills only:

```bash
curl -fsSL https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/install.sh | \
  bash -s -- --skills peer-review,implement-review
```

---

### Windows (PowerShell — native, no bash required)

```powershell
irm https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/install.ps1 | iex
```

Install specific skills only:

```powershell
.\install.ps1 -Skills peer-review,implement-review
```

---

### Python (any OS)

```bash
curl -fsSL https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/install.py | python3 -
```

---

### Installer options

| Flag (bash) | Flag (PowerShell) | Description |
|---|---|---|
| `--skills NAMES` | `-Skills NAMES` | Comma-separated list of skills (default: all) |
| `--list` | `-List` | Print available skills and exit |
| `--uninstall` | `-Uninstall` | Remove previously installed skill files |
| `--force` | `-Force` | Overwrite existing skill files |

---

## Installed paths

Each skill creates files in **all** of the following locations:

| Path | Purpose |
|---|---|
| `.nexskills/<name>.md` | Canonical procedure (source of truth — all tools read this) |
| `.claude/commands/<name>.md` | Claude CLI command |
| `.claude/prompts/<name>.lnk` | Claude CLI prompt symlink |
| `.github/copilot-instructions/<name>/SKILL.md` | VS Code Copilot skill wrapper |
| `.copilot/skills/<name>.md` | Copilot CLI loader |
| `.gemini/skills/<name>.md` | Gemini VS Code loader |
| `.gemini/commands/<name>.md` | Gemini CLI loader |

---

## Uninstalling

**Linux / macOS:**

```bash
bash install.sh --uninstall
# or remove specific skills:
bash install.sh --uninstall --skills peer-review
```

**Windows (PowerShell):**

```powershell
.\install.ps1 -Uninstall
# or remove specific skills:
.\install.ps1 -Uninstall -Skills peer-review
```

**Python:**

```bash
python3 install.py --uninstall
python3 install.py --uninstall --skills peer-review
```

---

## Available skills

### `/implement-next`
Reads `plan/status.md` to find the next pending task, then implements it
end-to-end: syncs with the integration branch, creates a feature branch,
executes the plan, runs tests, and triggers a peer review.

### `/peer-review`
Launches a code-review agent against the current branch diff and writes a
structured review report to `plan/reviews/`. Uses `plan/implementation-rules.md`
for project-specific constraints.

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

---

## How skills work

Each skill is a Markdown file stored in `.nexskills/`. The installer writes
thin loader/wrapper files for each AI tool so every tool reads the same
canonical procedure. Wrappers never duplicate the procedure — they instruct the
AI to load it at runtime via its file-reading tool.

Skills are project-agnostic — they detect the project's language and conventions
at runtime by reading `plan/implementation-rules.md` and the existing codebase.

## Updating

Re-run the installer with `--force` / `-Force` to pull the latest version of
all skills.

```bash
# Linux / macOS
curl -fsSL https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/install.sh | bash -s -- --force

# Windows PowerShell
.\install.ps1 -Force
```


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

Re-run the installer with `--force` to pull the latest version of all skills.

**Linux / macOS / WSL:**

```bash
curl -fsSL https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/install.sh | bash -s -- --force
```

**Windows (PowerShell — manual):**

```powershell
$base = "https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/skills"
$dest = ".claude\commands"
@("implement-next","peer-review","implement-review","plan-milestone","show-changes") | ForEach-Object {
    Invoke-WebRequest "$base/$_.md" -OutFile "$dest\$_.md" -Force
    Write-Host "Updated $_"
}
```

## License

MIT — see [LICENSE](LICENSE).
