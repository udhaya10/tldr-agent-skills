# Lens: Locating code — family chooser

**The question this lens answers**: "I need to find code in this project — which of `search`, `semantic`, `similar`, `dice` should I reach for?"

**Toolset**: `tldr search`, `tldr semantic`, `tldr similar`, `tldr dice`

**Why a family-chooser lens, why these tools**: All four answer "find code," but each answers a *different* underlying question. Picking the wrong one wastes time and can silently return empty results — none of these four loudly fails when given the kind of query that's wrong for it. The discriminator isn't what you want OUT; it's the shape of what you have GOING IN.

## Decision tree

| You already have... | And you want... | Reach for |
|---------------------|-----------------|-----------|
| A token, identifier, or regex | All occurrences with surrounding context (signatures, callers, callees) | `tldr search` |
| A concept in your own words, no shared vocabulary | Implementations of that concept | `tldr semantic` |
| One example function or file | Other functions/files that are like it | `tldr similar` |
| Two specific functions or files | A single number scoring how alike they are | `tldr dice` |

## The default

**`tldr search` first, always — if you have any token to anchor on.** It's the cheapest, fastest, most deterministic of the four. Sub-second on most repos, no model inference, no embedding cache to warm. Escalate only when search returns empty AND you genuinely have no shared vocabulary with the codebase.

## Common mistakes

- **Reaching for `tldr semantic` first because it sounds smarter.** Semantic is slower, less deterministic, and worse than search whenever any shared vocabulary exists. Use semantic only when your terms genuinely don't appear in code ("billing logic" might map to `ChargeProcessor.run`).
- **Using `tldr similar` with relative `-p`.** Always pass absolute paths or omit `-p` entirely. The smart-path fallback only kicks in for the literal default `.`; any other relative path returns "no indexed chunks found."
- **Using `tldr dice` with `file::function` target form.** That form is dead — it silently compares whole files. Use `file:start:end` line ranges (sourced from `tldr extract`) for true function-level comparison.
- **Skipping `-l <lang>` on multi-language repos.** All four tools auto-detect language by dominant file count; the wrong guess is silent. A search for `"database"` on a JS-dominant root returns zero Python matches without warning.
- **Using `tldr semantic`'s `--langs` with language names.** It takes file extensions (`py`, `rs`), not names (`python`, `rust`). Unknown values are silently dropped — check `total_chunks` before trusting an empty result.

## What this lens captures

A clean discriminator: cardinality of input + nature of what you know determines the tool. Once you internalize the four "you already have" rows above, picking is mechanical.

## What this lens misses

This is a *picking* lens — it deliberately collapses sequencing and composition:

- **Sometimes `semantic` THEN `search` is right.** Use `semantic` to discover what terms exist, then `search` exhaustively on those terms. The family-chooser frame doesn't surface that chain.
- **Once located, what next?** This lens stops at "you've found it." For the follow-up ("now tell me about this function"), see `understanding-a-function-family-chooser.md`.
- **Cross-file relationships.** None of these four traces callers or impact. For that, you need `tldr references`, `tldr calls`, or `tldr impact`.

## Pair with

- `understanding-a-function-family-chooser.md` — what to do AFTER locating
- *(future)* `code-discovery-sequence.md` — when chaining beats picking

## Sources

- `research/tool-cards/search/search.md`
- `research/tool-cards/search/semantic.md`
- `research/tool-cards/search/similar.md`
- `research/tool-cards/search/dice.md`
