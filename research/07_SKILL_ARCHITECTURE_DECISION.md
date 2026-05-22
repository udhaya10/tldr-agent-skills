# Research Journal 07: Skill Architecture Decision

> **The destination, locked in.** Journal 06 defined the cards and combinatorics intermediate layers. This journal commits to the specific shape of the final skill corpus those layers will be rendered into: **14 intent-aligned, self-contained, family-chooser-shaped skills, no router.**

## Why this exists

After completing Phase 1 (64 tool cards) and Phase 2 (19 combinatorics docs), the next move was the actual skill rewrite. Before starting, we re-thought the skill architecture from first principles. The current setup (14 group-aligned skills + 1 router) was inherited from the project's original framing — never validated against the research that came after. With cards and combinatorics in hand, a sharper architecture became visible. This journal locks it in.

> **Rule of thumb:** A skill earns its place by triggering on a *user intent*, not on a *CLI group*. The 14 chosen here all pass this test.

---

## The decision

**14 skills, no router.** Each skill maps to a user intent. Each is self-contained. Cross-skill references happen by sibling name only.

| # | Skill | Intent it triggers on |
|---|-------|----------------------|
| 1 | `tldr-locate-code` | "Find code I don't already have the path/name for" |
| 2 | `tldr-understand-function` | "Tell me about this named function" |
| 3 | `tldr-orient-codebase` | "Help me get oriented in this codebase" |
| 4 | `tldr-trace-relationships` | "Trace call/usage/dependency relationships at function level" |
| 5 | `tldr-trace-data-flow` | "Trace values, definitions, or expressions at variable level" |
| 6 | `tldr-change-impact` | "What will break if I change this?" |
| 7 | `tldr-architecture` | "Map the codebase's structure, layers, and coupling" |
| 8 | `tldr-runtime` | "Manage tldr's daemon, cache, and environment" |
| 9 | `tldr-fix-and-detect` | "Find bugs or apply deterministic fixes" |
| 10 | `tldr-audit-security` | "Audit for vulnerabilities and security issues" |
| 11 | `tldr-audit-complexity` | "Measure code complexity and size" |
| 12 | `tldr-audit-smells` | "Find code smells, debt, and refactor priorities" |
| 13 | `tldr-audit-coverage` | "Assess test coverage and specification quality" |
| 14 | `tldr-audit-api` | "Audit API design, interfaces, and stability" |

---

## Why this shape, not the alternatives

### Why not keep the current 14 group-aligned skills?

Group-aligned skills (e.g., `tldr-audit` wrapping 26 commands) force the LLM to also do the family-chooser job inside the skill. The skill body has to cover 6 sub-families' worth of decisions, the description has to trigger on any audit intent (vague), and every activation loads 26 commands' worth of content even when only 3 are relevant. This is the inverse of progressive disclosure.

### Why not one router + many skills?

A router exists because group skills *overlap*. `tldr-search` and `tldr-overview` both legitimately answer "find this function" depending on what you have. A router disambiguates. But the existence of a router is a symptom that skills were drawn at the wrong granularity. Intent-aligned skills don't overlap — `tldr-locate-code` and `tldr-understand-function` have non-overlapping descriptions ("don't have a name yet" vs "have a name"). They self-route via the description matcher built into the skill loader. No router middleman needed.

### Why not orchestration-workflow skills (e.g., `large-refactor`, `bug-investigation`)?

Workflow-shaped skills activate on a narrow phrase (e.g., "refactor"). They're high-value when they fire but low-ROI because most user turns don't say "refactor" — even when refactoring would benefit from tldr. Intent-aligned skills activate constantly because the intents are broad ("locate code", "understand a function") — they earn their token cost across many turns, not just task-flagged ones. This decision was made explicitly during brainstorming (see `research/agent-skills-authoring/02_KEY_INSIGHTS.md` — the "tool advertisement" framing).

### Why not collapse to 5-7 mega-skills?

Larger skills mean blunter triggers and longer bodies that get loaded on weakly-matching intents. Anthropic's progressive disclosure works best when each skill's body is focused on one job. 14 sharp skills beat 5 sprawling ones on every axis except absolute file count.

---

