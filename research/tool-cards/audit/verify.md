# tldr verify

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/audit/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Constraint-coverage dashboard that runs `contracts`, `specs`, and optionally `invariants` + `patterns` over a path and reports what percentage of constraint-relevant functions are actually specified.

**Why reach for it**
- One command instead of orchestrating four sub-analyzers and aggregating their output
- Returns a single `coverage_pct` metric for "how much of this code is specified" — agent-friendly headline
- `--quick` mode skips the expensive invariants/patterns sub-analyses (5–10x faster)
- `partial_results: true` flag plus per-sub-analyzer status lets the agent distinguish real bugs from expected failures (e.g., `specs` failing because no `tests/` dir exists)

**When to use**
- Auditing a codebase for specification gaps before a refactor
- Wanting a CI signal of "is constraint coverage trending up or down" over time
- Picking a target area: the sub-analyzer with lowest items_found is where contract work is needed
- Replacing a hand-rolled `contracts + specs + invariants` pipeline

**When NOT to use**
- Need security findings — use `tldr secure` (security-focused) instead
- Need general code-quality metrics (complexity, dead code) — that's `tldr health`, not `verify`
- Need just one sub-analyzer's full detail — call it directly rather than parsing the aggregate

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```
tldr verify [OPTIONS] [PATH]
```
```
tldr verify backend/providers --quick             # --quick strongly recommended
tldr verify backend --quick                       # larger directory
tldr verify backend/providers --quick --detail contracts
```

**Output in plain words**: A JSON dashboard with a KEYED `sub_results` object (`contracts`, `specs`, optionally `invariants` and `patterns`), a `summary` block with total spec/contract/invariant counts plus a `coverage` sub-object, and timing/file counts.

**Killer detail**: `coverage_pct` is a percentage of CONSTRAINT-RELEVANT functions (a subset of all project functions), not of every function in the repo — the `coverage.scope` field literally says so. For project-wide coverage, divide constraint counts by `tldr structure`'s `total_functions` instead.

**Other footguns**
- `--detail <X>` is SILENTLY IGNORED — `--detail contracts`, `--detail wat`, or omitting it all produce byte-identical JSON. Skip the flag.
- Silent Python fallback on non-Python projects: README.md, lang-mismatched dirs, and empty dirs all return the same 40-line empty result. Pass `-l <lang>` explicitly for non-Python work.

**Source**: `research/tldr/audit/verify.md`
