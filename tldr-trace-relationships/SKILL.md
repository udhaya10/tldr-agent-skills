---
name: tldr-trace-relationships
description: Trace call, usage, and dependency relationships at function level — answer "who calls X", "find all usages of", "trace what depends on", "blast radius", "what is unreachable", "dead code", "find references", "who uses this". Reach for this whenever you have a SYMBOL or FUNCTION NAME in hand and need to know what touches it, who calls it, or whether it's safe to delete. Replaces grep-then-read loops with AST-verified, scope-aware relationship queries. Includes the dead-code discovery workflow (discover candidates with `dead`, then ALWAYS verify each with `references` before deletion).
allowed-tools: [Bash]
---

# tldr-trace-relationships

## When to use

Use this skill when you ALREADY have a function name, symbol name, or the whole project in hand and need to ask a **relationship question**: who calls this, where is this referenced, what is the recursive blast radius if I change it, what is unreachable. The question is about *call edges and use sites between functions*, not about values inside a function.

The discriminator vs sibling skills:

- For questions about VALUES, variables, or which lines mathematically influence another line → see `tldr-trace-data-flow` (slice, chop, reaching-defs, dead-stores). The boundary is **call paths vs values**. If you've spent five `impact` calls chasing callers and the bug is actually an assignment inside one function that clobbers a value, you crossed the boundary too late.
- For impact analysis that starts from a GIT DIFF rather than a function name → see `tldr-change-impact` (change-impact, whatbreaks). `impact` here takes a function; `whatbreaks` takes a diff.
- For finding code when you DON'T yet have a name to feed these tools → see `tldr-locate-code` first.
- For inspecting what a function DOES (signature, complexity, body) rather than its relationships → see `tldr-understand-function`.

If you can't say "I want callers" or "I want use sites" or "I want the project graph," you probably want `tldr references` — it's the broadest entry point and the only one that surfaces non-call use sites (reads, writes, imports, type references).

## The decision — which tool to use

The discriminator is the **cardinality axis**: how many inputs go in, what shape comes out, whether the walk is recursive.

| You have... | You want... | Walk shape | Reach for |
|-------------|-------------|------------|-----------|
| Nothing — the whole project | Every caller→callee edge in one graph | Many-edges, forward, flat | `tldr calls` |
| One symbol name (any kind) | Every use site classified as call / read / write / import / type | One-symbol, flat list, all-kinds | `tldr references` |
| One function name | The recursive caller tree — callers, callers-of-callers, blast radius | One-function, reverse, recursive | `tldr impact` |
| Nothing — the whole project | List of functions that look unreachable (deletion candidates) | Project-wide, function-level | `tldr dead` (then verify each with `references`) |

**No universal default.** This family has no single first move because each tool takes a different input shape. Pick by what's in your hand.

## Dead-code discovery workflow

Dead-code discovery is **not a single tool** — it's a mandatory three-step workflow. Skipping step 2 is the #1 way this family produces regressions.

1. **`tldr dead`** to discover candidates. Treat output as a hypothesis list, not a delete list. The `possibly_dead` bucket specifically means "exactly one identifier reference exists in the codebase, and that one reference is the function's own definition." Public exports, reflection-called code, framework callbacks, and decorated routes all legitimately land in `possibly_dead`.
2. **`tldr references <name>`** on every `possibly_dead` candidate before deletion. This is the verdict step; `dead` is only discovery. Once an entry point is identified as a known false positive, whitelist it via `tldr dead --entry-points name1,name2,...`.
3. **`tldr-trace-data-flow` → `dead-stores`** only AFTER function-level deletions, when scrubbing wasted assignments inside a surviving function. `dead-stores` lives in the sibling data-flow skill because it's a per-function SSA pass at variable granularity, not a project-wide call-graph op.

If the question is narrower — "is THIS one named function unused?" — skip `dead` entirely and go straight to `tldr references <name>`.

## Tool reference

### `tldr calls` — project-wide forward call graph

Project-wide function-to-function call graph in one shot — every cross-file edge, ready to pipe into Graphviz.

**Why reach for it**:
- Single command yields the whole forward call graph; no per-function probing required
- DOT format (`-f dot`) renders directly through `dot -Tsvg` for visualization
- Daemon-cached and byte-identical between cold and warm runs — sub-200ms warm
- `nodes` is the union of edge endpoints AND every defined function, so the inventory stays faithful even when functions have no edges

**When to use**:
- Want the whole project's "who calls whom" map, not just one function's neighborhood
- Need a visual call graph for review, docs, or architecture discussions
- Feeding a downstream graph tool (Graphviz, gephi, custom)

