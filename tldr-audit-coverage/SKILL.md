---
name: tldr-audit-coverage
description: Assess test coverage and specification quality — answer "is this code actually tested or specified?" Reach for this whenever the question is about constraint coverage, contract extraction, behavioral specs, observed invariants, or line-coverage reports — NOT about smells or bugs. Triggers on "test coverage", "is this code tested", "what's not covered", "extract contracts", "find invariants", "test specifications", "verify constraints", "specification coverage", "formal contracts", "what does the test suite prove", "uncovered lines", "pre/post conditions".
allowed-tools: [Bash]
---

# tldr-audit-coverage

## When to use

Use this skill whenever the question is **"is this code adequately tested or specified?"** — coverage gaps, extracted contracts, behavioral specs from tests, empirically observed invariants, or aggregate specification health. The intent is **assessment of specification adequacy**, not bug-hunting or code-smell triage.

The discriminator vs sibling skills:

- For "what to FIX" (smells, debt, hotspots, churn) → see `tldr-audit-smells`
- For "what's BROKEN" (bug detection, repair patches, diagnostics) → see `tldr-fix-and-detect`
- For "is this SECURE" (vulnerabilities, taint, secure-aggregator) → see `tldr-audit-security`
- For "is this code COMPLEX" (cognitive, cyclomatic, halstead, LOC) → see `tldr-audit-complexity`

These five tools look adjacent ("things about tests and constraints") but they read from **five genuinely different data sources** — not five views of the same thing. Picking wrong returns data that doesn't answer the question (and in some cases silently returns zero).

## The decision — which tool to use

The discriminator is **where the signal lives**.

| You have / want... | Data source | Reach for |
|--------------------|-------------|-----------|
| One headline "how much of this code is specified at all?" across contracts+specs(+invariants+patterns) | Aggregate of the sub-analyzers | `tldr verify` |
| An existing Cobertura / LCOV / coverage.py report and want which lines are uncovered | External test-execution report file | `tldr coverage` |
| One function, want its IMPLIED pre/post/invariants from the body itself | CODE patterns (type hints, isinstance, asserts, raises) | `tldr contracts` |
| A pytest test file, want explicit `(inputs, expected_output)` pairs grouped by function-under-test | Pytest test SOURCE (`assert ==`, `pytest.raises`, `@parametrize`) | `tldr specs` |
| A test suite that runs, want what tests EMPIRICALLY prove about a function's argument ranges/relations | Observed test argument & return VALUES (Daikon-lite) | `tldr invariants` |

**Default: `tldr verify <path>` for the "is this codebase specified?" headline question** — it runs `contracts` + `specs` (and optionally `invariants` + `patterns`) under one call, returns a single `coverage_pct` metric, and the per-sub-analyzer `status` field tells you which dimension is weakest (lowest `items_found` is where to invest). Drop into a specific sibling when verify points you somewhere: `contracts` for a single-function refactor safety net, `specs` to dump everything tests say about one function, `invariants` to compare empirical behavior against the stated contract, and `coverage` for the entirely-separate "line-coverage from CI reports" axis.

## Tool reference

### `tldr verify` — constraint-coverage dashboard (meta-aggregator)

Runs `contracts`, `specs`, and optionally `invariants` + `patterns` over a path and reports what percentage of constraint-relevant functions are actually specified.

**Why reach for it**:
- One command instead of orchestrating four sub-analyzers and aggregating their output
- Returns a single `coverage_pct` metric for "how much of this code is specified" — agent-friendly headline
- `--quick` mode skips the expensive invariants/patterns sub-analyses (5–10x faster)
- `partial_results: true` flag plus per-sub-analyzer `status` lets you distinguish real bugs from expected failures (e.g., `specs` failing because no `tests/` dir exists)

**When to use**:
- Auditing a codebase for specification gaps before a refactor
- CI signal of "is constraint coverage trending up or down" over time
- Picking a target area: the sub-analyzer with lowest `items_found` is where contract work is needed
- Replacing a hand-rolled `contracts + specs + invariants` pipeline

**Usage**:
```bash
tldr verify <path> [-l <lang>] [--quick] [--include-invariants] [--include-patterns]
```

**Output**: A JSON dashboard with a keyed `sub_results` object (`contracts`, `specs`, optionally `invariants` and `patterns`), a `summary` block with total spec/contract/invariant counts plus a `coverage` sub-object, and timing/file counts.

**Killer detail**: `coverage_pct` is a percentage of CONSTRAINT-RELEVANT functions (a subset of all project functions), not of every function in the repo — the `coverage.scope` field literally says so. **For project-wide coverage, divide constraint counts by `tldr structure`'s `total_functions`** instead.

