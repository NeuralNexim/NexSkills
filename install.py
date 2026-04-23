# Install NexSkills from the command line
# Usage: python install.py [options]
# Options:
#   --skills NAMES    Comma-separated list of skills (default: all)
#   --list            List available skills and exit
#   --uninstall       Remove previously installed skill files
#   --force           Overwrite existing skill files
import argparse
import os
import re
import sys
import textwrap
import urllib.error
import urllib.request

REPO_RAW = "https://raw.githubusercontent.com/NeuralNexim/NexSkills/main"

# Marker written into every generated file so conflicts can be detected
NEXSKILLS_MARKER = "<!-- nexskills:managed -->"

# .gitignore section delimiters
_GI_START = "# >>> NexSkills managed — do not edit between these markers"
_GI_END   = "# <<< NexSkills"
_GI_PATHS = [
    ".nexskills/",
    ".claude/commands/",
    ".claude/prompts/",
    ".github/copilot-instructions/",
    ".copilot/",
    ".gemini/",
]

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


def _is_nexskills_file(path):
    """Return True if path exists and was written by NexSkills."""
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as fh:
            return NEXSKILLS_MARKER in fh.read(1024)
    except OSError:
        return False


def _conflict_paths(skill):
    """Return all file paths the installer would write for this skill.
    All use the nexskills- prefix so they never conflict with user files."""
    return [
        os.path.join(NEXSKILLS_DIR,   f"{skill}.md"),
        os.path.join(CLAUDE_DIR,      f"nexskills-{skill}.md"),
        os.path.join(COPILOT_CLI_DIR, f"nexskills-{skill}.md"),
        os.path.join(GEMINI_DIR,      f"nexskills-{skill}.md"),
        os.path.join(GEMINI_CLI_DIR,  f"nexskills-{skill}.md"),
        os.path.join(COPILOT_DIR,     f"nexskills-{skill}", "SKILL.md"),
    ]


def _update_gitignore(add):
    """Add or remove the NexSkills block in .gitignore."""
    gitignore = ".gitignore"
    existing = ""
    if os.path.exists(gitignore):
        with open(gitignore, "r", encoding="utf-8") as fh:
            existing = fh.read()
    cleaned = re.sub(
        r"\n?# >>> NexSkills managed.*?# <<< NexSkills\n?",
        "",
        existing,
        flags=re.DOTALL,
    ).rstrip("\n")
    if add:
        section = "\n\n" + _GI_START + "\n" + "\n".join(_GI_PATHS) + "\n" + _GI_END
        new_content = cleaned + section + "\n"
    else:
        new_content = cleaned + "\n" if cleaned else ""
    with open(gitignore, "w", encoding="utf-8") as fh:
        fh.write(new_content)


def _any_nexskills_installed():
    """Return True if at least one skill remains installed in .nexskills/."""
    return any(
        os.path.isfile(os.path.join(NEXSKILLS_DIR, f"{s}.md"))
        for s in ALL_SKILLS
    )


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

        {NEXSKILLS_MARKER}

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
        {NEXSKILLS_MARKER}

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

        # ── Conflict check: only .nexskills/ download can conflict (prefixed
        # loader files use nexskills- prefix so they won't clash with user files)
        if os.path.isfile(nexskills_dest) and not _is_nexskills_file(nexskills_dest) and not force:
            print(f"Conflict: {nexskills_dest} exists and is not a NexSkills file.")
            print(f"  Move or remove it, or use --force to overwrite.")
            skip += 1
            continue

        # ── 1. Download canonical copy into .nexskills/ ────────────────────────
        if os.path.isfile(nexskills_dest) and _is_nexskills_file(nexskills_dest) and not force:
            print(f"Skipping {skill} (already installed — use --force to overwrite)")
            skip += 1
            continue

        try:
            _fetch(skill_url, nexskills_dest)
        except (urllib.error.URLError, OSError) as e:
            print(f"Error downloading {skill}: {e}")
            fail += 1
            continue

        # ── 2. Claude CLI loader (nexskills-<skill>.md) ───────────────────────
        import shutil
        claude_dest = os.path.join(CLAUDE_DIR, f"nexskills-{skill}.md")
        _write_generic_wrapper(skill, nexskills_dest, claude_dest)
        try:
            prompt_link = os.path.join(CLAUDE_PROMPTS, f"nexskills-{skill}.lnk")
            if os.path.lexists(prompt_link):
                os.remove(prompt_link)
            rel = os.path.relpath(claude_dest, CLAUDE_PROMPTS)
            os.symlink(rel, prompt_link)
        except OSError:
            pass  # symlinks optional on Windows

        # ── 3. VS Code Copilot: SKILL.md wrapper ──────────────────────────────
        _write_copilot_wrapper(skill, nexskills_dest, os.path.join(COPILOT_DIR, f"nexskills-{skill}"))

        # ── 4. Copilot CLI loader ──────────────────────────────────────────────
        _write_generic_wrapper(skill, nexskills_dest, os.path.join(COPILOT_CLI_DIR, f"nexskills-{skill}.md"))

        # ── 5. Gemini (VS Code extension) loader ──────────────────────────────
        _write_generic_wrapper(skill, nexskills_dest, os.path.join(GEMINI_DIR, f"nexskills-{skill}.md"))

        # ── 6. Gemini CLI loader ───────────────────────────────────────────────
        _write_generic_wrapper(skill, nexskills_dest, os.path.join(GEMINI_CLI_DIR, f"nexskills-{skill}.md"))

        print(f"Installed {skill}")
        ok += 1

    _update_gitignore(add=True)
    print(f"\nDone: {ok} installed, {skip} skipped, {fail} failed.")
    if ok > 0:
        print("\nInstalled skills can be invoked in your AI tool:")
        print("  CLI:  Type /implement-next, /peer-review, /show-changes, etc.")
        print("  Code: Type the skill name or /skill-name in the Copilot chat panel.")
        print("\n[NexSkills] VS Code users: reload the window to activate new skills.")
        print('             Ctrl+Shift+P \u2192 \"Developer: Reload Window\" \u2192 Enter')


def uninstall(selected):
    removed_count = 0
    for skill in selected:
        removed = False
        paths = [
            os.path.join(NEXSKILLS_DIR,   f"{skill}.md"),
            os.path.join(CLAUDE_DIR,      f"nexskills-{skill}.md"),
            os.path.join(CLAUDE_PROMPTS,  f"nexskills-{skill}.lnk"),
            os.path.join(COPILOT_DIR,     f"nexskills-{skill}"),   # directory
            os.path.join(COPILOT_CLI_DIR, f"nexskills-{skill}.md"),
            os.path.join(GEMINI_DIR,      f"nexskills-{skill}.md"),
            os.path.join(GEMINI_CLI_DIR,  f"nexskills-{skill}.md"),
        ]
        for p in paths:
            if _remove_if_exists(p):
                removed = True
        if removed:
            print(f"Removed {skill}")
            removed_count += 1
        else:
            print(f"Nothing to remove for {skill} (not installed)")
    if not _any_nexskills_installed():
        _update_gitignore(add=False)
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



