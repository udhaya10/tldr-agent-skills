# tldr health

**Pitch**: One-shot code-quality dashboard that runs six sub-analyzers (complexity, cohesion, dead_code, martin, coupling, similarity) concurrently and returns a unified summary.

**Why reach for it**
- The right FIRST command in any audit — `--quick --summary` triages a codebase in one call instead of running six tools and aggregating their JSON
- `--detail <analyzer>` drills into one sub-analyzer's full output after the summary flags a problem — single command for both triage and deep-dive
- `--quick` skips the expensive cross-file analyses (coupling + similarity) — usable on real codebases at interactive speeds
- Returns hotspot counts, dead-code percentage, and average cyclomatic in one block — the typical "is this codebase healthy?" headline

**When to use**
- Starting any code audit cold — get the lay of the land before picking a specific tool
- Asked "what's the worst part of this codebase?" — summary surfaces hotspots and low-cohesion classes
- CI health gate that needs one number across several dimensions
- Routing decision: high `hotspot_count` → `tldr complexity` + `tldr cognitive`; high `dead_percentage` → `tldr dead`

**When NOT to use** (versus individual audit tools)
- Already know the dimension (just complexity, just cohesion, just dead code) — call the specific tool; health adds latency for analyses you'll ignore
- Need security findings — health doesn't cover `tldr secure`/`tldr vuln`/`tldr taint`
- Need constraint/spec coverage — use `tldr verify`, which aggregates a different set (contracts + specs + invariants + patterns)

**Output in plain words**: A summary block with files/functions/classes analyzed, average cyclomatic, hotspot counts, dead-code percentage, and (in full mode) coupling/similarity pair counts. `--detail <name>` swaps the summary for one sub-analyzer's full per-item output.

**Killer detail**: Health is SLOW on real codebases — 9.7 seconds for 56 files even in `--quick` mode, and there is NO daemon caching, so repeat calls recompute everything. Budget the latency and prefer `--quick --summary` for triage; only drop `--quick` when coupling/similarity numbers are actually needed.

**Source**: `research/tldr/audit/health.md`
