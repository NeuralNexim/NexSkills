#!/usr/bin/env bash
# install.sh — NexSkills installer
# Usage: curl -fsSL https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/install.sh | bash
# Or:    bash install.sh [--skills NAMES] [--list] [--uninstall] [--force]
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/NeuralNexim/NexSkills/main"

# Marker written into every generated file so conflicts can be detected
NEXSKILLS_MARKER="<!-- nexskills:managed -->"

# .gitignore section delimiters
GI_START="# >>> NexSkills managed \u2014 do not edit between these markers"
GI_END="# <<< NexSkills"
GI_PATHS=(
    ".nexskills/"
    ".claude/commands/"
    ".claude/prompts/"
    ".github/copilot-instructions/"
    ".copilot/"
    ".gemini/"
)

# Install directories
NEXSKILLS_DIR=".nexskills"
CLAUDE_DIR=".claude/commands"
CLAUDE_PROMPTS=".claude/prompts"
COPILOT_DIR=".github/copilot-instructions"
COPILOT_CLI_DIR=".copilot/skills"
GEMINI_DIR=".gemini/skills"
GEMINI_CLI_DIR=".gemini/commands"

ALL_SKILLS=(
    "implement-next"
    "peer-review"
    "implement-review"
    "plan-milestone"
    "show-changes"
)

# ── portable per-skill metadata ────────────────────────────────────────────────

_skill_description() {
    case "$1" in
        implement-next)    echo "Implement the next milestone task from the project plan. WHEN: implement next, start next task, /implement-next, begin implementation, next feature, continue development." ;;
        peer-review)       echo "Run structured code review against the current branch diff. WHEN: peer review, code review, review changes, /peer-review, review my code, review diff." ;;
        implement-review)  echo "Fix BLOCKING issues from a peer-review. WHEN: implement review, fix review comments, address blocking issues, /implement-review, resolve review." ;;
        plan-milestone)    echo "Analyse roadmap and generate structured implementation plan files for the next milestone. WHEN: plan milestone, generate plan, /plan-milestone, create plan." ;;
        show-changes)      echo "Scan the current branch diff for new and updated public-facing symbols. WHEN: show changes, what changed, list changes, /show-changes, display changes." ;;
        *)                 echo "${1} skill workflow." ;;
    esac
}

_skill_hint() {
    case "$1" in
        implement-next)    echo "Optional: milestone ID or leave blank to pick from plan/status.md" ;;
        peer-review)       echo "Optional: branch name or leave blank to review current branch" ;;
        implement-review)  echo "Optional: path to review file, or leave blank to auto-detect" ;;
        plan-milestone)    echo "Optional: milestone ID or description to plan" ;;
        show-changes)      echo "Optional: branch name or leave blank to use current branch" ;;
        *)                 echo "" ;;
    esac
}

SELECTED_SKILLS=()
LIST_ONLY=false
FORCE=false
UNINSTALL=false

# ── helpers ────────────────────────────────────────────────────────────────────

info()    { printf '\033[1;34m[NexSkills]\033[0m %s\n' "$*"; }
success() { printf '\033[1;32m[NexSkills]\033[0m %s\n' "$*"; }
warn()    { printf '\033[1;33m[NexSkills]\033[0m %s\n' "$*" >&2; }
error()   { printf '\033[1;31m[NexSkills]\033[0m ERROR: %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<EOF
Usage: install.sh [OPTIONS]

Install (or uninstall) NexSkills into a project across multiple AI tools.

Options:
  --skills NAMES        Comma-separated list of skills (default: all)
  --list                List available skills and exit
  --uninstall           Remove previously installed skill files
  --force               Overwrite existing skill files (install only)
  -h, --help            Show this message

Installed paths per skill:
  .nexskills/<name>.md                          canonical procedure (all tools read this)
  .claude/commands/<name>.md                    Claude CLI command
  .claude/prompts/<name>.lnk                    Claude CLI prompt symlink
  .github/copilot-instructions/<name>/SKILL.md  VS Code Copilot skill wrapper
  .copilot/skills/<name>.md                     Copilot CLI loader
  .gemini/skills/<name>.md                      Gemini (VS Code) loader
  .gemini/commands/<name>.md                    Gemini CLI loader

Example:
  bash install.sh --skills peer-review,implement-review
  bash install.sh --uninstall --skills peer-review
  bash install.sh --uninstall   # removes all skills
EOF
}

skill_exists_in_list() {
    local name="$1" skill
    for skill in "${ALL_SKILLS[@]}"; do
        [[ "$skill" == "$name" ]] && return 0
    done
    return 1
}

