# Research Methodology — Agent Skills Authoring

## Purpose

Capture Anthropic's official guidance on how to author Claude Code Agent Skills, so we can update our 14 `tldr-*` skill files (currently ~20–67 lines each, total ~570 lines) using authoritative source material rather than guesswork.

## Sources scraped (2026-05-22)

Five official Anthropic documentation pages, scraped via `firecrawl scrape --only-main-content` and saved as markdown in `references/`:

| File | Source URL | Why we picked it |
|------|-----------|------------------|
| `overview.md` | `platform.claude.com/docs/.../agent-skills/overview` | Foundational concepts: architecture, progressive disclosure, structure rules |
| `quickstart.md` | `.../agent-skills/quickstart` | API-level invocation tutorial (less relevant — we use Claude Code filesystem skills, not API) |
| `best-practices.md` | `.../agent-skills/best-practices` | The authoring bible — naming, descriptions, workflows, anti-patterns, checklist |
| `enterprise.md` | `.../agent-skills/enterprise` | Org-scale practices: review checklists, naming/cataloging, role-based bundles |
| `skills-guide.md` | `.../build-with-claude/skills-guide` | API mechanics (upload, version, multi-turn) — mostly N/A for our case |

## How we fetched them

```bash
# All 5 in parallel via firecrawl skill (background commands)
firecrawl scrape "<url>" --only-main-content -o references/<name>.md
```

Total: 5 concurrent scrapes, ~30 seconds wall-clock, ~101 KB / 2,655 lines of markdown.

`--only-main-content` strips nav/footer/sidebars to keep just the doc body — important because the raw pages include marketing chrome that adds noise without signal.

## How we will use them

The `references/` folder is the **frozen source of truth** for this research cycle. If a doc page changes upstream, we re-scrape into a new dated folder rather than overwriting — same pattern as our Journal 04 environment-pin discipline for the tldr probes.

The synthesis (what we learned + value assessment + gap analysis) lives in `02_KEY_INSIGHTS.md`.

## Re-running this research

To refresh the references:

```bash
cd /Users/udhayakumar/Workspace/03-Parcadei-Ecosystem/AIHarnessUtilities/tldr-agent-skills
for url_pair in \
    "https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview:overview" \
    "https://platform.claude.com/docs/en/agents-and-tools/agent-skills/quickstart:quickstart" \
    "https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices:best-practices" \
    "https://platform.claude.com/docs/en/agents-and-tools/agent-skills/enterprise:enterprise" \
    "https://platform.claude.com/docs/en/build-with-claude/skills-guide:skills-guide" ; do
    url="${url_pair%:*}"
    name="${url_pair#*:}"
    firecrawl scrape "$url" --only-main-content -o research/agent-skills-authoring/references/${name}.md
done
```
