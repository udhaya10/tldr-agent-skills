# tldr context

**Pitch**: Packs an entry function plus its transitive callees into one LLM-ready markdown bundle, sized to drop into a prompt.

**Why reach for it**
- Replaces "read the function, then chase every helper it calls" with a single command
- `-f text` emits markdown via `to_llm_string()` — paste-ready, no post-processing
- Daemon-cached path is ~35x faster than rebuild on repeat queries against the same project
- Depth knob (`-d`) lets the caller trade context completeness against token budget

**When to use**
- About to hand a function and its dependencies to another model or skill
- Investigating an unfamiliar entry point and want signature + callees in one shot
- Building a focused review pack for a single function instead of slurping whole files
- Need cyclomatic / block metrics alongside the dependency tree

**When NOT to use**
- Just need raw caller/callee edges — use `tldr calls` and skip the per-node decoration
- Want deep single-function analysis without the transitive walk — use `tldr explain`

**Output in plain words**: A `RelevantContext` payload listing the entry plus every reachable function within depth, each with signature, file (relative to PATH), line, callees, and complexity. Text format renders the same data as markdown with code-block-wrapped signatures.

**Killer detail**: Using `--file` or the `<file>:<func>` shorthand silently disables the daemon route — the protocol can't carry those filters, so disambiguation costs the speedup.

**Other footguns**
- `--file` is interpreted relative to PATH, not cwd. When `PATH=backend`, pass `--file providers/yahoo.py`, NOT `--file backend/providers/yahoo.py` — the latter silently matches nothing and returns `functions: []` with exit 0.
- With default `PATH=.` and no `-l`, duplicate function names across the project resolve via silent first-match-wins (e.g. `_to_finite_float` picks `precomputed_indicators.py` over `providers/yahoo.py`). Always scope PATH and pass `-l` when the name might be ambiguous.

**Source**: `research/tldr/search/context.md`