**When NOT to use**:
- Investigating one function's callers — use `tldr impact <fn>` (reverse, recursive)
- Finding every use of a symbol regardless of call/read/write — use `tldr references`
- Just want the top-N most-connected functions — that's centrality, covered in `tldr-architecture` (`hubs`)

**Usage**:
```bash
tldr calls [path] [-l <lang>] [-f json|dot] [--max-items <N>]
```

**Output**: JSON with `nodes` (every defined function), `edges` (caller→callee with `call_type`), and `total_edges`/`shown_edges`/`truncated` so the caller can tell when the default `--max-items 200` cap fired.

**Killer detail**: Edges are sorted alphabetically by `src_file:src_func` BEFORE truncation — `--max-items 5` returns the alphabetically-first 5, NOT the most important. Pass `--max-items 99999` for the full graph; there is no importance ranking.

---

### `tldr references` — every use site of one symbol, classified

Every use-site of a symbol across the codebase, AST-verified and classified as call/read/write/import/type.

**Why reach for it**:
- Replaces `grep -rn` with kind classification, confidence scores, and false-positive filtering
- Surfaces ALL definitions when a symbol name lives in multiple files (e.g., the same helper in three modules)
- `--kinds import` reveals importers a call-graph view would miss; `--kinds write` finds mutation sites
- Friendly "no results" stderr block suggests recovery steps when the search comes up empty

**When to use**:
- Need a flat enumeration of every use site of one symbol — broader than calls (also reads, writes, imports, types)
- Verifying a `possibly_dead` candidate from `tldr dead` really has only one reference
- Renaming preparation, where you need to find every touch point
- Same symbol exists in multiple files and you need to see all definitions

**When NOT to use**:
- Want recursive callers-of-callers — use `tldr impact <fn>` (this is flat, level-1 only)
- Want the whole-project edge list — use `tldr calls`
- Just looking up where a name is declared — use `tldr definition` in `tldr-understand-function`

**Usage**:
```bash
tldr references <symbol> [path] [-l <lang>] [--kinds call,read,write,import,type] [--scope workspace|file] [--limit <N>]
```

**Output**: JSON with `definitions[]` (all matches), `references[]` (each with `kind`, `confidence`, single-line `context`), `total_references` vs `shown_references`, and a `search_scope` that reports the ACTUAL scope used.

**Killer detail**: `--scope workspace` is the default but the engine silently auto-narrows to `file` when the symbol looks file-local — always read `search_scope` in the response to know what was actually searched.

**Other footguns**:
- `--kinds invalid_kind` is a silent failure: unknown kinds become a filter matching nothing and you get zero results with no clap rejection. Stick to `call`, `read`, `write`, `import`, `type`.
- `--limit 0` means LITERAL zero references returned, not unlimited. Pass `--limit 999999` for "all."
- `--context-lines N` is plumbed but unimplemented per `--help`; context is always one line.

---

### `tldr impact` — recursive reverse caller tree (blast radius)

Recursive reverse call graph for one function — every caller, every caller-of-caller, up to `--depth`, with blast-radius totals.

**Why reach for it**:
- Single command answers "if I change this signature, who breaks?" — recursive, not flat
- Function-not-found errors include "Did you mean:" suggestions (exit 20) — agents can parse and retry
- `-f dot` emits a real reverse Graphviz graph (`rankdir=RL`); pipe to `dot -Tpng` for a picture
- Auto-recovers cross-file edges the AST builder misses via a references-enrichment fallback

**When to use**:
- About to change a function's signature, return type, or delete it
- Need to enumerate the transitive caller tree, not just direct callers
- Pre-refactor risk assessment on a known function name

**When NOT to use**:
- Want a flat list of EVERY use site (calls, reads, writes, imports) — use `tldr references`
- Don't know the function name yet — discover it first via `tldr-locate-code`
- Want the whole project's edges — `tldr calls` (forward) or `tldr-architecture` (`hubs` for centrality)
- Question is "what tests will break from this diff?" — that's `whatbreaks` in `tldr-change-impact`

**Usage**:
```bash
tldr impact <function> [path] [-l <lang>] [--depth <N>] [-f json|dot]
```

**Output**: JSON `targets` map keyed by `"file:function"` (one symbol can resolve in multiple files), each with `caller_count` and a recursive `callers[]` tree carrying `note` fields that mark when results came from the references-enrichment fallback.

