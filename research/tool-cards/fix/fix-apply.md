# tldr fix apply

**Pitch**: Takes a source file and an error text, tries the deterministic-fix registry, and either writes the patched source or emits a structured diagnosis for LLM hand-off.

**Why reach for it**
- For the small set of known-fixable patterns (TS2304 missing imports, simple Python typos with `--api-surface`, etc.) it produces the patched file with zero LLM cost
- When no deterministic fix exists, the JSON diagnosis (`error_code`, `message`, `location`, `confidence`) is the ideal LLM input — agents don't have to re-parse the raw traceback
- `--diff`, `-o <out>`, and `-i --in-place` cover the common write-back patterns
- Unified parser across Python tracebacks, Rust E0xxx, TS2xxx, gcc/clang, jest/mocha, eslint, ruff

**When to use**
- Compiler/test output names a well-known error and the agent wants the registry to try first before paying for an LLM
- Building an LLM-fix pipeline and needs structured diagnosis as input: `<runtime> 2>&1 | tldr fix apply -s <FILE> --stdin`
- Targeting TS2339 property errors with an `--api-surface api-surface.json` from `tldr api-check`

**When NOT to use**
- Just want the parsed diagnosis without attempting a fix — use `tldr fix diagnose` (exits 0 on Low confidence; apply exits 1)
- Need to loop test→fix→retest — use `tldr fix check`

**Output in plain words**: Default emits a JSON diagnosis `{ language, error_code, message, location?, confidence }`. When a deterministic fix exists, also prints the patched source (or unified diff with `-d`); when it doesn't, stderr says `"No auto-fix available... Escalate to a model."` and exit is 1.

**Killer detail**: Exit 1 is the COMMON case, not the failure case — the deterministic-fix registry is intentionally small, so most invocations return `confidence: Low` and `"Escalate to a model"` on stderr. Treat exit 1 + a populated JSON diagnosis as the happy path for LLM hand-off, not as an error to recover from.

**Other footguns**
- Stdin is read implicitly when neither `--error` nor `--error-file` is provided (even without `--stdin`) — `tldr fix apply -s buggy.py` in an interactive terminal HANGS waiting on stdin. Always pass `< /dev/null` or set `--error`/`--error-file` explicitly in scripts.
- `--api-surface <bad-path>` is SILENTLY IGNORED — no warning that the surface file is missing. Verify it exists externally before relying on TS2339-style suggestions.

**Source**: `research/tldr/fix/fix-apply.md`
