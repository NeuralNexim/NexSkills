---
description: Verify this repo's ai-dev-framework install (version, markers, hooks, commit gate, ruleset).
---

Run the framework health check on this repo and report the result:

```
sh ~/.ai-dev-framework/bin/framework-check .
```

If `~/.ai-dev-framework` isn't the framework path on this machine, use the local clone of
`ai-dev-framework`. Summarize: installed vs latest version, any marker/hook/ruleset problems, and
whether an upgrade is available. Do not change anything — this is read-only.
