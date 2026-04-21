# NexSkills

A collection of generic Copilot CLI skill files for software development
workflows, installable into any project in seconds.

## Installation

### Linux / macOS

```bash
# Install all skills into .claude/commands/ in your project
curl -fsSL https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/install.sh | bash
```

Install specific skills only:

```bash
curl -fsSL https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/install.sh | bash -s -- \
  --skills peer-review,implement-review
```

Install into a custom directory:

```bash
curl -fsSL https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/install.sh | bash -s -- \
  --target ~/myproject/.claude/commands
```

---

### Windows (PowerShell)

```powershell
# Install all skills into .claude\commands\ in your project
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/install.sh" `
  -OutFile "$env:TEMP\nexskills-install.sh"
bash "$env:TEMP\nexskills-install.sh"
```

> **Requires** Git Bash, WSL, or any shell that provides `bash` and `curl`.
> Git for Windows includes both — download from https://git-scm.com/download/win

Install specific skills only (Git Bash / WSL):

```bash
bash "$TEMP/nexskills-install.sh" --skills peer-review,implement-review
```

---

### Windows (WSL)

Open your WSL terminal and run the same command as Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/install.sh | bash
```

To install into a Windows-side project from WSL, use the mounted path:

```bash
curl -fsSL https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/install.sh | \
  bash -s -- --target /mnt/c/Users/$USER/myproject/.claude/commands
```

---

### Manual install (any OS)

If you cannot run shell scripts, download skill files directly and place them
in your project's `.claude/commands/` directory:

```
https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/skills/implement-next.md
https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/skills/peer-review.md
https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/skills/implement-review.md
https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/skills/plan-milestone.md
https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/skills/show-changes.md
```

On Windows you can do this with PowerShell (no shell required):

```powershell
$base = "https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/skills"
$dest = ".claude\commands"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
@("implement-next","peer-review","implement-review","plan-milestone","show-changes") | ForEach-Object {
    Invoke-WebRequest "$base/$_.md" -OutFile "$dest\$_.md"
    Write-Host "Installed $_"
}
```

---

### Installer options

| Flag | Description |
|------|-------------|
| `--target DIR` | Install into a custom directory (default: `.claude/commands`) |
| `--skills NAMES` | Comma-separated list of skills to install (default: all) |
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
