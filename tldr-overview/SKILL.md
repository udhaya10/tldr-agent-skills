---
name: tldr-overview
description: "[DEPRECATED — replaced by tldr-locate-code, tldr-understand-function, tldr-orient-codebase, tldr-architecture] This skill was retired in the 14-skill intent-aligned restructure. DO NOT activate — see body for migration commands."
allowed-tools: [Bash]
metadata:
  deprecated: "true"
  replaced-by: "tldr-locate-code, tldr-understand-function, tldr-orient-codebase, tldr-architecture"
  deprecation-date: "2026-05-22"
  scheduled-removal: "next minor release"
---

# tldr-overview — DEPRECATED

This skill has been retired in favor of more focused intent-aligned skills. See the [skill architecture decision](https://github.com/udhaya10/tldr-agent-skills/blob/main/research/07_SKILL_ARCHITECTURE_DECISION.md) for the rationale.

## Replacement(s)

- `tldr-locate-code` — find code by intent (when you don't have a name yet)
- `tldr-understand-function` — inspect a known function (definition / explain / extract / context)
- `tldr-orient-codebase` — onboard to a codebase (tree / structure / importers / imports)
- `tldr-architecture` — map structure, layers, coupling

## To migrate

```bash
npx skills remove tldr-overview
npx skills add udhaya10/tldr-agent-skills --all -g
```

After migrating, your existing tldr-* skills will still work — they all wrap the same underlying `tldr-code` CLI commands, just organized by user intent instead of CLI group.

This deprecation stub will be removed entirely in a future release.
