# tldr specs

**Pitch**: Mines pytest-style test files for explicit behavioral specifications — `assert ==` pairs, `pytest.raises` blocks, `@parametrize` cases — and groups them by the function under test.

**Why reach for it**
- Inverts the test suite into an executable spec — each `IOSpec` is a concrete `(inputs, expected_output)` pair with a line anchor back to the test
- Self-contained: needs only `--from-tests`, no source file required (unlike `tldr invariants`)
- Three spec classes (`input_output`, `exception`, `property`) cover the bulk of pytest patterns in one pass
- Per-function aggregation means an agent can grab "everything the test suite says about `process_payment`" in one query

**When to use**
- Verifying a new implementation still satisfies the contract — dump all IOSpecs for the function and replay them mentally
- Documenting public behavior from existing tests instead of writing prose
- Auditing test quality: a function with zero specs is either untested or its tests are too imperative to read
- Comparing intended behavior (specs from tests) against inferred behavior (`tldr invariants`)

**When NOT to use**
- Code patterns (asserts, guards) inside the function body are the source of truth — use `tldr contracts`
- Numeric/range invariants from observed argument values — `tldr invariants`

**Output in plain words**: A `functions` array, one entry per function-under-test, each with `input_output_specs`, `exception_specs`, and `property_specs`. Summary reports `total_specs`, a `by_type` breakdown, and how many test files/functions were scanned.

**Killer detail**: `--from-tests` IS validated (exit 1 if missing), but `--source` is NOT — passing `--source /no/such/path` silently returns exit 0 with full output. Validate `--source` externally before trusting cross-reference results.

**Source**: `research/tldr/audit/specs.md`