list_skills() {
    echo "Available NexSkills:"
    for skill in "${ALL_SKILLS[@]}"; do
        printf "  %-20s  %s/skills/%s.md\n" "$skill" "$REPO_RAW" "$skill"
    done
}

write_copilot_wrapper() {
    local skill="$1" nexskills_path="$2" skill_dir="$3"
    local skill_title description hint
    skill_title="$(echo "${skill//-/ }" | awk '{$1=toupper(substr($1,1,1))substr($1,2); print}')"
    description="$(_skill_description "$skill")"
    hint="$(_skill_hint "$skill")"
    mkdir -p "$skill_dir"
    cat > "$skill_dir/SKILL.md" <<SKILLEOF
---
name: ${skill}
description: "${description}"
argument-hint: "${hint}"
---

${NEXSKILLS_MARKER}

# ${skill_title}

Read the complete procedure from \`${nexskills_path}\` using the \`read_file\` tool,
then follow every step in that file precisely and in order.

**Do not paraphrase, skip, or reorder any steps.**
SKILLEOF
}

write_generic_wrapper() {
    local skill="$1" nexskills_path="$2" dest="$3"
    local skill_title
    skill_title="$(echo "${skill//-/ }" | awk '{$1=toupper(substr($1,1,1))substr($1,2); print}')"
    cat > "$dest" <<WRAPEOF
${NEXSKILLS_MARKER}

# ${skill_title}

Load and follow the complete procedure from \`${nexskills_path}\`.
Read that file with your file-reading tool and execute every step
precisely and in order. Do not paraphrase, skip, or reorder any steps.
WRAPEOF
}

is_nexskills_file() {
    local path="$1"
    [[ -f "$path" ]] || return 1
    grep -qF "$NEXSKILLS_MARKER" "$path" 2>/dev/null
}

conflict_paths() {
    local skill="$1"
    echo "$NEXSKILLS_DIR/$skill.md"
    echo "$CLAUDE_DIR/$skill.md"
    echo "$COPILOT_CLI_DIR/$skill.md"
    echo "$GEMINI_DIR/$skill.md"
    echo "$GEMINI_CLI_DIR/$skill.md"
    echo "$COPILOT_DIR/$skill/SKILL.md"
}

any_nexskills_installed() {
    local s
    for s in "${ALL_SKILLS[@]}"; do
        [[ -f "$NEXSKILLS_DIR/$s.md" ]] && return 0
    done
    return 1
}

update_gitignore() {
    local add="$1"  # true or false
    local gitignore=".gitignore"
    local existing="" cleaned section
    [[ -f "$gitignore" ]] && existing="$(cat "$gitignore")"
    # Strip any existing NexSkills block (requires perl for portable multi-line)
    if command -v perl &>/dev/null; then
        cleaned="$(printf '%s' "$existing" | perl -0777 -pe 's/\n?# >>> NexSkills managed.*?# <<< NexSkills\n?//s')"
    else
        cleaned="$existing"
    fi
    cleaned="${cleaned%%$'\n'}"
    cleaned="${cleaned%$'\n'}"
    if [[ "$add" == true ]]; then
        section=$'\n\n'
        section+="$GI_START"$'\n'
        for p in "${GI_PATHS[@]}"; do section+="$p"$'\n'; done
        section+="$GI_END"
        printf '%s%s\n' "$cleaned" "$section" > "$gitignore"
    else
        if [[ -n "$cleaned" ]]; then
            printf '%s\n' "$cleaned" > "$gitignore"
        else
            : > "$gitignore"
        fi
    fi
}

# ── argument parsing ────────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skills)
            [[ -n "${2-}" ]] || error "--skills requires a comma-separated list"
            IFS=',' read -ra SELECTED_SKILLS <<< "$2"; shift 2 ;;
        --list)
            LIST_ONLY=true; shift ;;
        --uninstall)
            UNINSTALL=true; shift ;;
        --force)
            FORCE=true; shift ;;
        -h|--help)
            usage; exit 0 ;;
        *)
            error "Unknown option: $1. Use -h for help." ;;
    esac
done

if $LIST_ONLY; then
    list_skills
    exit 0
fi

if [[ ${#SELECTED_SKILLS[@]} -eq 0 ]]; then
    SELECTED_SKILLS=("${ALL_SKILLS[@]}")
fi

for skill in "${SELECTED_SKILLS[@]}"; do
    skill_exists_in_list "$skill" || error "Unknown skill: '$skill'. Use --list to see available skills."
done

# ── uninstall ────────────────────────────────────────────────────────────────────

if $UNINSTALL; then
    info "Uninstalling ${#SELECTED_SKILLS[@]} skill(s)..."
    ok=0
    for skill in "${SELECTED_SKILLS[@]}"; do
        removed=false
        paths=(
            "$NEXSKILLS_DIR/$skill.md"
            "$CLAUDE_DIR/$skill.md"
            "$CLAUDE_PROMPTS/$skill.lnk"
            "$COPILOT_DIR/$skill"
            "$COPILOT_CLI_DIR/$skill.md"
            "$GEMINI_DIR/$skill.md"
            "$GEMINI_CLI_DIR/$skill.md"
        )
        for p in "${paths[@]}"; do
            if [[ -f "$p" || -L "$p" ]]; then rm -f "$p" && removed=true
            elif [[ -d "$p" ]]; then rm -rf "$p" && removed=true
            fi
        done
        if $removed; then
            success "Removed $skill"
            (( ok++ )) || true
        else
            warn "Nothing to remove for $skill (not installed)"
        fi
    done
    echo ""
    info "Done. Removed: $ok skill(s)."
    exit 0
fi

# ── install ─────────────────────────────────────────────────────────────────────

info "Installing ${#SELECTED_SKILLS[@]} skill(s)..."

mkdir -p "$NEXSKILLS_DIR" "$CLAUDE_DIR" "$CLAUDE_PROMPTS" \
         "$COPILOT_DIR" "$COPILOT_CLI_DIR" \
         "$GEMINI_DIR" "$GEMINI_CLI_DIR"

ok=0; skip=0; fail=0

for skill in "${SELECTED_SKILLS[@]}"; do
    nexskills_dest="$NEXSKILLS_DIR/$skill.md"
    url="$REPO_RAW/skills/$skill.md"

    # ── Conflict check: skip if any target is an existing non-NexSkills file ─────
    conflict_found=false
    while IFS= read -r p; do
        if [[ -f "$p" ]] && ! is_nexskills_file "$p"; then
            [[ "$conflict_found" == false ]] && warn "Conflict: $skill — existing user files found, skipping:"
            warn "  $p"
            conflict_found=true
        fi
    done < <(conflict_paths "$skill")
    if [[ "$conflict_found" == true ]]; then
        warn "  Rename or move those files first."
        (( skip++ )) || true
        continue
    fi

    # ── 1. Download canonical copy into .nexskills/ ──────────────────────────
    if [[ -f "$nexskills_dest" ]] && is_nexskills_file "$nexskills_dest" && ! $FORCE; then
        warn "Skipping $skill (already installed — use --force to overwrite)"
        (( skip++ )) || true
        continue
    fi

    downloaded=false
    if command -v curl &>/dev/null; then
        curl -fsSL "$url" -o "$nexskills_dest" && downloaded=true || true
    elif command -v wget &>/dev/null; then
        wget -qO "$nexskills_dest" "$url" && downloaded=true || true
    else
        error "Neither curl nor wget is available."
    fi

    if ! $downloaded; then
        warn "Failed to download $skill"
        (( fail++ )) || true
        continue
    fi

    # ── 2. Claude CLI ─────────────────────────────────────────────────────────
    cp "$nexskills_dest" "$CLAUDE_DIR/$skill.md"
    ln -sf "../../$nexskills_dest" "$CLAUDE_PROMPTS/$skill.lnk" 2>/dev/null || true

    # ── 3. VS Code Copilot SKILL.md wrapper ───────────────────────────────────
    write_copilot_wrapper "$skill" "$nexskills_dest" "$COPILOT_DIR/$skill"

    # ── 4. Copilot CLI loader ─────────────────────────────────────────────────
    write_generic_wrapper "$skill" "$nexskills_dest" "$COPILOT_CLI_DIR/$skill.md"

    # ── 5. Gemini (VS Code) loader ────────────────────────────────────────────
    write_generic_wrapper "$skill" "$nexskills_dest" "$GEMINI_DIR/$skill.md"

    # ── 6. Gemini CLI loader ──────────────────────────────────────────────────
    write_generic_wrapper "$skill" "$nexskills_dest" "$GEMINI_CLI_DIR/$skill.md"

    success "Installed $skill"
    (( ok++ )) || true
done

update_gitignore true

# ── summary ─────────────────────────────────────────────────────────────────────────

echo ""
info "Done. Installed: $ok  Skipped: $skip  Failed: $fail"

if [[ $fail -gt 0 ]]; then
    warn "Some skills failed to install. Check your network connection."
    exit 1
fi


