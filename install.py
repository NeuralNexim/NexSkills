# Install NexSkills from the command line
# Usage: python install.py [options]
# Options:
#   --skills NAMES    Comma-separated list of skills (default: all)
#   --list            List available skills and exit
#   --uninstall       Remove previously installed skill files
#   --force           Overwrite existing skill files
import argparse
import os
import sys
import textwrap
import urllib.error
import urllib.request

REPO_RAW = "https://raw.githubusercontent.com/NeuralNexim/NexSkills/main"

ALL_SKILLS = [
    "implement-next",
    "peer-review",
    "implement-review",
    "plan-milestone",
    "show-changes",
]

SKILL_DESCRIPTIONS = {
    "implement-next":   "Implement the next milestone task from the project plan. WHEN: implement next, start next task, /implement-next, begin implementation, next feature, continue development.",
    "peer-review":      "Run structured code review against the current branch diff. WHEN: peer review, code review, review changes, /peer-review, review my code, review diff.",
    "implement-review": "Fix BLOCKING issues from a peer-review. WHEN: implement review, fix review comments, address blocking issues, /implement-review, resolve review.",
    "plan-milestone":   "Analyse roadmap and generate structured implementation plan files for the next milestone. WHEN: plan milestone, generate plan, /plan-milestone, create plan.",
    "show-changes":     "Scan the current branch diff for new and updated public-facing symbols. WHEN: show changes, what changed, list changes, /show-changes, display changes.",
}

SKILL_HINTS = {
    "implement-next":   "Optional: milestone ID or leave blank to pick from plan/status.md",
    "peer-review":      "Optional: branch name or leave blank to review current branch",
    "implement-review": "Optional: path to review file, or leave blank to auto-detect",
    "plan-milestone":   "Optional: milestone ID or description to plan",
    "show-changes":     "Optional: branch name or leave blank to use current branch",
}

# Directories written by the installer
NEXSKILLS_DIR   = ".nexskills"
CLAUDE_DIR      = ".claude/commands"
CLAUDE_PROMPTS  = ".claude/prompts"
COPILOT_DIR     = ".github/copilot-instructions"
COPILOT_CLI_DIR = ".copilot/skills"
GEMINI_DIR      = ".gemini/skills"
GEMINI_CLI_DIR  = ".gemini/commands"


def _makedirs(*dirs):
    for d in dirs:
        os.makedirs(d, exist_ok=True)


def _remove_if_exists(path):
    if os.path.isfile(path) or os.path.islink(path):
        os.remove(path)
        return True
    if os.path.isdir(path):
        import shutil
        shutil.rmtree(path)
        return True
    return False


def _fetch(url, dest):
    urllib.request.urlretrieve(url, dest)


def _write_copilot_wrapper(skill, procedure_path, skill_dir):
    """Write a VS Code Copilot SKILL.md wrapper that delegates to the procedure file."""
    os.makedirs(skill_dir, exist_ok=True)
    title = skill.replace("-", " ").capitalize()
    description = SKILL_DESCRIPTIONS.get(skill, f"{title} skill workflow.")
    hint = SKILL_HINTS.get(skill, "")
    content = textwrap.dedent(f"""\
        ---
        name: {skill}
        description: "{description}"
        argument-hint: "{hint}"
        ---

        # {title}

        Read the complete procedure from `{procedure_path}` using the `read_file` tool,
        then follow every step in that file precisely and in order.

        **Do not paraphrase, skip, or reorder any steps.**
    """)
    with open(os.path.join(skill_dir, "SKILL.md"), "w", encoding="utf-8") as fh:
        fh.write(content)


def _write_generic_wrapper(skill, nexskills_path, dest):
    """Write a thin loader file that instructs the tool to load the NexSkills procedure."""
    title = skill.replace("-", " ").capitalize()
    content = textwrap.dedent(f"""\
        # {title}

        Load and follow the complete procedure from `{nexskills_path}`.
        Read that file with your file-reading tool and execute every step
        precisely and in order. Do not paraphrase, skip, or reorder any steps.
    """)
    with open(dest, "w", encoding="utf-8") as fh:
        fh.write(content)


def list_skills():
    print("Available NexSkills:")
    for skill in ALL_SKILLS:
        print(f"  {skill:<20}  skills/{skill}.md")


