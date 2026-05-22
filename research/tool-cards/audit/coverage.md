# tldr coverage

**Pitch**: Multi-format coverage report parser that turns Cobertura XML, LCOV, or coverage.py JSON into a uniform summary plus optional per-file breakdown.

**Why reach for it**
- One command absorbs all three common coverage formats; the JSON shape is normalized so downstream tools don't branch on format
- Threshold check, sort, and `--uncovered-only` filter are built in — no `jq` gymnastics for CI gating
- `--by-file --uncovered` emits the actual uncovered line numbers, which is what an LLM needs to propose new tests
- Best-in-class parse-error message in the audit suite (states cause AND fix)

**When to use**
- CI just produced a coverage report and the agent needs to know which files are below threshold
- Planning where to write tests: combine `--uncovered-only --uncovered` to get the file:line pairs that lack coverage
- Comparing coverage across runs without writing a custom parser
- The user provided an unknown coverage XML/LCOV file and the format needs auto-detecting

**When NOT to use**
- Need to know which functions are *adequately specified* by tests — that's `tldr specs` or `tldr invariants`, not line coverage
- The report doesn't exist yet — coverage parses existing reports, it does not run the test suite

**Output in plain words**: A summary block with line/branch/function percentages and a `threshold_met` boolean, plus (with `--by-file`) per-file entries each carrying uncovered lines and function names. Schema fields vary by format — LCOV gives branch + function rates, Cobertura and coverage.py give line coverage only.

**Killer detail**: Forcing `-R cobertura` on an LCOV file (or vice versa) silently returns `{ format: "cobertura", summary: { line_coverage: 0.0, total_lines: 0 } }` with exit 0 — no warning the format was wrong. Trust auto-detect (the default); if forcing the format, verify `total_lines > 0` before reading anything else.

**Source**: `research/tldr/audit/coverage.md`