**Killer detail**: On Python (and C#, Kotlin, Scala, OCaml, Lua), `--depth` is silently a no-op — the AST call graph misses cross-file edges, the references-enrichment fallback fills them in but only at level 1. Watch for `"Discovered via references"` notes in the output to confirm depth is being ignored. `--type-aware` is registered but unimplemented; ignore it.

---

### `tldr dead` — project-wide unreachable-function detector

Project-wide unreachable-function detector — what code is safe to delete.

**Why reach for it**:
- Replaces hand-rolled `grep` with framework-aware analysis (`'use server'`, `.d.ts`, decorators all handled)
- Splits results into definitively-dead (zero refs) and possibly-dead (single ref = the definition itself)
- Refcount mode is single-pass and fast; `--call-graph` available when precision matters
- Whitelist known entry points via `--entry-points name1,name2,...` to suppress false positives

**When to use**:
- Cleaning up before a refactor and want a list of deletion candidates
- Auditing legacy code paths during onboarding
- Need a baseline "dead percentage" for tech-debt tracking

**When NOT to use**:
- Verifying ONE function is unused — `tldr references <name>` is the direct answer
- Hunting unused assignments inside functions — that's `dead-stores`, covered in `tldr-trace-data-flow`

**Usage**:
```bash
tldr dead [path] [-l <lang>] [--call-graph] [--entry-points name1,name2,...] [--max-items <N>]
```

**Output**: JSON with `dead_functions` (0 refs), `possibly_dead` (1 ref), a `by_file` grouping, and totals including a `dead_percentage`. The list is paged by `--max-items`; the totals always reflect the full count.

**Killer detail**: `possibly_dead` means "exactly one identifier reference exists in the codebase" — that one reference is the function's own definition. Public exports, reflection-called code, framework callbacks, and decorated routes all legitimately land here, so **always verify a candidate with `tldr references <name>` before deleting**. See the "Dead-code discovery workflow" section above.

## Common mistakes

- **Using `tldr calls` to investigate one function's neighborhood.** Calls returns the whole project's edges sorted alphabetically; `--max-items 5` gives the alphabetically-first 5, not the ones around your function. For per-function questions, use `impact` (reverse) or filter the calls output post-hoc.
- **Using `tldr references` and expecting recursive callers.** References is FLAT — level-1 use sites only. "Who calls the callers of `foo`?" needs `impact`, not references with a higher limit.
- **Trusting `tldr impact --depth N` on Python.** On Python (also C#, Kotlin, Scala, OCaml, Lua) `--depth` is silently a no-op — the references-enrichment fallback only fills level 1. Check for `"Discovered via references"` notes in the output before reporting a depth-N tree.
- **Reaching for `tldr calls` to get "the most important functions."** Calls has no importance ranking and truncates alphabetically. Centrality lives in `tldr-architecture` (`hubs`).
- **Ignoring `search_scope` on `references` output.** `--scope workspace` is the default, but the engine silently auto-narrows to `file` for file-local symbols. A "1 reference" result under a narrowed scope is not project-wide.
- **Deleting a `possibly_dead` candidate without running `references`.** The #1 way the dead-code workflow produces regressions. `dead` is discovery; `references` is the verdict. Always verify, every time.
- **Reaching for `dead-stores` when you meant `dead`** (or vice versa). `dead-stores` is per-function and finds unused *assignments*; `dead` is project-wide and finds unused *functions*. Wrong granularity, silent disappointment. `dead-stores` lives in `tldr-trace-data-flow`.
- **Staying in this skill when the bug is about a VALUE.** If you've spent five `impact` calls chasing callers and the bug is actually that some assignment inside one function clobbers the result, you needed `tldr-trace-data-flow` (`slice` or `reaching-defs`) two calls ago. When the question turns from "where is X used" to "why is X wrong here," cross the trace→data-flow boundary.
- **Using `tldr impact` for "what tests will break?"** Impact gives the caller tree, not test breakage. The right tool is `whatbreaks` in `tldr-change-impact`, which takes a diff rather than a function name.

## See also

- `tldr-trace-data-flow` — when the question is about VALUES, variables, or which lines mathematically influence another line (slice, chop, reaching-defs, dead-stores). Cross this boundary when "where is X used" becomes "why is X wrong here."
- `tldr-change-impact` — when starting from a git diff rather than a function name (change-impact, whatbreaks). `impact` is shared in spirit but takes a function; `whatbreaks` takes a diff and reports test breakage.
- `tldr-locate-code` — when you don't yet have the symbol name to feed `references`, `impact`, or `dead` verification.
- `tldr-understand-function` — when you want to inspect what a function DOES (signature, complexity, body, definition) rather than its relationships.
- `tldr-architecture` — when the question is "which functions are the most-connected hubs?" rather than "what touches this one function?" (`hubs`, centrality, coupling).
