# tldr hubs

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/trace/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Top-N most-central functions in the call graph, ranked by a composite of in-degree, out-degree, PageRank, and betweenness.

**Why reach for it**
- Discovers candidate "choke point" functions WITHOUT needing a function name to start with
- Composite score and `risk_level` (LOW/MEDIUM/HIGH/CRITICAL) give an immediate prioritization signal
- `--algorithm` lets the caller pick the centrality lens: `indegree` (called by many), `pagerank` (called by important callers), `betweenness` (bottlenecks)
- Best path-error UX in the entire CLI — passing a file instead of a directory yields a friendly recovery hint

**When to use**
- Picking refactor or test-coverage targets and need data on what matters most
- Looking for architectural bottlenecks before a redesign
- Want the executive summary of the call graph, not the whole graph

**When NOT to use**
- You already have a function name and want its neighborhood — use `tldr impact <fn>`
- Need the full edge list for visualization — use `tldr calls -f dot`
- Ranking by code complexity, not network position — use `tldr complexity`

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```
tldr hubs [OPTIONS] [PATH]
tldr hubs backend/providers -l python                      # P01 — happy path
tldr hubs backend -l python --algorithm pagerank           # P12 — pagerank centrality
```

**Output in plain words**: JSON with `hubs[]` (each entry has function ref, composite score, per-algorithm metrics, risk level), `total_nodes`, `measures_used`, and `pagerank_info` when applicable.

**Killer detail**: `-f dot` does NOT emit a call graph — it emits the top hubs as standalone labeled boxes chained by invisible edges to force Graphviz into a vertical list. For a real DOT call graph, use `tldr calls -f dot` instead.

**Source**: `research/tldr/trace/hubs.md`
