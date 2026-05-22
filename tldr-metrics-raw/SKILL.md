---
name: tldr-metrics-raw
description: "[DEPRECATED — replaced by tldr-audit-complexity, tldr-audit-coverage] This skill was retired in the 14-skill intent-aligned restructure. DO NOT activate — see body for migration commands."
allowed-tools: [Bash]
metadata:
  deprecated: "true"
  replaced-by: "tldr-audit-complexity, tldr-audit-coverage"
  deprecation-date: "2026-05-22"
  scheduled-removal: "next minor release"
---

# tldr-metrics-raw — DEPRECATED

This skill has been retired in favor of more focused intent-aligned skills. See the [skill architecture decision](https://github.com/udhaya10/tldr-agent-skills/blob/main/research/07_SKILL_ARCHITECTURE_DECISION.md) for the rationale.

## Replacement(s)

- `tldr-audit-complexity` — loc, halstead (size and complexity metrics)
- `tldr-audit-coverage` — coverage (test coverage metrics)

## To migrate

```bash
npx skills remove tldr-metrics-raw
npx skills add udhaya10/tldr-agent-skills --all -g
```

After migrating, your existing tldr-* skills will still work — they all wrap the same underlying `tldr-code` CLI commands, just organized by user intent instead of CLI group.

This deprecation stub will be removed entirely in a future release.