def install(selected, force):
    _makedirs(
        NEXSKILLS_DIR,
        CLAUDE_DIR, CLAUDE_PROMPTS,
        COPILOT_DIR,
        COPILOT_CLI_DIR,
        GEMINI_DIR, GEMINI_CLI_DIR,
    )
    ok = skip = fail = 0
    for skill in selected:
        nexskills_dest = os.path.join(NEXSKILLS_DIR, f"{skill}.md")
        skill_url      = f"{REPO_RAW}/skills/{skill}.md"

        # ── 1. Download canonical copy into .nexskills/ ────────────────────────
        if os.path.exists(nexskills_dest) and not force:
            print(f"Skipping {skill} (already installed — use --force to overwrite)")
            skip += 1
            continue

        try:
            _fetch(skill_url, nexskills_dest)
        except (urllib.error.URLError, OSError) as e:
            print(f"Error downloading {skill}: {e}")
            fail += 1
            continue

        # ── 2. Claude CLI: hard copy in .claude/commands/ ─────────────────────
        claude_dest = os.path.join(CLAUDE_DIR, f"{skill}.md")
        try:
            import shutil
            shutil.copy2(nexskills_dest, claude_dest)
            # Attempt symlink in .claude/prompts/
            prompt_link = os.path.join(CLAUDE_PROMPTS, f"{skill}.lnk")
            if os.path.lexists(prompt_link):
                os.remove(prompt_link)
            rel = os.path.relpath(claude_dest, CLAUDE_PROMPTS)
            os.symlink(rel, prompt_link)
        except OSError:
            pass  # symlinks optional on Windows

        # ── 3. VS Code Copilot: SKILL.md wrapper ──────────────────────────────
        _write_copilot_wrapper(skill, nexskills_dest, os.path.join(COPILOT_DIR, skill))

        # ── 4. Copilot CLI loader ──────────────────────────────────────────────
        _write_generic_wrapper(skill, nexskills_dest, os.path.join(COPILOT_CLI_DIR, f"{skill}.md"))

        # ── 5. Gemini (VS Code extension) loader ──────────────────────────────
        _write_generic_wrapper(skill, nexskills_dest, os.path.join(GEMINI_DIR, f"{skill}.md"))

        # ── 6. Gemini CLI loader ───────────────────────────────────────────────
        _write_generic_wrapper(skill, nexskills_dest, os.path.join(GEMINI_CLI_DIR, f"{skill}.md"))

        print(f"Installed {skill}")
        ok += 1

    print(f"\nDone: {ok} installed, {skip} skipped, {fail} failed.")


def uninstall(selected):
    removed_count = 0
    for skill in selected:
        removed = False
        paths = [
            os.path.join(NEXSKILLS_DIR,   f"{skill}.md"),
            os.path.join(CLAUDE_DIR,      f"{skill}.md"),
            os.path.join(CLAUDE_PROMPTS,  f"{skill}.lnk"),
            os.path.join(COPILOT_DIR,     skill),          # directory
            os.path.join(COPILOT_CLI_DIR, f"{skill}.md"),
            os.path.join(GEMINI_DIR,      f"{skill}.md"),
            os.path.join(GEMINI_CLI_DIR,  f"{skill}.md"),
        ]
        for p in paths:
            if _remove_if_exists(p):
                removed = True
        if removed:
            print(f"Removed {skill}")
            removed_count += 1
        else:
            print(f"Nothing to remove for {skill} (not installed)")
    print(f"\nDone. Removed: {removed_count} skill(s).")


def main():
    parser = argparse.ArgumentParser(description="Install NexSkills")
    parser.add_argument("--skills",     help="Comma-separated list of skills to install (default: all)")
    parser.add_argument("--list",       action="store_true", help="List available skills and exit")
    parser.add_argument("--uninstall",  action="store_true", help="Remove previously installed skill files")
    parser.add_argument("--force",      action="store_true", help="Overwrite existing skill files")
    args = parser.parse_args()

    if args.list:
        list_skills()
        sys.exit(0)

    if args.skills:
        selected = [s.strip() for s in args.skills.split(",") if s.strip()]
        unknown  = [s for s in selected if s not in ALL_SKILLS]
        if unknown:
            print(f"Unknown skill(s): {', '.join(unknown)}. Use --list to see available skills.")
            sys.exit(1)
    else:
        selected = list(ALL_SKILLS)

    if args.uninstall:
        uninstall(selected)
    else:
        install(selected, args.force)


if __name__ == "__main__":
    main()



