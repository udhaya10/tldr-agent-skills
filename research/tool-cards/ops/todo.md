# tldr todo

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/ops/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Unified refactor checklist that runs four sub-analyses (dead code, complexity, cohesion, similar) and aggregates the findings into a single prioritized, scored `items[]` list.

**Why reach for it**
- One command replaces running `dead`, `complexity`, `cohesion`, and `similar` separately
- Every item ships with `priority` (sortable int), `severity`, and a 0.0–1.0 `score` for actionability filtering
- `--quick` skips the expensive similar-analysis when fast iteration matters
- `--detail <sub-analysis>` expands one section inline for drill-down without re-running

**When to use**
- Generating a "what should I refactor next" checklist for a file or directory
- Pre-PR audit: sort items by priority and address the top N
- Pairing with `tldr hotspots` — hotspots tells you WHERE to start, todo tells you WHAT to do once there
- Driving a CI gate that fails on `severity == "critical"` items

**When NOT to use**
- Hunting a specific code smell — use `tldr smells`
- Wanting a single health score — use `tldr health`
- Wanting churn-weighted priorities — use `tldr hotspots`

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```
tldr todo [OPTIONS] <PATH>
```
```
# P01 — quick scan of a directory
tldr todo backend/providers --quick
# P02 — quick scan of a broader tree
tldr todo backend --quick
# P10 — drill into dead-code details
tldr todo backend/providers --quick --detail dead
```

**Output in plain words**: JSON with `wrapper: "todo"`, the input `path`, an `items` array of `{category, priority, description, file, line, severity, score}` entries, a `summary` block aggregating sub-analysis counts, and `total_elapsed_ms`.

**Killer detail**: `--max-items 0` means "show all" here, but in `tldr contracts`, `tldr patterns`, and `tldr surface` the same flag means "literally zero." This cross-command divergence is the trap — always check the per-command help before relying on 0 as a sentinel.

**Source**: `research/tldr/ops/todo.md`
