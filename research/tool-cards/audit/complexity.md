# tldr complexity

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/audit/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Minimal single-function metric scorer that returns the four standard structural numbers — cyclomatic, cognitive, max_nesting, lines_of_code — for one named function, daemon-cached for sub-millisecond repeat calls.

**Why reach for it**
- Smallest, fastest, most focused complexity command in the suite — perfect for filling in `complexity` columns in audit reports
- Routes through the daemon: cold ~50ms, warm sub-millisecond, byte-identical results across cold and warm
- Cognitive score matches `tldr cognitive` exactly (same canonical `tldr_core::calculate_complexity` engine) — safe to use either
- Cleanest CLI surface in the audit suite: two positionals (FILE, FUNCTION), `-l`, `-f`, `-q`, nothing else

**When to use**
- Already know the function name and want its four metrics in one cheap call
- Building a CI workflow that scores a fixed set of functions on every commit (the daemon cache makes this near-free)
- Need a deterministic, scriptable JSON for downstream tooling — `tldr complexity ... -f compact | jq .cognitive`

**When NOT to use**
- Don't know which functions are interesting yet — use `tldr cognitive <DIR> --include-cyclomatic` to rank ALL functions in one call (don't loop `tldr complexity` in shell)
- Want the per-line contributor breakdown that explains WHY the score is high — only `tldr cognitive --show-contributors` provides that

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```
tldr complexity [OPTIONS] <FILE> <FUNCTION>
```
```
tldr complexity backend/providers/yahoo.py _to_finite_float           # both FILE and FUNCTION required
tldr complexity backend/providers/yahoo.py fetch_historical_data      # another function in same file
tldr complexity backend/providers/yahoo.py _to_finite_float -f text   # text output format
```

**Output in plain words**: A 5-field JSON record (`function, cyclomatic, cognitive, max_nesting, lines_of_code`). No `file` field in the output, so multi-function aggregation requires external bookkeeping — `tldr cognitive` is the right tool for that case.

**Killer detail**: `-l typescript` on a `.py` file does NOT report a language mismatch — the TypeScript parser walks Python source, fails to locate the function, and the command exits 20 with a misleading `"Function not found: <name>"`. When the language might be ambiguous, pass `-l` to the file's actual language first.

**Source**: `research/tldr/audit/complexity.md`