## What's INSIDE each skill

Every `tldr-*/SKILL.md` follows the same structure:

```markdown
---
name: tldr-<intent>
description: <50-100 word trigger-rich description in third person>
allowed-tools: [Bash]
---

# tldr-<intent>

## When to use
<3-5 sentence intro establishing the intent space and the boundary
with related skills>

## The decision (family-chooser content)
<Decision table or bullets for picking the right tool from this skill's
roster. Sourced from the relevant combinatorics doc.>

## Tool reference
<Inlined card content for EACH command in the skill — typically
3-7 cards × ~200 words each>

## Common mistakes
<Cross-tool footguns from the combinatorics doc>

## See also
<Sibling skill names — by name only, never paths>
```

Target: ~150-250 lines per SKILL.md (well under Anthropic's 500-line ceiling).

> **Rule of thumb:** A skill is correct when (a) its description fires on a clear user-intent phrase, (b) its body answers "which tool, and how do I use it" without requiring any external file load, and (c) it tells the LLM when to leave for a sibling skill.

---

## The self-containment constraint

**Skills MUST be self-contained after install.** When users run `npx skills add udhaya10/tldr-agent-skills`, they get the `tldr-*/` folders but **NOT** the `research/` folder. So:

| Reference type | Allowed in SKILL.md? |
|----------------|---------------------|
| Cross-skill by name (e.g., "see `tldr-understand-function`") | ✅ — sibling skills are co-installed |
| Path into `research/` (e.g., `../research/tool-cards/...`) | ❌ — broken after install |
| External URL to this repo (github.com/...) | ❌ — fragile, may rot |
| Link to a card or dossier file | ❌ — same as above |
| `tldr-code` repo URL (the tool being wrapped) | ✅ — hard runtime dependency anyway |

**Implication:** Every piece of content the skill needs at runtime is **INLINED** into SKILL.md. Cards inlined. Family-chooser decision tables inlined. Common mistakes inlined. The skill is one self-contained file.

Cross-skill references work because sibling skills are present in the install. They're "helpful pointers" — not load-bearing. Each skill works alone if a user installs a subset.

---

## What `research/` becomes after the rewrite

The `research/` folder is **NOT a runtime dependency**. After the rewrite, it serves three purposes:

1. **Regeneration source** — when `tldr-code` ships v0.5 (new commands, behavior changes, bug fixes), re-run probes per Journal 04 → update affected cards per Journal 06 → re-inline updated content into the appropriate SKILL.md files. The skills are *compiled artifacts* from the research; research is the source.
2. **Authoring evidence** — when proposing skill changes (rule changes, new sections, removing claims), the dossier + card + combinatorics chain provides traceable evidence behind every claim. No skill claim is "I said so" — it traces back to probes.
3. **Audit / verification** — any external reviewer can re-run any probe (`bash research/tldr/<group>/<cmd>.probes/probe.sh`) to verify a claim survived a version bump.

Research is not dead weight after the rewrite — it's the maintenance backbone for keeping skills sharp as the underlying tool evolves.

---

## Tool distribution map (locked)

Every active CLI command places into exactly one *primary* skill home. Four commands have legitimate *secondary* homes where their card content is duplicated (4 cards × ~200 words = ~800 words of acceptable redundancy across the corpus).

| Skill | Primary commands | Source combinatorics docs |
|-------|------------------|--------------------------|
| tldr-locate-code | search, semantic, similar, dice, context | `locating-code-family-chooser`, `locator-showdown-family-chooser` |
| tldr-understand-function | definition, explain, extract, (context shared) | `understanding-a-function-family-chooser`, `locator-showdown-family-chooser` |
| tldr-orient-codebase | tree, structure, importers, imports, (extract shared) | `codebase-orientation-canonical`, `codebase-orientation-rapid` |
| tldr-trace-relationships | calls, references, impact, dead | `trace-relationships-family-chooser`, `dead-code-discovery-family-chooser`, `investigation-depth-family-chooser` |
| tldr-trace-data-flow | slice, chop, reaching-defs, available, dead-stores | `deep-data-flow-family-chooser`, `investigation-depth-family-chooser` |
| tldr-change-impact | change-impact, whatbreaks, diff, (impact shared) | `change-impact-family-chooser` |
| tldr-architecture | hubs, coupling, cohesion, clones, deps, temporal, (structure shared) | `architecture-mapping-family-chooser`, `audit-structural-quality-family-chooser` |
| tldr-runtime | cache, daemon, warm, stats, doctor | `ops-daemon-lifecycle-family-chooser` |
| tldr-fix-and-detect | bugbot, diagnostics, fix-diagnose, fix-check, fix-apply | `fix-detect-vs-repair-family-chooser` |
| tldr-audit-security | secure, taint, vuln | `audit-security-family-chooser` |
| tldr-audit-complexity | cognitive, complexity, halstead, loc | `audit-complexity-metrics-family-chooser` |
| tldr-audit-smells | smells, debt, hotspots, churn, todo, resources, health | `audit-smells-debt-family-chooser` |
| tldr-audit-coverage | coverage, contracts, invariants, verify, specs | `audit-coverage-testing-family-chooser` |
| tldr-audit-api | api-check, interface, inheritance, patterns, surface | `audit-api-design-family-chooser` |

Total: **64 unique commands** distributed across 14 skills + 4 secondary placements (context, extract, impact, structure).

---

## What changes vs the current state

| | Today (pre-rewrite) | After rewrite |
|---|--------------------|----------------|
| Skill count | 14 group-aligned + 1 router = **15** | 14 intent-aligned, no router |
| Skill granularity | CLI-group-shaped | Intent-shaped (sometimes spans groups) |
| Skill body | ~40-line stub listing commands | ~200-line self-contained playbook |
| Description trigger words | Broad-and-vague (must cover whole group) | Sharp-and-specific (must cover one intent) |
| Cards | Live in `research/tool-cards/` | Inlined into SKILL.md bodies |
| Combinatorics | Live in `research/tool-combinatorics/` | Distributed into SKILL.md bodies |
| Router | Active disambiguator | Retired — sharp descriptions self-route |
| External refs in skills | (mostly) none | None (enforced as a hard constraint) |
| Overlap between skills | Real (search vs overview both "find functions") | Disambiguated by description (don't have name vs have name) |

Skill folder additions/renames/retirements:

- **Retire entirely**: tldr-router, tldr-search, tldr-overview, tldr-trace, tldr-deep, tldr-audit, tldr-fix, tldr-ops, tldr-refactor-history, tldr-refactor-oo, tldr-formal-methods, tldr-api-stability, tldr-metrics-raw, tldr-security-taint — all 15 current skills retired
- **Create**: 14 new skill folders as listed above

The retirement is wholesale because the new skills don't 1:1-map to old ones (most splits and recombines crossings).

---

## Open questions deferred to execution

1. **Inlined-card voice**: when inlining a card from `research/tool-cards/`, do we keep the card's exact structure (Pitch → Why → When → When NOT → Output → Killer detail → Other footguns) or compress further? Probably preserve structure for consistency; defer compression to per-skill judgment if a card feels disproportionate.
2. **Cross-skill pointer phrasing**: "for X, see `tldr-Y`" is the default phrasing. Should we always end skills with a "## See also" section listing related siblings, or only when there's a specific tradeoff to flag?
3. **Description length budget**: Anthropic caps at 1024 chars. Our descriptions will probably run 200–500 chars. Worth tracking actual sizes across the 14 to see if any need trimming.
4. **`allowed-tools` field**: currently most skills have `[Bash]`. Some may need `[Bash, Read]` (e.g., skills that suggest reading a file in their playbook). Decide per skill at write time.

---

## Cross-references

- **Journal 04** — operational protocol for the dossier evidence layer (the foundation)
- **Journal 06** — cards and combinatorics protocol (the bridge from dossiers to skills)
- **`agent-skills-authoring/02_KEY_INSIGHTS.md`** — Anthropic's skill-authoring guidance that motivated the self-containment and intent-alignment constraints
- **`tool-combinatorics/<topic>-family-chooser.md`** — the 19 combinatorics docs that get distributed into the 14 skill bodies
- **`tool-cards/<group>/<cmd>.md`** — the 64 cards that get inlined into the 14 skill bodies
