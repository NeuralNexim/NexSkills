# install.ps1 — NexSkills installer for Windows
# Usage: .\install.ps1 [OPTIONS]
# Or (run without cloning):
#   irm https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/install.ps1 | iex
#
# Options:
#   -Target  <dir>     Install directory (default: .claude\commands)
#   -Skills  <names>   Comma-separated list of skills to install (default: all)
#   -List              List available skills and exit
#   -Force             Overwrite existing skill files
#   -Help              Show this message
[CmdletBinding()]
param(
    [string]   $Target  = '.claude\commands',
    [string]   $Skills  = '',
    [switch]   $List,
    [switch]   $Force,
    [switch]   $Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$REPO_RAW   = 'https://raw.githubusercontent.com/NeuralNexim/NexSkills/main'
$PROMPTS_DIR = '.claude\prompts'

$ALL_SKILLS = @(
    'implement-next'
    'peer-review'
    'implement-review'
    'plan-milestone'
    'show-changes'
)

# ── helpers ────────────────────────────────────────────────────────────────────

function Write-Info    { param($msg) Write-Host "[NexSkills] $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "[NexSkills] $msg" -ForegroundColor Green }
function Write-Warn    { param($msg) Write-Host "[NexSkills] WARNING: $msg" -ForegroundColor Yellow }
function Write-Err     { param($msg) Write-Host "[NexSkills] ERROR: $msg" -ForegroundColor Red; exit 1 }

function Show-Usage {
    @"
Usage: .\install.ps1 [OPTIONS]

Install NexSkills Copilot CLI skill files into a project.

Options:
  -Target <dir>     Install directory (default: .claude\commands)
  -Skills <names>   Comma-separated list of skills to install (default: all)
  -List             List available skills and exit
  -Force            Overwrite existing skill files
  -Help             Show this message

Available skills: $($ALL_SKILLS -join ', ')

Example:
  .\install.ps1 -Skills peer-review,implement-review -Target .claude\commands
  .\install.ps1 -Force
"@
}

function Show-Skills {
    Write-Host 'Available NexSkills:'
    foreach ($skill in $ALL_SKILLS) {
        Write-Host ("  {0,-20}  {1}/skills/{2}.md" -f $skill, $REPO_RAW, $skill)
    }
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

# ── create directories ─────────────────────────────────────────────────────────

try {
    New-Item -ItemType Directory -Force -Path $Target      | Out-Null
    New-Item -ItemType Directory -Force -Path $PROMPTS_DIR | Out-Null
} catch {
    Write-Err "Failed to create directories: $_"
}

# ── install ────────────────────────────────────────────────────────────────────

Write-Info "Installing $($selected.Count) skill(s) -> $Target"

$ok = $skip = $fail = 0

foreach ($skill in $selected) {
    $dest        = Join-Path $Target "$skill.md"
    $url         = "$REPO_RAW/skills/$skill.md"
    $symlinkDest = Join-Path $PROMPTS_DIR "$skill.lnk"

    if (Test-Path $dest) {
        if (-not $Force) {
            Write-Warn "Skipping $skill.md (already exists - use -Force to overwrite)"
            $skip++
            continue
        }
        Remove-Item $dest -Force
    }

    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
        Write-Success "Installed $skill.md"
        $ok++
    } catch {
        Write-Warn "Failed to download $skill.md : $_"
        $fail++
        continue
    }

    # Symlink: requires Developer Mode or admin on Windows
    try {
        if (Test-Path $symlinkDest) { Remove-Item $symlinkDest -Force }
        $rel = [System.IO.Path]::GetRelativePath($PROMPTS_DIR, $dest)
        New-Item -ItemType SymbolicLink -Path $symlinkDest -Target $rel | Out-Null
    } catch {
        Write-Warn "Could not create symlink for $skill (enable Developer Mode or run as Administrator): $_"
    }
}

# ── summary ────────────────────────────────────────────────────────────────────

Write-Host ''
Write-Info "Done. Installed: $ok  Skipped: $skip  Failed: $fail"
