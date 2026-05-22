# Lens: Audit coverage & testing — family chooser

**The question this lens answers**: "I want to know what this code is actually specified or covered by — which of `coverage`, `contracts`, `invariants`, `verify`, `specs` should I run?"

**Toolset**: `tldr coverage`, `tldr contracts`, `tldr invariants`, `tldr verify`, `tldr specs`

**Why a family-chooser lens, why these tools**: These five look adjacent ("things about tests and constraints") but they read from **five genuinely different data sources** — not five views of the same thing. The discriminator is **where does the signal come from**: an external coverage report, the function body's own asserts/types, observed test data, the test suite's `assert ==` pairs, or an aggregate over multiple of those. Picking wrong returns data that doesn't answer the question (and in some cases silently returns zero).

## Decision tree

| You have / want... | Data source | Reach for |
|--------------------|-------------|-----------|
| An existing Cobertura / LCOV / coverage.py report and want which lines are uncovered | External test-execution report file | `tldr coverage` |
| One function, want its IMPLIED pre/post/invariants from the body itself | CODE patterns (type hints, isinstance, asserts, raises) | `tldr contracts` |
| A test suite that runs, want what the tests EMPIRICALLY prove about a function's argument ranges/relations | Observed test argument & return VALUES (Daikon-lite) | `tldr invariants` |
| A pytest test file, want explicit `(inputs, expected_output)` pairs grouped by function-under-test | Pytest test SOURCE (`assert ==`, `pytest.raises`, `@parametrize`) | `tldr specs` |
| A single "how much of this code is specified at all?" headline across `contracts`+`specs`(+`invariants`+`patterns`) | Aggregate of the above sub-analyzers | `tldr verify` |

## The default

**`tldr verify <path>` for the "is this codebase specified?" headline question — the most common framing.** It runs `contracts` + `specs` (and optionally `invariants` + `patterns`) under one call, returns a single `coverage_pct` metric, and the per-sub-analyzer `status` field tells the agent which dimension is weakest (lowest `items_found` is where to invest). Drop into the specific sibling when verify points you somewhere: `tldr contracts` for a single-function refactor safety net, `tldr specs` to dump everything the tests say about one function, `tldr invariants` to compare empirical behavior against the stated contract, and `tldr coverage` for the entirely-separate "line-coverage from CI reports" axis.

## Common mistakes

- **Reading `tldr verify`'s `coverage_pct` as project-wide coverage.** It is the percentage of CONSTRAINT-RELEVANT functions (a subset of all project functions) that have any spec/contract attached — `coverage.scope` literally says so in the output. For true project-wide coverage, divide the constraint counts by `tldr structure`'s `total_functions`.
- **Treating `tldr coverage` and `tldr verify` as overlapping.** They don't overlap at all. `coverage` parses an external CI artifact and reports line %. `verify` reads source code patterns and reports constraint %. A project can be 100% line-covered with 0% constraints, or vice versa.
- **Passing `tldr verify --detail contracts` and expecting filtered output.** `--detail` is SILENTLY IGNORED — every value (and omitting the flag) produces byte-identical JSON. Skip the flag.
- **Forcing `tldr coverage -R cobertura` on an LCOV file.** Returns `{ format: "cobertura", summary: { line_coverage: 0.0, total_lines: 0 } }` with exit 0 — no warning that the format guess was wrong. Trust auto-detect; if forcing, verify `total_lines > 0` before reading anything else.
- **Passing `tldr contracts --limit 0` expecting "unlimited".** It returns LITERAL ZERO conditions — opposite of `tldr cognitive --top 0` and `tldr dead --max-items 0` in the same suite. Pass `--limit 9999` for "all," or leave the default 100.
- **Calling `tldr specs --source /no/such/path` and trusting the cross-references.** `--from-tests` is validated (exit 1 if missing), `--source` is NOT — bogus paths silently return exit 0 with full output. Validate `--source` externally before trusting any cross-reference fields.
- **Mapping `tldr invariants`'s `arg0`/`arg1` back to source parameter names from the invariants output alone.** Variables are NAMED POSITIONALLY, never by the source parameter name. Use `tldr extract` on the source file to get the real names, then zip.
- **Running `tldr verify` on a non-Python directory without `-l`.** Silent Python fallback: README.md, language-mismatched dirs, and empty dirs all return the same 40-line empty result. Pass `-l <lang>` explicitly for non-Python work.

## What this lens captures

- The five-data-sources framing is durable: once internalized, the picker is just "where does my signal live."
- The verify-as-aggregator default keeps the common case (one headline number) cheap; sub-tools are escalations, not duplicates.

## What this lens misses

- **Whether the tests actually pass.** None of these five runs the suite. `tldr coverage` reads a report someone else produced; the others read code or test source.
- **Security-specific constraint coverage.** `tldr secure` is the security-focused aggregator, parallel in shape to `verify` but for vulnerabilities — covered in the security family.
- **Generic code-quality metrics.** Complexity, dead code, hotspots — those are `tldr health` territory and other audit families.

## Pair with

- `audit-security-family-chooser.md` — `verify` is the constraint-coverage sibling of `secure` (constraints vs security findings); same shape, different signal
- `audit-api-design-family-chooser.md` — `patterns` (which `verify` can include as a sub-analyzer) is also the conventions-extractor in the API family

## Sources

- `research/tool-cards/audit/coverage.md`
- `research/tool-cards/audit/contracts.md`
- `research/tool-cards/audit/invariants.md`
- `research/tool-cards/audit/verify.md`
- `research/tool-cards/audit/specs.md`
