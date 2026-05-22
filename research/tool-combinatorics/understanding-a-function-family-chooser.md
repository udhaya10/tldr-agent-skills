# Lens: Understanding a function — family chooser

**The question this lens answers**: "I have a function (a name, a cursor, or a file) — which of `definition`, `explain`, `extract`, `context` tells me what I need?"

**Toolset**: `tldr definition`, `tldr explain`, `tldr extract`, `tldr context`

**Why a family-chooser lens, why these tools**: All four answer "tell me about this function," but at different cardinalities and depths. The cleanest discriminator is the *cardinality of input → output*: that single dimension picks the right tool nearly every time. Going deeper than needed wastes tokens; going shallower than needed sends you back for a second call.

## Decision tree by cardinality

| Input cardinality | Output cardinality | Tool | Relative cost |
|-------------------|--------------------|------|---------------|
| One cursor (file + line + col) | One binding site | `tldr definition` | Cheapest |
| One named function | One comprehensive report (signature + purity + complexity + both call directions) | `tldr explain` | Medium |
| One file | All definitions in the file + intra-file call graph | `tldr extract` | Medium |
| One entry point | A transitive walk (entry + every callee within depth) | `tldr context` | Largest |

## The decision rule

- **Don't know the function name yet** → `tldr extract` on the file. Get the roster, then pick.
- **Know the name, just need where it lives** → `tldr definition`. One result, cheap.
- **Know the name, deciding whether to refactor** → `tldr explain`. Purity verdict + caller count is the signal.
- **Know the name, handing to another model** → `tldr context`. The bundle is exactly what the next-stage prompt wants.

## Common mistakes

- **Reaching for `tldr context` when `tldr explain` would do.** Context's transitive walk is expensive. If you only need to understand the function in isolation (not its callees), explain is the right tool and ~5× smaller output.
- **Using `tldr explain` to inventory a file's functions.** Explain takes one name; you'd be guessing. Use extract.
- **Setting `tldr explain --depth N`.** It's dead code in v0.4.0 — depths 0, 2, 5 produce byte-identical output. Don't waste tokens setting it.
- **Calling `tldr definition` with mismatched indexing.** Line is 1-indexed, column is 0-indexed. Editor-pipe coordinates (1-indexed both) silently fail with `unresolved at`. Always decrement column.
- **Calling `tldr context` with `--file` or `<file>:<func>` shorthand and expecting daemon speed.** Both silently disable the daemon route; you pay the cold-build cost.

## What this lens captures

The cardinality framing is durable — even when new sibling tools land, "what's the shape of your input and what shape do you need out?" still picks correctly.

## What this lens misses

- **Cross-file relationships.** This lens is one function at a time. For callers across files, use `tldr references` (it's about USAGES, not definitions). For blast-radius cascades, `tldr impact`.
- **Why the function exists historically.** Archaeology isn't covered here — `tldr churn` + git log + `tldr explain` together would be the archaeology lens on this toolset.
- **Refactor planning at the file/module level.** This is per-function; for module-scoping, `tldr structure` + `tldr cohesion` is a different lens.

## Pair with

- `locating-code-family-chooser.md` — what to do BEFORE you have a function name
- *(future)* `cross-file-relationships-family-chooser.md` — references vs calls vs impact

## Sources

- `research/tool-cards/overview/definition.md`
- `research/tool-cards/overview/explain.md`
- `research/tool-cards/overview/extract.md`
- `research/tool-cards/search/context.md` *(note: lives in the search group, but functionally belongs to this family)*
