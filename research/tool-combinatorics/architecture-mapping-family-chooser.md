# Lens: Architecture mapping — family chooser

**The question this lens answers**: "I want to understand the architecture of this codebase — which of `tree`, `structure`, `hubs`, `coupling`, `cohesion`, `clones`, `deps` should I reach for?"

**Toolset** (spans multiple groups): `tldr tree`, `tldr structure` (overview group); `tldr hubs` (trace group); `tldr coupling`, `tldr cohesion`, `tldr clones` (audit group); `tldr deps` (ops group).

**Why a family-chooser lens, why these tools**: "Architecture" is the broadest LLM-vocabulary word in the entire toolkit. Six different sub-questions hide inside it, and each one has a different right tool living in a different CLI group. The biggest trap is conflating the **three different coupling angles**: `audit/coupling` measures function-call coupling between modules (Martin metrics), `ops/deps` measures import-graph coupling (a different graph entirely), `trace/hubs` measures network centrality (which functions are most depended on). LLMs reach for `audit/coupling` to find import cycles and get nothing useful; they reach for `ops/deps` to learn which functions matter and get a file-level import map that says nothing about calls. This family has no single default — only intent-conditional defaults — and forcing one would mislead the LLM.

## Decision tree by sub-question

| The architectural question is... | Granularity | Reach for | Group |
|----------------------------------|-------------|-----------|-------|
| "What FILES exist in this project?" | Filesystem layout, `.gitignore`-clean | `tldr tree` | overview |
| "What's DEFINED in those files — the API roster?" | Functions, classes, imports per file | `tldr structure` | overview |
| "Which functions are MOST-CALLED — the choke points?" | Network centrality (composite of in-degree, PageRank, betweenness) | `tldr hubs` | trace |
| "Which modules are COUPLED via FUNCTION CALLS? Any call-graph cycles?" | Robert Martin Ca/Ce/instability per module | `tldr coupling` (project-wide) | audit |
| "Which modules IMPORT each other? Any IMPORT cycles?" | Module-level import graph | `tldr deps` | ops |
| "Are the methods inside this ONE class actually COHESIVE?" | LCOM4 per class, with split candidates | `tldr cohesion` | audit |
| "What CODE IS DUPLICATED across the project?" | Token-similarity all-vs-all (Type-1/2/3 clones) | `tldr clones` | audit |

## The default (intent-conditional)

No universal default — pick by intent. The four most common:

- **"What IS this codebase?"** → `tldr tree -e <lang>` then `tldr structure <dir>`. Cheap, deterministic, no metrics needed. See `codebase-orientation-canonical.md` for the full flow.
- **"Where are the load-bearing functions?"** → `tldr hubs <dir>`. Composite score + `risk_level` give instant prioritization without needing a function name to start with.
- **"How tangled is this codebase?"** → `tldr coupling <project> --top 20` for call coupling with Martin metrics, AND `tldr deps . --show-cycles` for import cycles. **Run both** — different graphs, different problems.
- **"Is this one class doing too much?"** → `tldr cohesion <file>`. LCOM4 > 1 with `components[]` hands back the method groupings to split into.

## Common mistakes

- **Using `tldr coupling` to find import cycles — the #1 cross-group confusion.** Coupling traces FUNCTION CALLS, not imports. The `--help` itself redirects to `tldr deps` for the import-graph case. Import cycles → `tldr deps . --show-cycles`. Call-graph cycles → `tldr coupling --cycles-only`. They are different graphs and usually surface different problems. An LLM that reaches for `coupling` because the word matches the intent will get function-call coupling and assume "no import problems" when the import graph is on fire.
- **Using `tldr deps` to learn which functions are important.** Deps is FILE-level imports; it has nothing to say about which functions matter. For function-importance, use `tldr hubs` (centrality on the call graph). Same word ("dependencies") points at two different graphs.
- **Using `tldr hubs` and expecting the full call graph.** Hubs returns ranked NODES with centrality scores, not edges. For a visual call graph, use `tldr calls -f dot`. Note: `tldr hubs -f dot` does NOT emit the call graph — it emits hubs as boxes chained by invisible edges.
- **Reaching for `tldr tree` when you actually need definitions** (or `tldr structure` when you only need files). Tree is a pure filesystem walk; structure parses ASTs. Tree to find files, structure to find what's in them.
- **Running `tldr cohesion --lang typescript`.** It is Python-only despite accepting `--lang`; the flag is silently ignored. On non-Python trees it returns empty `classes[]` with no `warnings`.
- **Running `tldr clones` on a full backend.** Detection is O(N²); scope to subdirectories. Medium backends (~50 files) routinely blow the 30s timeout. Also: non-existent paths return exit 0 with a valid empty report — check `files_analyzed > 0`.
- **Parsing `tldr coupling` or `tldr deps --show-cycles` without branching on mode/flag.** Coupling's schema flips on `PATH_B` (pair vs project-wide). `deps --show-cycles` returns a bare array, not the `DepsReport` envelope. Branch before parsing.
- **Trusting `tldr tree` filters on a warm daemon cache.** Cached `FileTree` is returned as-is; `--ext` / `--include-hidden` are NOT re-applied. Stop the daemon or expect the full cached tree.

## What this lens captures

- The seven sub-questions hiding under "architecture" are separable on three axes: **what scope** (filesystem / definitions / functions / modules / class / project), **what graph** (none / call / import / centrality / similarity), **what metric** (none / Martin Ca/Ce/I / LCOM4 / Dice similarity).
- The three-coupling-angles callout. `audit/coupling` (call coupling between modules), `ops/deps` (import coupling between modules), `trace/hubs` (centrality of nodes within the call graph) all sound like "coupling" or "dependencies" to an LLM. Naming the distinction prevents the most common wrong-group failure in this area.
- An intent-conditional default discipline — the family genuinely serves multiple incompatible intents, and forcing one default would lie to the LLM.

## What this lens misses

- **Inheritance hierarchies** (`tldr inheritance`) — covered in the API/design family-chooser.
- **Per-file imports list** (`tldr imports`) and **reverse importers** (`tldr importers`) — finer-grained than `deps`, in the overview group.
- **Architectural WORKFLOW vs PICKING.** This lens is for picking when you know the sub-question. For walking the full orientation workflow, see `codebase-orientation-canonical.md` / `codebase-orientation-rapid.md`.
- **Whether bad architecture is causing real pain.** Structural metrics describe shape, not pain. For pain, cross-reference with `tldr hotspots` (churn × complexity).

## Pair with

- `codebase-orientation-canonical.md` — the textbook orientation workflow on `tree` + `structure` + `extract` + `importers` + `imports`
- `codebase-orientation-rapid.md` — the time-boxed orientation lens on the same toolset
- `audit-structural-quality-family-chooser.md` — within-audit-family chooser for `cohesion` / `coupling` / `clones` (this doc's audit-side discriminator, expanded)
- `trace-relationships-family-chooser.md` — when `tldr hubs` identifies a load-bearing function and the next question is "who depends on it?" (`tldr impact`)

## Sources

- `research/tool-cards/overview/structure.md`
- `research/tool-cards/overview/tree.md`
- `research/tool-cards/trace/hubs.md`
- `research/tool-cards/audit/coupling.md`
- `research/tool-cards/audit/cohesion.md`
- `research/tool-cards/audit/clones.md`
- `research/tool-cards/ops/deps.md`
