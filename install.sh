#!/usr/bin/env bash
# install.sh — NexSkills installer
# Usage: curl -fsSL https://raw.githubusercontent.com/NeuralNexim/NexSkills/main/install.sh | bash
# Or:    bash install.sh [--target DIR] [--skills NAMES] [--list] [--force]
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/NeuralNexim/NexSkills/main"
DEFAULT_TARGET=".claude/commands"

ALL_SKILLS=(
    "implement-next"
    "peer-review"
    "implement-review"
    "plan-milestone"
    "show-changes"
)

TARGET=""
SELECTED_SKILLS=()
LIST_ONLY=false
FORCE=false

# ── helpers ────────────────────────────────────────────────────────────────────

info()    { printf '\033[1;34m[NexSkills]\033[0m %s\n' "$*"; }
success() { printf '\033[1;32m[NexSkills]\033[0m %s\n' "$*"; }
warn()    { printf '\033[1;33m[NexSkills]\033[0m %s\n' "$*" >&2; }
error()   { printf '\033[1;31m[NexSkills]\033[0m ERROR: %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<EOF
Usage: install.sh [OPTIONS]

Install NexSkills Copilot CLI skill files into a project.

Options:
  --target DIR          Install directory (default: .claude/commands)
  --skills NAMES        Comma-separated list of skills to install (default: all)
  --list                List available skills and exit
  --force               Overwrite existing skill files
  -h, --help            Show this message

Available skills: ${ALL_SKILLS[*]}

Example:
  bash install.sh --skills peer-review,implement-review --target .claude/commands
EOF
}

skill_exists_in_list() {
    local name="$1"
    local skill
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

# ── argument parsing ────────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            [[ -n "${2-}" ]] || error "--target requires a directory argument"
            TARGET="$2"; shift 2 ;;
        --skills)
            [[ -n "${2-}" ]] || error "--skills requires a comma-separated list"
            IFS=',' read -ra SELECTED_SKILLS <<< "$2"; shift 2 ;;
        --list)
            LIST_ONLY=true; shift ;;
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

# ── defaults ────────────────────────────────────────────────────────────────────

[[ -z "$TARGET" ]] && TARGET="$DEFAULT_TARGET"

if [[ ${#SELECTED_SKILLS[@]} -eq 0 ]]; then
    SELECTED_SKILLS=("${ALL_SKILLS[@]}")
fi

# ── validate skill names ────────────────────────────────────────────────────────

for skill in "${SELECTED_SKILLS[@]}"; do
    skill_exists_in_list "$skill" || error "Unknown skill: '$skill'. Use --list to see available skills."
done

# ── install ─────────────────────────────────────────────────────────────────────

info "Installing ${#SELECTED_SKILLS[@]} skill(s) → $TARGET"

mkdir -p "$TARGET"

ok=0
skip=0
fail=0

for skill in "${SELECTED_SKILLS[@]}"; do
    dest="$TARGET/$skill.md"
    url="$REPO_RAW/skills/$skill.md"

    if [[ -f "$dest" ]] && ! $FORCE; then
        warn "Skipping $skill.md (already exists — use --force to overwrite)"
        (( skip++ )) || true
        continue
    fi

    if command -v curl &>/dev/null; then
        if curl -fsSL "$url" -o "$dest"; then
            success "Installed $skill.md"
            (( ok++ )) || true
        else
            warn "Failed to download $skill.md from $url"
            (( fail++ )) || true
        fi
    elif command -v wget &>/dev/null; then
        if wget -qO "$dest" "$url"; then
            success "Installed $skill.md"
            (( ok++ )) || true
        else
            warn "Failed to download $skill.md from $url"
            (( fail++ )) || true
        fi
    else
        error "Neither curl nor wget is available. Cannot download skills."
    fi
done

# ── summary ─────────────────────────────────────────────────────────────────────

echo ""
info "Done. Installed: $ok  Skipped: $skip  Failed: $fail"

if [[ $fail -gt 0 ]]; then
    warn "Some skills failed to install. Check your network connection."
    exit 1
fi

if [[ $ok -gt 0 ]]; then
    echo ""
    info "Invoke installed skills in Copilot CLI with:"
    for skill in "${SELECTED_SKILLS[@]}"; do
        [[ -f "$TARGET/$skill.md" ]] && printf "  /%-20s\n" "$skill"
    done
fi
