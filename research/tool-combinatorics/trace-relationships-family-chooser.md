# Lens: Trace relationships — family chooser

**The question this lens answers**: "I have a function or symbol — which of `calls`, `references`, `impact` gives me the relationship view I actually need?"

**Toolset**: `tldr calls`, `tldr references`, `tldr impact`

**Why a family-chooser lens, why these tools**: All three return "things connected to code," but they answer different relationship questions at different cardinalities. The clean discriminator is the *cardinality axis* — how many entities go in, what shape comes out, and whether the walk is recursive. Picking the wrong one is rarely a hard failure; it just wastes the call or hides the answer in noise.

## Decision tree by cardinality

| You have... | You want... | Walk shape | Reach for |
|-------------|-------------|------------|-----------|
| Nothing — the whole project | Every caller→callee edge in one graph | Many-edges, forward, flat | `tldr calls` |
| One symbol name (any kind) | Every use site classified as call / read / write / import / type | One-symbol, flat list, all-kinds | `tldr references` |
| One function name | The recursive caller tree — callers, callers-of-callers, blast radius | One-function, reverse, recursive | `tldr impact` |

## The default

**Default depends on what's in your hand.** This family has no universal first move because the three tools each take a different input shape:

- Have a **function name** and want "what depends on me?" → `tldr impact` (reverse, recursive)
- Have **any symbol** and want "where is this touched?" → `tldr references` (flat, all use kinds)
- Have **the whole project** and want the edge graph → `tldr calls` (forward, project-wide)

When in doubt about which input you actually have: if you can't say "I want callers OR I want the project graph," you probably want `references` — it's the broadest and the only one that surfaces non-call use sites (reads, writes, imports, type references).

## Common mistakes

- **Using `tldr calls` to investigate one function's neighborhood.** Calls returns the whole project's edges sorted alphabetically; `--max-items 5` gives the alphabetically-first 5, not the ones around your function. For per-function questions, use `impact` (reverse) or filter the calls output post-hoc.
- **Using `tldr references` and expecting recursive callers.** References is FLAT — level-1 use sites only. "Who calls the callers of `foo`?" needs `impact`, not references with a higher limit.
- **Using `tldr impact` on Python and trusting `--depth`.** On Python (also C#, Kotlin, Scala, OCaml, Lua) `--depth` is silently a no-op — the references-enrichment fallback only fills level 1. Check for `"Discovered via references"` notes in the output before reporting a depth-N tree.
- **Reaching for `tldr calls` to get a list of "the most important functions."** Calls has no importance ranking and truncates alphabetically. Use `tldr hubs` for centrality.
- **Ignoring `search_scope` on references output.** `--scope workspace` is the default but the engine silently auto-narrows to `file` for file-local symbols. The actual scope used is in the response — read it before trusting the count.
- **Using `tldr impact` for "what tests will break?"** Impact gives the caller tree, not test breakage. The right tool is `trace/whatbreaks`, covered separately in `change-impact-family-chooser.md`.

## What this lens captures

The cardinality framing is durable. One input shape (project / symbol / function) plus one output shape (edge graph / flat list / recursive tree) picks the right tool without overlap.

## What this lens misses

- **Centrality and architectural hubs.** "Which functions are the project's most-connected nodes?" is `tldr hubs`, not in this family.
- **Test-breakage cascades.** "If I change this, which tests fail?" is `trace/whatbreaks`, covered in `change-impact-family-chooser.md`.
- **Dead code.** "Which functions have zero references?" is `tldr dead` (function-level), often verified with a `tldr references` follow-up.

## Pair with

- `understanding-a-function-family-chooser.md` — what to do AFTER you have the relationship and want to read the function itself
- `change-impact-family-chooser.md` *(future / sibling)* — `whatbreaks` + `change-impact` for test-impact reasoning
- `locating-code-family-chooser.md` — what to do BEFORE you have a name to feed these three tools

## Sources

- `research/tool-cards/trace/calls.md`
- `research/tool-cards/trace/references.md`
- `research/tool-cards/trace/impact.md`
