# tldr invariants

**Pitch**: Daikon-lite inferencer that watches argument and return values across a test suite and emits the type/range/relation invariants those tests actually establish.

**Why reach for it**
- Surfaces what the test suite EMPIRICALLY proves about a function — independent of the code's stated contract
- Cross-argument `relation` invariants (e.g., `arg1 < arg2`) catch coupling that single-variable analyses miss
- Confidence is observation-count driven, so high-confidence invariants are well-supported by data
- Pairs cleanly with `tldr contracts` to triangulate: code-stated contract vs test-observed behavior — divergence flags gaps

**When to use**
- Refactoring a function and need a behavioral safety net beyond what asserts encode
- Auditing whether tests actually exercise meaningful constraints (or just cover lines)
- Reverse-engineering an API by feeding its test suite and extracting the implicit numeric/type contract
- Deciding which inputs are worth fuzzing — anything outside the inferred `range` is unexplored

**When NOT to use**
- The codebase has no real test suite, or tests use only generated/random inputs (inferences will be thin or misleading)
- Need function pre/post inferred from CODE rather than test data — that's `tldr contracts`

**Output in plain words**: Per-function blocks listing preconditions and postconditions as `Invariant` records with positional variable names (`arg0`, `arg1`, ..., `result`), an `expression` string, `kind` (`type`, `range`, `relation`, etc.), and an observation count. Summary reports total observations and how many test files/functions were scanned.

**Killer detail**: Variables are NAMED POSITIONALLY — `arg0`, `arg1`, never by the source parameter name. Mapping `arg0` back to `value` (or whatever the signature calls it) requires inspecting the source separately, usually via `tldr extract`.

**Source**: `research/tldr/audit/invariants.md`