**Other footguns**:
- `--detail <X>` is SILENTLY IGNORED — `--detail contracts`, `--detail wat`, or omitting it all produce byte-identical JSON. Skip the flag
- Silent Python fallback on non-Python projects: README.md, language-mismatched dirs, and empty dirs all return the same 40-line empty result. Pass `-l <lang>` explicitly for non-Python work

---

### `tldr coverage` — multi-format coverage report parser

Turns Cobertura XML, LCOV, or coverage.py JSON into a uniform summary plus optional per-file breakdown.

**Why reach for it**:
- One command absorbs all three common coverage formats; the JSON shape is normalized so downstream tools don't branch on format
- Threshold check, sort, and `--uncovered-only` filter are built in — no `jq` gymnastics for CI gating
- `--by-file --uncovered` emits the actual uncovered line numbers, which is what an LLM needs to propose new tests
- Best-in-class parse-error message in the audit suite (states cause AND fix)

**When to use**:
- CI just produced a coverage report and you need to know which files are below threshold
- Planning where to write tests: combine `--uncovered-only --uncovered` to get the file:line pairs lacking coverage
- Comparing coverage across runs without writing a custom parser
- The user provided an unknown coverage XML/LCOV file and the format needs auto-detecting

**Usage**:
```bash
tldr coverage <report-file> [-R cobertura|lcov|coveragepy] [--by-file] [--uncovered] [--uncovered-only] [--threshold <pct>]
```

**Output**: A summary block with line/branch/function percentages and a `threshold_met` boolean, plus (with `--by-file`) per-file entries each carrying uncovered lines and function names. Schema fields vary by format — LCOV gives branch + function rates, Cobertura and coverage.py give line coverage only.

**Killer detail**: Forcing `-R cobertura` on an LCOV file (or vice versa) silently returns `{ format: "cobertura", summary: { line_coverage: 0.0, total_lines: 0 } }` with exit 0 — no warning the format was wrong. **Trust auto-detect** (the default); if forcing the format, verify `total_lines > 0` before reading anything else.

---

### `tldr contracts` — extract pre/post/invariants from a function body

Pulls implicit pre/post-conditions out of a single function — type hints, isinstance checks, assert statements, raise guards — and tags each with a confidence level.

**Why reach for it**:
- Surfaces the contract a function ALREADY enforces without reading the body line by line
- Confidence buckets let you filter out noise (type-annotation-only conditions are flagged "low")
- Returns the AST line number for each condition — direct anchor for follow-up edits
- Best error message in the audit suite when language is ambiguous (states file AND fix)

**When to use**:
- About to refactor a function and want to know what invariants its callers depend on
- Generating API documentation or negative test cases from existing code
- Comparing a function's static contract (this tool) against its tested behavior (`tldr invariants`) to find drift
- Auditing whether a public function actually validates its inputs

**Usage**:
```bash
tldr contracts <file> [--function <name>] [--limit <N>] [--min-confidence low|medium|high]
```

**Output**: A JSON record with `preconditions`, `postconditions`, and `invariants` arrays. Each condition carries the variable name (`"return"` for the return value), a human-readable constraint string, the source line, and a confidence string (`"low"`, `"medium"`, `"high"`).

**Killer detail**: `--limit 0` returns LITERAL ZERO conditions, not unlimited — opposite of `tldr cognitive --top 0` and `tldr dead --max-items 0` in the same suite. **Pass `--limit 9999`** (or just leave the default 100) when "all" is what's wanted.

---

### `tldr specs` — extract behavioral specs from pytest tests

Mines pytest-style test files for explicit behavioral specifications — `assert ==` pairs, `pytest.raises` blocks, `@parametrize` cases — and groups them by the function under test.

**Why reach for it**:
- Inverts the test suite into an executable spec — each `IOSpec` is a concrete `(inputs, expected_output)` pair with a line anchor back to the test
- Self-contained: needs only `--from-tests`, no source file required (unlike `tldr invariants`)
- Three spec classes (`input_output`, `exception`, `property`) cover the bulk of pytest patterns in one pass
- Per-function aggregation means you can grab "everything the test suite says about `process_payment`" in one query

**When to use**:
- Verifying a new implementation still satisfies the contract — dump all IOSpecs and replay them mentally
- Documenting public behavior from existing tests instead of writing prose
- Auditing test quality: a function with zero specs is either untested or its tests are too imperative to read
- Comparing intended behavior (specs from tests) against inferred behavior (`tldr invariants`)

**Usage**:
```bash
tldr specs --from-tests <test-dir-or-file> [--source <src-file>] [--function <name>]
```

**Output**: A `functions` array, one entry per function-under-test, each with `input_output_specs`, `exception_specs`, and `property_specs`. Summary reports `total_specs`, a `by_type` breakdown, and how many test files/functions were scanned.

