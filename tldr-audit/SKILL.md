---
name: tldr-audit
description: "[DEPRECATED — replaced by tldr-audit-security, tldr-audit-complexity, tldr-audit-smells, tldr-audit-coverage, tldr-audit-api, tldr-architecture] This skill was retired in the 14-skill intent-aligned restructure. DO NOT activate — see body for migration commands."
allowed-tools: [Bash]
metadata:
  deprecated: "true"
  replaced-by: "tldr-audit-security, tldr-audit-complexity, tldr-audit-smells, tldr-audit-coverage, tldr-audit-api, tldr-architecture"
  deprecation-date: "2026-05-22"
  scheduled-removal: "next minor release"
---

# tldr-audit — DEPRECATED

This skill has been retired in favor of more focused intent-aligned skills. See the [skill architecture decision](https://github.com/udhaya10/tldr-agent-skills/blob/main/research/07_SKILL_ARCHITECTURE_DECISION.md) for the rationale.

## Replacement(s)

- `tldr-audit-security` — secure / taint / vuln
- `tldr-audit-complexity` — cognitive / complexity / halstead / loc
- `tldr-audit-smells` — smells / debt / hotspots / churn / health / resources / todo
- `tldr-audit-coverage` — coverage / contracts / invariants / verify / specs
- `tldr-audit-api` — api-check / interface / inheritance / patterns / surface
- `tldr-architecture` — cohesion / coupling / clones (structural-quality concerns)

## To migrate

```bash
npx skills remove tldr-audit
npx skills add udhaya10/tldr-agent-skills --all -g
```

After migrating, your existing tldr-* skills will still work — they all wrap the same underlying `tldr-code` CLI commands, just organized by user intent instead of CLI group.

This deprecation stub will be removed entirely in a future release.
