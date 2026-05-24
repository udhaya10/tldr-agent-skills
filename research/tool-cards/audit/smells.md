# tldr smells

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/audit/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: AST-based code-smell detector that names the anti-pattern (god class, long method, deep nesting, etc.) with file, line, severity, and optional refactor suggestion.

**Why reach for it**
- One pass covers 10 default detectors plus 8 more under `--deep` — no need to assemble a lint pipeline
- `severity` (1-3) per finding gives a built-in prioritization signal for top-N triage
- `--suggest` adds a refactor hint per smell, ready to feed to an LLM with the source location
- `--smell-type <X>` and `-t strict|default|relaxed` thresholds turn it into a focused single-rule check or a broad audit

**When to use**
- Need to find concrete anti-patterns (god class, feature envy, data clumps) with line numbers, not just metric scores
- Building a refactor backlog and want ranked candidates with reason strings
- Running a pre-commit / code-review check for one specific smell on changed files
- Want one tool that aggregates cohesion + coupling + dead-code + clone signals (use `--deep`)

**When NOT to use**
- Want the unwritten *conventions* the code follows rather than its anti-patterns — that's `tldr patterns`
- Need a single monetizable "how much debt" number — `tldr debt` rolls smells into SQALE minutes

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```
tldr smells [OPTIONS] [PATH]
```
```
tldr smells backend/providers                              # scan directory (PATH defaults to .)
tldr smells backend/providers --deep -s low-cohesion      # low-cohesion requires --deep
tldr smells backend/providers --suggest                   # include fix suggestions
```

**Output in plain words**: A `smells[]` array of findings (each with `smell_type` in snake_case, absolute `file` path, `name`, `line`, `reason`, `severity`), plus `by_file` counts keyed by absolute path, a `summary` rollup, and a `warnings[]` advisory nudging toward `--deep` when applicable.

**Killer detail**: Passing `--smell-type` for one of the 8 deep-only smells (`low-cohesion`, `tight-coupling`, `dead-code`, `code-clone`, `high-cognitive-complexity`, `middle-man`, `refused-bequest`, `inappropriate-intimacy`) WITHOUT `--deep` returns silent empty results with no warning — the gating advisory is suppressed once `--smell-type` is set.

**Source**: `research/tldr/audit/smells.md`