**Killer detail**: `--from-tests` IS validated (exit 1 if missing), but `--source` is NOT — passing `--source /no/such/path` silently returns exit 0 with full output. **Validate `--source` externally** before trusting cross-reference fields.

---

### `tldr invariants` — Daikon-lite inferencer from observed test data

Watches argument and return values across a test suite and emits the type/range/relation invariants those tests actually establish.

**Why reach for it**:
- Surfaces what the test suite EMPIRICALLY proves about a function — independent of the code's stated contract
- Cross-argument `relation` invariants (e.g., `arg1 < arg2`) catch coupling that single-variable analyses miss
- Confidence is observation-count driven, so high-confidence invariants are well-supported by data
- Pairs cleanly with `tldr contracts` to triangulate: code-stated contract vs test-observed behavior — divergence flags gaps

**When to use**:
- Refactoring a function and need a behavioral safety net beyond what asserts encode
- Auditing whether tests actually exercise meaningful constraints (or just cover lines)
- Reverse-engineering an API by feeding its test suite and extracting the implicit numeric/type contract
- Deciding which inputs are worth fuzzing — anything outside the inferred `range` is unexplored

**Usage**:
```bash
tldr invariants --from-tests <test-dir> --source <src-file> [--function <name>]
```

**Output**: Per-function blocks listing preconditions and postconditions as `Invariant` records with positional variable names (`arg0`, `arg1`, ..., `result`), an `expression` string, `kind` (`type`, `range`, `relation`, etc.), and an observation count. Summary reports total observations and how many test files/functions were scanned.

**Killer detail**: Variables are NAMED POSITIONALLY — `arg0`, `arg1`, never by the source parameter name. **Mapping `arg0` back to `value` (or whatever the signature calls it) requires inspecting the source separately**, usually via `tldr extract`.

## Common mistakes

- **Treating `tldr coverage` and `tldr verify` as overlapping.** They don't overlap at all. `coverage` parses an external CI artifact and reports line %. `verify` reads source-code patterns and reports constraint %. A project can be 100% line-covered with 0% constraints, or vice versa — they're orthogonal axes.
- **Reading `tldr verify`'s `coverage_pct` as project-wide coverage.** It is the percentage of CONSTRAINT-RELEVANT functions (a subset of all project functions) that have any spec/contract attached — `coverage.scope` literally says so in the output. For true project-wide coverage, divide the constraint counts by `tldr structure`'s `total_functions`.
- **Passing `tldr verify --detail contracts` and expecting filtered output.** `--detail` is SILENTLY IGNORED — every value (and omitting the flag) produces byte-identical JSON. Skip the flag.
- **Forcing `tldr coverage -R cobertura` on an LCOV file.** Returns `{ format: "cobertura", summary: { line_coverage: 0.0, total_lines: 0 } }` with exit 0 — no warning. Trust auto-detect; if forcing, verify `total_lines > 0` before reading anything else.
- **Passing `tldr contracts --limit 0` expecting "unlimited".** It returns LITERAL ZERO conditions — opposite of `tldr cognitive --top 0` and `tldr dead --max-items 0` in the same suite. Pass `--limit 9999` for "all," or leave the default 100.
- **Calling `tldr specs --source /no/such/path` and trusting the cross-references.** `--from-tests` is validated (exit 1 if missing), `--source` is NOT — bogus paths silently return exit 0 with full output. Validate `--source` externally before trusting any cross-reference fields.
- **Mapping `tldr invariants`'s `arg0`/`arg1` back to source parameter names from the invariants output alone.** Variables are NAMED POSITIONALLY, never by the source parameter name. Use `tldr extract` on the source file to get the real names, then zip.
- **Running `tldr verify` on a non-Python directory without `-l`.** Silent Python fallback: README.md, language-mismatched dirs, and empty dirs all return the same 40-line empty result. Pass `-l <lang>` explicitly for non-Python work.
- **Reaching for this skill when the real question is "what's broken" or "what should I fix".** Coverage/contracts/specs measure adequacy of specification, not presence of bugs or smells. Hop to `tldr-fix-and-detect` (bugs) or `tldr-audit-smells` (debt/refactor priorities) instead.

## See also

- `tldr-audit-smells` — when the question is "what to fix" (smells, debt, hotspots, churn) rather than "what's adequately tested"
- `tldr-fix-and-detect` — when the question is "what's broken" (bug detection, repair patches) rather than "what's specified"
- `tldr-audit-security` — when the headline question is vulnerabilities; `tldr secure` is the security-focused aggregator that parallels `verify`'s shape
- `tldr-audit-api` — when the focus is API design conventions and patterns; `tldr patterns` (which `verify` can include as a sub-analyzer) is also the conventions-extractor there
- `tldr-understand-function` — for extracting source line ranges (via `tldr extract`) needed to map `tldr invariants` positional `argN` back to real parameter names
