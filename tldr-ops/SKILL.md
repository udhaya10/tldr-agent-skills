---
name: tldr-ops
description: "[DEPRECATED — replaced by tldr-runtime, tldr-change-impact, tldr-architecture, tldr-audit-smells, tldr-audit-api] This skill was retired in the 14-skill intent-aligned restructure. DO NOT activate — see body for migration commands."
allowed-tools: [Bash]
metadata:
  deprecated: "true"
  replaced-by: "tldr-runtime, tldr-change-impact, tldr-architecture, tldr-audit-smells, tldr-audit-api"
  deprecation-date: "2026-05-22"
  scheduled-removal: "next minor release"
---

# tldr-ops — DEPRECATED

This skill has been retired in favor of more focused intent-aligned skills. See the [skill architecture decision](https://github.com/udhaya10/tldr-agent-skills/blob/main/research/07_SKILL_ARCHITECTURE_DECISION.md) for the rationale.

## Replacement(s)

- `tldr-runtime` — cache / daemon / warm / stats / doctor (infrastructure)
- `tldr-change-impact` — change-impact / diff (what-changed-and-what-breaks)
- `tldr-architecture` — deps (import-level coupling)
- `tldr-audit-smells` — todo (refactor checklist)
- `tldr-audit-api` — surface (API extraction)

## To migrate

```bash
npx skills remove tldr-ops
npx skills add udhaya10/tldr-agent-skills --all -g
```

After migrating, your existing tldr-* skills will still work — they all wrap the same underlying `tldr-code` CLI commands, just organized by user intent instead of CLI group.

This deprecation stub will be removed entirely in a future release.
