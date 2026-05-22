# tldr impact

**Pitch**: Recursive reverse call graph for one function — every caller, every caller-of-caller, up to `--depth`, with blast-radius totals.

**Why reach for it**
- Single command answers "if I change this signature, who breaks?" — recursive, not flat
- Function-not-found errors include "Did you mean:" suggestions (exit 20) — agents can parse and retry
- `-f dot` emits a real reverse Graphviz graph (`rankdir=RL`); pipe to `dot -Tpng` for a picture
- Auto-recovers cross-file edges the AST builder misses via a references-enrichment fallback

**When to use**
- About to change a function's signature, return type, or delete it
- Need to enumerate the transitive caller tree, not just direct callers
- Pre-refactor risk assessment on a known function name

**When NOT to use**
- Want a flat list of EVERY use site (calls, reads, writes, imports) — use `tldr references`
- Don't know the function name yet — discover it via `tldr search` or `tldr hubs` first
- The whole project's edges — `tldr calls` (forward) or `tldr hubs` (centrality summary)

**Output in plain words**: JSON `targets` map keyed by `"file:function"` (one symbol can resolve in multiple files), each with `caller_count` and a recursive `callers[]` tree carrying `note` fields that mark when results came from the references-enrichment fallback.

**Killer detail**: On Python (and C#, Kotlin, Scala, OCaml, Lua), `--depth` is silently a no-op — the AST call graph misses cross-file edges, the references-enrichment fallback fills them in but only at level 1. Watch for `"Discovered via references"` notes in the output to confirm depth is being ignored. `--type-aware` is registered but unimplemented; ignore it.

**Source**: `research/tldr/trace/impact.md`
