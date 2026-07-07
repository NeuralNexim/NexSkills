---
description: Upgrade this repo to the latest ai-dev-framework version (branch → PR, never merges).
---

Upgrade this repo's ai-dev-framework install to the latest version:

1. Read `~/.ai-dev-framework/setup/SETUP_PROMPT.md` and follow it as an **upgrade** (it detects the
   upgrade from this repo's `.framework-version`).
2. Honor its Phase 3.5 (validate resolved config) and Phase 3a (branch/worktree/PR discipline) —
   install on a new branch cut from this repo's recorded `DEFAULT_BRANCH` (worktree if the tree is
   dirty), never on the current branch, never committing to a protected branch.
3. Open a PR with the standardized change report in the description. **Do not merge** — leave that
   to the operator.

First, show me the version delta and the plan; get my OK before writing anything.
