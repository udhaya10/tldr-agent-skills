# tldr available

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/deep/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Available-expressions dataflow — which expressions (e.g., `a + b`, `len(x)`) are already computed and still valid at every program point, with redundant-computation candidates surfaced for CSE.

**Why reach for it**
- Surfaces `redundant_computations` automatically — actionable Common Subexpression Elimination targets without manual scanning
- Modal queries (`--check <expr>`, `--at-line <N>`, `--killed-by <expr>`) answer focused questions without parsing the full block-by-block report
- Per-block `avail_in`/`avail_out`/`gen`/`kill` sets expose the underlying dataflow for advanced consumers
- Compiler-grade precision for typed languages where the AST extractor catches arithmetic, comparison, and call expressions

**When to use**
- Hunting CSE opportunities in performance-sensitive Rust/C/C++/Go/TypeScript code
- Confirming "is this exact expression already computed earlier?" — pass `--check`
- Investigating "what killed availability of expression E?" — pass `--killed-by`

**When NOT to use**
- Question is about variable origins, not expression availability — use `tldr reaching-defs`
- Working in Python — the AST extractor is conservative on dynamic-typed code; expect mostly empty results
- Need wasted-assignment detection — use `tldr dead-stores`

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```bash
tldr available <file> <function>                         # full per-block availability report
tldr available <file> <function> --check '<expr>'        # check if specific expression is available
tldr available <file> <function> --at-line <N>           # filter availability sets to one line
```

**Output in plain words**: A JSON report with per-block availability sets, the full expression list, a `redundant_computations` array of CSE candidates, or — under a modal flag — a slim envelope shape specific to the query.

**Killer detail**: `--cse-only` is a TEXT-FORMAT-ONLY flag despite what `--help` suggests — in JSON or compact mode it has ZERO effect, and default output is byte-identical to `--cse-only` output. The flag only suppresses the per-block section in `-f text`.

**Source**: `research/tldr/deep/available.md`
