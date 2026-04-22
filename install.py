# Install NexSkills from the command line
# Usage: python install.py [options]
# Options:
#   --target <dir>    Directory to install skills (default: .claude/commands)
#   --force           Overwrite existing skill files
import argparse
import os
import sys
import urllib.error
import urllib.request

ALL_SKILLS = [
    "implement-next",
    "peer-review",
    "implement-review",
    "plan-milestone",
    "show-changes",
]

def init(target_dir, prompts_dir):
    try:
        os.makedirs(target_dir, exist_ok=True)
        os.makedirs(prompts_dir, exist_ok=True)
    except OSError as e:
        print(f"Error initializing directories: {e}")
        return False
    return True

def list_skills():
    print("Available NexSkills:")
    for skill in ALL_SKILLS:
        print(f"  {skill:<20}  skills/{skill}.md")


def main():
    parser = argparse.ArgumentParser(description='Install NexSkills')
    parser.add_argument('--target', default='.claude/commands', help='Directory to install skills (default: .claude/commands)')
    parser.add_argument('--skills', help='Comma-separated list of skills to install (default: all)')
    parser.add_argument('--list', action='store_true', help='List available skills and exit')
    parser.add_argument('--force', action='store_true', help='Overwrite existing skill files')
    args = parser.parse_args()

    if args.list:
        list_skills()
        sys.exit(0)

    REPO_RAW = "https://raw.githubusercontent.com/NeuralNexim/NexSkills/main"
    PROMPTS_DIR = ".claude/prompts"

    if args.skills:
        selected = [s.strip() for s in args.skills.split(',')]
        unknown = [s for s in selected if s not in ALL_SKILLS]
        if unknown:
            print(f"Unknown skill(s): {', '.join(unknown)}. Use --list to see available skills.")
            sys.exit(1)
    else:
        selected = list(ALL_SKILLS)

    print(f"Installing {len(selected)} skill(s) → {args.target}")
    if not init(args.target, PROMPTS_DIR):
        print("Initialization failed. Exiting.")
        sys.exit(1)

    ok = skip = fail = 0
    for skill in selected:
        dest = os.path.join(args.target, f"{skill}.md")
        skill_url = f"{REPO_RAW}/skills/{skill}.md"
        prompt_link = os.path.join(PROMPTS_DIR, f"{skill}.lnk")

        if os.path.exists(dest):
            if args.force:
                os.remove(dest)
            else:
                print(f"Skipping {skill}.md (already exists — use --force to overwrite)")
                skip += 1
                continue

        try:
            urllib.request.urlretrieve(skill_url, dest)
            print(f"Installed {skill}.md")
            ok += 1
        except (urllib.error.URLError, OSError) as e:
            print(f"Error installing {skill}: {e}")
            fail += 1
            continue

        try:
            rel = os.path.relpath(dest, PROMPTS_DIR)
            if os.path.lexists(prompt_link):
                os.remove(prompt_link)
            os.symlink(rel, prompt_link)
        except OSError as e:
            print(f"Warning: could not create symlink for {skill} (on Windows, enable Developer Mode or run as admin): {e}")

    print(f"Done: {ok} installed, {skip} skipped, {fail} failed.")

if __name__ == "__main__":
    main()


