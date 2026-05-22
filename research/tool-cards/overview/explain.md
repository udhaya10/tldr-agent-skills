# tldr explain

**Pitch**: Deep-dive on one named function — signature, purity, complexity, callers, and callees — consolidated into one report.

**Why reach for it**
- One call replaces piping through `tldr extract` + `tldr complexity` + `tldr calls` + `tldr references`
- Cyclomatic value is the canonical one from `tldr_core` — safe to compare across commands
- Purity classifier emits a four-state verdict (`pure`, `impure`, `unknown-medium`, `unknown-low`) with effect tags, so the agent can reason about blast radius before editing
- Accepts both bare names and `Class.method` qualified form

**When to use**
- About to modify a function and need to know who calls it and what it touches
- Triaging "should I refactor this?" — purity + caller count is the signal
- Wanting both call directions plus context in one shot, not two

**When NOT to use**
- Don't know the function name yet — start with `tldr extract` to get the roster
- Only need the declaration site — `tldr definition` is cheaper
- Need a single numeric metric — `tldr complexity` is leaner

**Output in plain words**: A typed report with the function's location range, signature, purity verdict with effects, complexity numbers, and merged caller/callee lists (external callees marked with a `<external>` sentinel file).

**Killer detail**: `--depth` is dead code in v0.4.0 — declared on the struct but never read. Depths 0, 2, and 5 produce byte-identical output. Don't waste tokens setting it.

**Source**: `research/tldr/overview/explain.md`
