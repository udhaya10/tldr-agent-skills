# tldr temporal

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/audit/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Mines method-call sequences across a codebase and reports which methods are typically called before which — the implicit lifecycle protocol the code follows.

**Why reach for it**
- FP-Growth-style sequence mining surfaces "A before B" patterns no per-file analysis can find
- Each constraint comes with `support`, `confidence`, and concrete `examples: [{file, line}]` — actionable, not abstract
- `--include-trigrams` extends to 3-method sequences for fuller protocol shapes (e.g., `connect → query → close`)
- Catches lifecycle protocols other audit tools miss: builder patterns, init/teardown ordering, acquire/release pairs

**When to use**
- Reverse-engineering an API's expected call order (e.g., "how do callers usually use this library?")
- Looking for resource lifecycle bugs at the project level (pair with `tldr resources` for the per-file CFG view)
- Auditing whether a new code path follows the same `before → after` pattern as existing call sites
- Inferring builder/fluent-API protocols by querying a specific method's typical predecessors

**When NOT to use**
- Need the call graph (who-calls-whom) rather than call ordering — that's `tldr calls`
- Per-file resource leak detection — `tldr resources` does CFG-based leak analysis

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```
tldr temporal [OPTIONS] <PATH>
```
```
tldr temporal backend/providers                   # PATH required (no default)
tldr temporal backend/providers --source-lang auto   # default is "python" — pass auto for other languages
tldr temporal backend/providers --query fetch_historical_data
```

**Output in plain words**: A `constraints` array of bigrams (each with `before`, `after`, `support`, `confidence`, examples), an optional `trigrams` array for 3-method sequences, and metadata reporting `files_analyzed` and `sequences_extracted`.

**Killer detail**: `--source-lang` defaults to a hardcoded `"python"` (not auto-detect) — the ONLY tldr command with a non-auto language default. Non-Python repos get silent empty results unless `--source-lang <lang>` or `--source-lang auto` is passed.

**Other footguns**
- `-f compact` returns PRETTY JSON, not single-line (same quirk as `tldr taint` and `tldr resources`). Pipe through `jq -c` if compact is actually needed.
- `--query <method>` is EXACT MATCH against qualified `before`/`after` names, not substring search. Use `jq '.constraints[] | select(.before | contains("X"))'` for fuzzy lookups.

**Source**: `research/tldr/audit/temporal.md`
