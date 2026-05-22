# tldr cohesion

**Pitch**: LCOM4 analyzer that measures whether the methods inside a single class actually share state — and, when they don't, hands back the exact method groupings to split into.

**Why reach for it**
- `lcom4 = 1` means "cohesive"; `lcom4 > 1` means the class has methods that don't touch any shared fields — concrete split candidates
- When verdict is `"split_candidate"`, the engine pre-computes `components[].methods` AND a `split_suggestion` string — the refactor plan is in the output
- Operates per-class with union-find on the method↔field graph, so the answer is structural rather than heuristic
- Bounded by hard limits (`MAX_METHODS_PER_CLASS`, 30s timeout) so it stays bounded on pathological inputs

**When to use**
- Reviewing a god class and want a defensible "split into these N groups" recommendation
- Auditing whether classes follow the Single Responsibility Principle
- Identifying utility classes masquerading as cohesive ones (low LCOM, many unrelated method groups)
- A counterpart to `tldr coupling` for the classic "high cohesion, low coupling" check

**When NOT to use**
- Need module-level dependency analysis (between classes/files) — that's `tldr coupling`
- Want generic anti-pattern detection across many smell types — `tldr smells --deep` includes cohesion

**Output in plain words**: A `classes[]` array — each entry has `lcom4`, `method_count`, `field_count`, `verdict` (`"cohesive"` or `"split_candidate"`), `components[]` with explicit method/field groupings, and an actionable `split_suggestion` string when applicable — plus a `summary` rollup.

**Killer detail**: It is Python-only despite accepting `--lang`. The parser hardcodes `tree_sitter_python::LANGUAGE`, so `--lang typescript` is silently ignored and returns whatever Python classes exist (or empty silently on a non-Python tree). Three distinct failure modes (empty dir, non-Python file, Python file with no classes) all produce the identical empty shape with no `warnings`.

**Source**: `research/tldr/audit/cohesion.md`
