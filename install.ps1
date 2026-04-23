# install.ps1 — NexSkills installer for Windows
# Usage: .\install.ps1 [OPTIONS]
# Or (run without cloning):
#   irm https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/install.ps1 | iex
#
# Options:
#   -Skills  <names>   Comma-separated list of skills to install (default: all)
#   -List              List available skills and exit
#   -Uninstall         Remove previously installed skill files
#   -Force             Overwrite existing skill files
#   -Help              Show this message
[CmdletBinding()]
param(
    [string]   $Skills    = '',
    [switch]   $List,
    [switch]   $Uninstall,
    [switch]   $Force,
    [switch]   $Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$REPO_RAW = 'https://raw.githubusercontent.com/NeuralNexim/NexSkills/main'

# Marker written into every generated file so conflicts can be detected
$NEXSKILLS_MARKER = '<!-- nexskills:managed -->'

# .gitignore section delimiters
$GI_START = '# >>> NexSkills managed — do not edit between these markers'
$GI_END   = '# <<< NexSkills'
$GI_PATHS = @(
    '.nexskills/'
    '.claude/commands/'
    '.claude/prompts/'
    '.github/copilot-instructions/'
    '.copilot/'
    '.gemini/'
)
$NEXSKILLS_DIR   = '.nexskills'
$CLAUDE_DIR      = '.claude\commands'
$CLAUDE_PROMPTS  = '.claude\prompts'
$COPILOT_DIR     = '.github\copilot-instructions'
$COPILOT_CLI_DIR = '.copilot\skills'
$GEMINI_DIR      = '.gemini\skills'
$GEMINI_CLI_DIR  = '.gemini\commands'

$ALL_SKILLS = @(
    'implement-next'
    'peer-review'
    'implement-review'
    'plan-milestone'
    'show-changes'
)

$SKILL_DESCRIPTIONS = @{
    'implement-next'   = 'Implement the next milestone task from the project plan. WHEN: implement next, start next task, /implement-next, begin implementation, next feature, continue development.'
    'peer-review'      = 'Run structured code review against the current branch diff. WHEN: peer review, code review, review changes, /peer-review, review my code, review diff.'
    'implement-review' = 'Fix BLOCKING issues from a peer-review. WHEN: implement review, fix review comments, address blocking issues, /implement-review, resolve review.'
    'plan-milestone'   = 'Analyse roadmap and generate structured implementation plan files for the next milestone. WHEN: plan milestone, generate plan, /plan-milestone, create plan.'
    'show-changes'     = 'Scan the current branch diff for new and updated public-facing symbols. WHEN: show changes, what changed, list changes, /show-changes, display changes.'
}

$SKILL_HINTS = @{
    'implement-next'   = 'Optional: milestone ID or leave blank to pick from plan/status.md'
    'peer-review'      = 'Optional: branch name or leave blank to review current branch'
    'implement-review' = 'Optional: path to review file, or leave blank to auto-detect'
    'plan-milestone'   = 'Optional: milestone ID or description to plan'
    'show-changes'     = 'Optional: branch name or leave blank to use current branch'
}

# ── helpers ────────────────────────────────────────────────────────────────────

function Write-Info    { param($msg) Write-Host "[NexSkills] $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "[NexSkills] $msg" -ForegroundColor Green }
function Write-Warn    { param($msg) Write-Host "[NexSkills] WARNING: $msg" -ForegroundColor Yellow }
function Write-Err     { param($msg) Write-Host "[NexSkills] ERROR: $msg" -ForegroundColor Red; exit 1 }

function Show-Usage {
    @"
Usage: .\install.ps1 [OPTIONS]

Install (or uninstall) NexSkills into a project across multiple AI tools.

Options:
  -Skills <names>   Comma-separated list of skills (default: all)
  -List             List available skills and exit
  -Uninstall        Remove previously installed skill files
  -Force            Overwrite existing skill files (install only)
  -Help             Show this message

Installed paths per skill:
  .nexskills\<name>.md                        — canonical procedure (all tools read this)
  .claude\commands\<name>.md                  — Claude CLI command
  .claude\prompts\<name>.lnk                  — Claude CLI prompt symlink
  .github\copilot-instructions\<name>\SKILL.md — VS Code Copilot skill wrapper
  .copilot\skills\<name>.md                   — Copilot CLI loader
  .gemini\skills\<name>.md                    — Gemini (VS Code) loader
  .gemini\commands\<name>.md                  — Gemini CLI loader

Example:
  .\install.ps1 -Skills peer-review,implement-review
  .\install.ps1 -Uninstall -Skills peer-review
  .\install.ps1 -Uninstall   # removes all skills
"@
}

function Show-Skills {
    Write-Host 'Available NexSkills:'
    foreach ($skill in $ALL_SKILLS) {
        Write-Host ("  {0,-20}  {1}/skills/{2}.md" -f $skill, $REPO_RAW, $skill)
    }
}

function Write-CopilotWrapper($skill, $nexskillsPath, $dir) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $title       = (Get-Culture).TextInfo.ToTitleCase($skill.Replace('-', ' '))
    $description = if ($SKILL_DESCRIPTIONS.ContainsKey($skill)) { $SKILL_DESCRIPTIONS[$skill] } else { "$title skill workflow." }
    $hint        = if ($SKILL_HINTS.ContainsKey($skill))        { $SKILL_HINTS[$skill] }        else { '' }
    $content = @"
---
name: $skill
description: "$description"
argument-hint: "$hint"
---

$NEXSKILLS_MARKER

# $title

Read the complete procedure from ``$nexskillsPath`` using the ``read_file`` tool,
then follow every step in that file precisely and in order.

**Do not paraphrase, skip, or reorder any steps.**
"@
    Set-Content -Path (Join-Path $dir 'SKILL.md') -Value $content -Encoding UTF8
}

function Write-GenericWrapper($skill, $nexskillsPath, $dest) {
    $title = (Get-Culture).TextInfo.ToTitleCase($skill.Replace('-', ' '))
    $content = @"
$NEXSKILLS_MARKER

# $title

Load and follow the complete procedure from ``$nexskillsPath``.
Read that file with your file-reading tool and execute every step
precisely and in order. Do not paraphrase, skip, or reorder any steps.
"@
    Set-Content -Path $dest -Value $content -Encoding UTF8
}

function Test-NexSkillsFile($path) {
    if (-not (Test-Path $path -PathType Leaf)) { return $false }
    try {
        $content = Get-Content $path -Raw -Encoding UTF8 -ErrorAction Stop
        return $content -like "*$NEXSKILLS_MARKER*"
    } catch { return $false }
}

function Get-ConflictPaths($skill) {
    # Only .nexskills/ can conflict; all loader files use nexskills- prefix
    return @(
        (Join-Path $NEXSKILLS_DIR   "$skill.md")
    )
}

function Test-AnyNexSkillsInstalled {
    foreach ($s in $ALL_SKILLS) {
        if (Test-Path (Join-Path $NEXSKILLS_DIR "$s.md") -PathType Leaf) { return $true }
    }
    return $false
}

function Update-Gitignore([bool]$add) {
    $gitignore = '.gitignore'
    $existing  = if (Test-Path $gitignore) { Get-Content $gitignore -Raw -Encoding UTF8 } else { '' }
    # Remove any existing NexSkills block
    $cleaned = $existing -replace '(?s)\r?\n?# >>> NexSkills managed.*?# <<< NexSkills\r?\n?', ''
    $cleaned = $cleaned.TrimEnd("`r","`n")
    if ($add) {
        $section = "`n`n$GI_START`n" + ($GI_PATHS -join "`n") + "`n$GI_END"
        [System.IO.File]::WriteAllText((Resolve-Path '.').Path + "\$gitignore", ($cleaned + $section + "`n"), [System.Text.Encoding]::UTF8)
    } else {
        $out = if ($cleaned) { $cleaned + "`n" } else { '' }
        [System.IO.File]::WriteAllText((Resolve-Path '.').Path + "\$gitignore", $out, [System.Text.Encoding]::UTF8)
    }
}

function Remove-IfExists($path) {
    if (Test-Path $path -PathType Leaf)      { Remove-Item $path -Force; return $true }
    if (Test-Path $path -PathType Container) { Remove-Item $path -Recurse -Force; return $true }
    return $false
}

# ── entry point ────────────────────────────────────────────────────────────────

if ($Help) { Show-Usage; exit 0 }
if ($List)  { Show-Skills; exit 0 }

# ── resolve selected skills ────────────────────────────────────────────────────

if ($Skills -ne '') {
    $selected = $Skills -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    $unknown  = $selected | Where-Object { $ALL_SKILLS -notcontains $_ }
    if ($unknown) {
        Write-Err "Unknown skill(s): $($unknown -join ', '). Use -List to see available skills."
    }
} else {
    $selected = $ALL_SKILLS
}

# ── uninstall ──────────────────────────────────────────────────────────────────

if ($Uninstall) {
    Write-Info "Uninstalling $($selected.Count) skill(s)..."
    $removedCount = 0
    foreach ($skill in $selected) {
        $paths = @(
            (Join-Path $NEXSKILLS_DIR   "$skill.md"),
            (Join-Path $CLAUDE_DIR      "nexskills-$skill.md"),
            (Join-Path $CLAUDE_PROMPTS  "nexskills-$skill.lnk"),
            (Join-Path $COPILOT_DIR     "nexskills-$skill"),
            (Join-Path $COPILOT_CLI_DIR "nexskills-$skill.md"),
            (Join-Path $GEMINI_DIR      "nexskills-$skill.md"),
            (Join-Path $GEMINI_CLI_DIR  "nexskills-$skill.md")
        )
        $removed = $false
        foreach ($p in $paths) {
            if (Remove-IfExists $p) { $removed = $true }
        }
        if ($removed) {
            Write-Success "Removed $skill"
            $removedCount++
        } else {
            Write-Warn "Nothing to remove for $skill (not installed)"
        }
    }
    if (-not (Test-AnyNexSkillsInstalled)) { Update-Gitignore $false }
    Write-Host ''
    Write-Info "Done. Removed: $removedCount skill(s)."
    exit 0
}

# ── install ────────────────────────────────────────────────────────────────────

Write-Info "Installing $($selected.Count) skill(s)..."

foreach ($dir in @($NEXSKILLS_DIR, $CLAUDE_DIR, $CLAUDE_PROMPTS, $COPILOT_DIR, $COPILOT_CLI_DIR, $GEMINI_DIR, $GEMINI_CLI_DIR)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

$ok = $skip = $fail = 0

foreach ($skill in $selected) {
    $nexskillsDest = Join-Path $NEXSKILLS_DIR "$skill.md"
    $url           = "$REPO_RAW/skills/$skill.md"

    # ── Conflict check: only .nexskills/ can conflict (prefixed loader files
    # use nexskills- prefix so they will never clash with user files) ──────────
    $conflicts = Get-ConflictPaths $skill | Where-Object {
        (Test-Path $_ -PathType Leaf) -and (-not (Test-NexSkillsFile $_))
    }
    if ($conflicts) {
        Write-Warn "Conflict: $nexskillsDest exists and is not a NexSkills file."
        Write-Host '  Move or remove it, or use -Force to overwrite.'
        $skip++
        continue
    }

    # ── 1. Download canonical copy into .nexskills/ ──────────────────────────────
    if ((Test-Path $nexskillsDest) -and (Test-NexSkillsFile $nexskillsDest) -and (-not $Force)) {
        Write-Warn "Skipping $skill (already installed — use -Force to overwrite)"
        $skip++
        continue
    }

    try {
        Invoke-WebRequest -Uri $url -OutFile $nexskillsDest -UseBasicParsing
    } catch {
        Write-Warn "Failed to download $skill : $_"
        $fail++
        continue
    }

    # ── 2. Claude CLI loader (nexskills-<skill>.md) ──────────────────────────
    $claudeDest = Join-Path $CLAUDE_DIR "nexskills-$skill.md"
    Write-GenericWrapper $skill $nexskillsDest $claudeDest
    try {
        $promptLink = Join-Path $CLAUDE_PROMPTS "nexskills-$skill.lnk"
        if (Test-Path $promptLink) { Remove-Item $promptLink -Force }
        $rel = [System.IO.Path]::GetRelativePath($CLAUDE_PROMPTS, $claudeDest)
        New-Item -ItemType SymbolicLink -Path $promptLink -Target $rel | Out-Null
    } catch {
        Write-Warn "Could not create Claude CLI symlink for $skill (enable Developer Mode or run as Administrator)"
    }

    # ── 3. VS Code Copilot SKILL.md wrapper ───────────────────────────────────
    Write-CopilotWrapper $skill $nexskillsDest (Join-Path $COPILOT_DIR "nexskills-$skill")

    # ── 4. Copilot CLI loader ─────────────────────────────────────────────────
    Write-GenericWrapper $skill $nexskillsDest (Join-Path $COPILOT_CLI_DIR "nexskills-$skill.md")

    # ── 5. Gemini (VS Code) loader ────────────────────────────────────────────
    Write-GenericWrapper $skill $nexskillsDest (Join-Path $GEMINI_DIR "nexskills-$skill.md")

    # ── 6. Gemini CLI loader ──────────────────────────────────────────────────
    Write-GenericWrapper $skill $nexskillsDest (Join-Path $GEMINI_CLI_DIR "nexskills-$skill.md")

    Write-Success "Installed $skill"
    $ok++
}

Update-Gitignore $true

# ── summary ────────────────────────────────────────────────────────────────────

Write-Host ''
Write-Info "Done. Installed: $ok  Skipped: $skip  Failed: $fail"

