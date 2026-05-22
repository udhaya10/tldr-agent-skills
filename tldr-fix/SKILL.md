---
name: tldr-fix
description: "[DEPRECATED — replaced by tldr-fix-and-detect] This skill was retired in the 14-skill intent-aligned restructure. DO NOT activate — see body for migration commands."
allowed-tools: [Bash]
metadata:
  deprecated: "true"
  replaced-by: "tldr-fix-and-detect"
  deprecation-date: "2026-05-22"
  scheduled-removal: "next minor release"
---

# tldr-fix — DEPRECATED

This skill has been retired in favor of more focused intent-aligned skills. See the [skill architecture decision](https://github.com/udhaya10/tldr-agent-skills/blob/main/research/07_SKILL_ARCHITECTURE_DECISION.md) for the rationale.

## Replacement(s)

- `tldr-fix-and-detect` — bugbot / diagnostics / fix-diagnose / fix-check / fix-apply (same tools, intent-aligned naming with detect vs repair workflows)

## To migrate

```bash
npx skills remove tldr-fix
npx skills add udhaya10/tldr-agent-skills --all -g
```

After migrating, your existing tldr-* skills will still work — they all wrap the same underlying `tldr-code` CLI commands, just organized by user intent instead of CLI group.

This deprecation stub will be removed entirely in a future release.
