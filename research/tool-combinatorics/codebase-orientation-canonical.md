# Lens: Codebase orientation — canonical (textbook) flow

**The question this lens answers**: "I'm new to this codebase and have the time to do this properly. What's the textbook sequence to orient myself?"

**Toolset**: `tldr tree`, `tldr structure`, `tldr extract`, `tldr importers`, `tldr imports`

**Why this lens, why these tools**: The canonical orientation flow is progressive zoom — forest → tree → branch → leaf. Each step's output feeds the next: tree picks files for structure, structure picks files for extract, extract reveals modules to feed into importers/imports. The discipline is "broad-to-narrow with no skipping," and that's exactly when the canonical lens is right.

## Moves

The order matters here — each step's output narrows the next step's input. Unlike the rapid lens, *don't skip steps*.

1. **`tldr tree -e <lang>`** — get the file inventory, scoped to one language. Reveals directory layout, .gitignore-clean. Confirms what kind of project this is (monorepo? single service? library?).
2. **`tldr structure <dir>`** — get the function/class roster across the files identified in step 1. Per-file definition lists with line numbers. This is where the project's API surface becomes visible.
3. **`tldr extract <file>`** — for the 3–5 files that look most important from structure (high definition density, or in `core/`, `lib/`, `services/` paths), get the full intra-file picture including local call graph.
4. **`tldr importers <module>` and `tldr imports <file>`** — for the modules that look load-bearing, see the dependency direction. `importers` reveals who depends on this (blast radius if changed); `imports` reveals what it depends on (its own surface area).

## What this lens captures

- **Progressive zoom**: forest → tree → branch → leaf, in that order. No premature deep-dives.
- **Complete coverage of the important parts**: every file that *should* be looked at gets looked at, because the funnel is wide at the top.
- **A hierarchy in your head that mirrors the codebase's actual structure** — useful for navigation later.
- **Cheap at the front, expensive only where it matters**: tree and structure are cheap; extract and importers are only run on selected targets.

## What this lens misses

- **Time-boxed efficiency.** Canonical assumes you have hours. For 1-hour orientation, see `codebase-orientation-rapid.md` — same tools, different discipline.
- **Hot-spot prioritization.** Canonical doesn't tell you which files are CHANGE-prone or BUG-prone. Add `tldr hotspots` (churn × complexity) when you're orienting to fix something specific.
- **Architectural lens.** "Where are the layers? What's the bounded context?" isn't this lens. Use `tldr hubs` (network centrality) + `tldr api-stability` after orientation if you need the architectural cut.
- **Design archaeology.** "Why was it built this way?" needs git history + `tldr churn`, not these tools.

## Pair with

- `codebase-orientation-rapid.md` — same toolset, time-boxed lens
- *(future)* `codebase-orientation-archaeology.md` — same toolset, "why was it built this way" lens
- *(future)* `codebase-orientation-pre-change.md` — same toolset, "what's safe to touch" lens

## Sources

- `research/tool-cards/overview/tree.md`
- `research/tool-cards/overview/structure.md`
- `research/tool-cards/overview/extract.md`
- `research/tool-cards/overview/importers.md`
- `research/tool-cards/overview/imports.md`
