# tldr calls

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/trace/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Project-wide function-to-function call graph in one shot — every cross-file edge, ready to pipe into Graphviz.

**Why reach for it**
- Single command yields the whole forward call graph; no per-function probing required
- DOT format (`-f dot`) renders directly through `dot -Tsvg` for visualization
- Daemon-cached and byte-identical between cold and warm runs — sub-200ms warm
- `nodes` is the union of edge endpoints AND every defined function, so the inventory stays faithful even when functions have no edges

**When to use**
- Want the whole project's "who calls whom" map, not just one function's neighborhood
- Need a visual call graph for review, docs, or architecture discussions
- Feeding a downstream graph tool (Graphviz, gephi, custom)
- Discovering candidate hubs by eyeballing the edge set before drilling in

**When NOT to use**
- Investigating one function's callers — use `tldr impact <fn>` (reverse, recursive)
- Finding every use of a symbol regardless of call/read/write — use `tldr references`
- Just want the top-N most-connected functions — use `tldr hubs`

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```
tldr calls [OPTIONS] [PATH]
tldr calls backend/providers -l python                     # P01 — happy path
tldr calls backend/providers -l python -f dot              # P08 — dot/Graphviz output
```

**Output in plain words**: JSON with `nodes` (every defined function), `edges` (caller→callee with `call_type`), and `total_edges`/`shown_edges`/`truncated` so the caller can tell when the default `--max-items 200` cap fired.

**Killer detail**: Edges are sorted alphabetically by `src_file:src_func` BEFORE truncation — `--max-items 5` returns the alphabetically-first 5, NOT the most important. Pass `--max-items 99999` for the full graph; there is no importance ranking.

**Source**: `research/tldr/trace/calls.md`
