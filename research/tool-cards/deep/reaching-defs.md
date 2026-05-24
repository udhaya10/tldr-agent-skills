# tldr reaching-defs

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/deep/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Classical reaching-definitions dataflow — for every USE of a variable, the set of DEFs that could be its source, plus per-block GEN/KILL/IN/OUT and a list of potentially uninitialized uses.

**Why reach for it**
- Answers "where did this value come from?" across every variable in a function, in one call
- Returns both def-use AND use-def chains — no need to invert manually
- `--var X` and `--line N` filter the report to a single variable or a single line site
- Flags uninitialized uses up front; pass `--params 'self,a,b'` to silence false positives on parameters

**When to use**
- Tracing the origin of a variable value to its possible definitions
- Auditing a function for potentially uninitialized reads
- Investigating control-flow merges (phi-like join points) where multiple defs can reach the same use
- Building targeted lookups — filter with `--var` plus `--line` for surgical queries

**When NOT to use**
- Question is about expressions (e.g., is `a + b` already computed?) — use `tldr available` (expression-centric, not variable-centric)
- Question is "which assignments are wasted?" — use `tldr dead-stores` (the inverse question)

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```bash
tldr reaching-defs <file> <function>                        # full def-use/use-def chains
tldr reaching-defs <file> <function> --var <name>           # filter to one variable
tldr reaching-defs <file> <function> --params 'a,b,c'       # suppress false positives on params
```

**Output in plain words**: A typed report with per-block `gen`/`kill`/`in`/`out` arrays, `def_use_chains` and `use_def_chains` linking definitions to use sites, an `uninitialized` list, and a `statistics` summary.

**Killer detail**: `-f compact` is wired to the pretty formatter — it produces output IDENTICAL to `-f json`, not minified. Pipe through `jq -c .` for actual one-line output.

**Other footguns**
- `--show-chains=false` and `--show-uninitialized=false` are REJECTED by clap (exit 2) — both flags are declared as `default_value = "true"` on `bool`, which clap treats as a SetTrue flag with no value accepted. The flags are always-on and cannot be disabled.
- All four `--show-*` knobs (`--show-in-out`, `--chains-only`, `--show-chains`, `--show-uninitialized`) are text-format-only no-ops. JSON output always includes the full report regardless.
- Function-not-found returns exit 20 here but exit 1 from `tldr dead-stores` (different Rust error namespace for the same semantic error) — cross-command exit-code drift.

**Source**: `research/tldr/deep/reaching-defs.md`
