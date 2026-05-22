# tldr dead-stores

**Pitch**: SSA-based dead-store detector — assignments to variables whose values are never subsequently read, scoped to a single function.

**Why reach for it**
- Compiler-grade detection catches control-flow-merge cases that grep misses (phi-node stores flagged via `is_phi`)
- `--compare` runs both SSA and live-variables analyses in one call — intersect the two for high-confidence findings
- Each finding carries `variable`, `ssa_name`, `line`, `block_id` — directly addressable for surgical refactors
- Default SSA-only output is conservative; opt into live-vars only when investigating

**When to use**
- Refactoring a function and want every wasted assignment in one pass
- Catching typos like `result = compute()` followed by `return reseult`
- Auditing debug leftovers and unused intermediate values
- Cross-validating findings — pass `--compare` and treat the intersection of `dead_stores_ssa` and `dead_stores_live_vars` as actionable

**When NOT to use**
- Looking for entire unused functions, not unused assignments — use `tldr dead` (function-level, not store-level)
- Tracing where a variable was defined — use `tldr reaching-defs` (the complementary view)

**Output in plain words**: A report with `dead_stores_ssa` (always populated) and `dead_stores_live_vars` (only when `--compare` is set, otherwise null), each entry naming the variable, its SSA-renamed form, line, and CFG block.

**Killer detail**: Function-not-found returns exit 1 here, NOT exit 20 — this command lives in the contracts namespace with its own `ContractsError` enum, breaking the convention used by every other deep-group command and by `impact`/`explain`/`context`. Agents scripting around dead-stores cannot rely on the exit-20-means-function-not-found pattern.

**Source**: `research/tldr/deep/dead-stores.md`
