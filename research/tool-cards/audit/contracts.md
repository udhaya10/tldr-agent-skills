# tldr contracts

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/audit/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Pulls implicit pre/post-conditions out of a single function — type hints, isinstance checks, assert statements, raise guards — and tags each with a confidence level.

**Why reach for it**
- Surfaces the contract a function ALREADY enforces without reading the body line by line
- Confidence buckets let the agent filter out noise (type-annotation-only conditions are flagged "low")
- Returns the AST line number for each condition — direct anchor for follow-up edits
- Best error message in the audit suite when language is ambiguous (states the file AND the fix)

**When to use**
- About to refactor a function and want to know what invariants its callers depend on
- Generating API documentation or negative test cases from existing code
- Comparing a function's static contract (this tool) against its tested behavior (`tldr invariants`) to find drift
- Auditing whether a public function actually validates its inputs

**When NOT to use**
- Need loop or class-level invariants project-wide — that's `tldr invariants`, not function pre/post
- Want behavioral specs from the test suite — `tldr specs` extracts assert-based input/output pairs

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```
tldr contracts [OPTIONS] <FILE> <FUNCTION>
```
```
tldr contracts backend/providers/yahoo.py _to_finite_float            # both FILE and FUNCTION required
tldr contracts backend/providers/yahoo.py fetch_historical_data       # another function in same file
tldr contracts backend/providers/yahoo.py fetch_historical_data --limit 1
```

**Output in plain words**: A JSON record with `preconditions`, `postconditions`, and `invariants` arrays. Each condition carries the variable name (`"return"` for the return value), a human-readable constraint string, the source line, and a confidence string (`"low"`, `"medium"`, `"high"`).

**Killer detail**: `--limit 0` returns LITERAL ZERO conditions, not unlimited — opposite of `tldr cognitive --top 0` and `tldr dead --max-items 0` in the same suite. Pass `--limit 9999` (or just leave the default 100) when "all" is what's wanted.

**Source**: `research/tldr/audit/contracts.md`
