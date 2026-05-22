---
name: tldr-trace-data-flow
description: Trace data flow at the variable, line, or expression level INSIDE a single function — answer "what affects this value", "where does this variable come from", "what's on the dependency path between line A and line B", "which assignments are never read", or "is this expression already computed". Reach for this whenever the question is about VALUES, LINES, or DEFINITIONS rather than function-to-function call relationships. Triggers on "trace the data flow", "find unused assignments", "dead store", "common subexpression", "what depends on this line", "reaching definitions", "available expressions", "backward slice", "forward slice", "dependency path between".
allowed-tools: [Bash]
compatibility: "Requires tldr-code CLI v0.4.0+. Tested on darwin and linux."
metadata:
  version: "1.0.0"
  author: "udhaya10"
  repository: "udhaya10/tldr-agent-skills"
  tldr.cli-version: "0.4.0"
  tldr.research-commit: "a025973"
  tldr.commands-wrapped: "slice, chop, reaching-defs, available, dead-stores"
---

# tldr-trace-data-flow

## When to use

Use this skill whenever the question is about **values inside one function** — which lines mathematically influence a result, which definitions could be the source of a variable's value, which expressions are already computed, which assignments are wasted. These are compiler-grade dataflow questions: precise, intra-function, and grounded in a CFG/PDG/SSA engine.

The discriminator vs sibling skills:

- For **call-graph questions** ("who calls `foo`", "what does `foo` depend on at the function level") → see `tldr-trace-relationships`. That skill is function-relationship granularity; this skill is value/line/expression granularity.
- For **function-level inspection** ("what does this function do", signature + purity + complexity) before deciding whether to go variable-level → see `tldr-understand-function`.
- For **actual bug repair** after dataflow analysis identifies the corrupted line → see `tldr-fix-and-detect`.
- For **security taint** ("does untrusted input reach a sink") → see `tldr-audit-security`. Taint uses a different engine; chop is the wrong tool.

The escalation rule: start with trace-relationships when the question is "what calls what." Cross into this skill only when the question collapses to a single function and becomes "why does THIS line produce THAT value" or "where did variable X get its value at line N." The signal you should have escalated: you've spent five trace calls chasing a caller tree, and the bug is actually an assignment inside one function clobbering a value. Trace will never find that; the tools in this skill will, immediately.

## The decision — which tool to use

The discriminator is **the shape of the question**: how many criterion points you have, whether you care about variables or expressions, and whether you're asking "where did this come from?" or "is this ever read?".

| You're asking... | About... | Anchor points | Reach for |
|------------------|----------|---------------|-----------|
| "What lines (transitively) affect / are affected by this one?" | Lines | 1 criterion line | `tldr slice` |
| "What lines lie on the dependency path from A to B?" | Lines | 2 criterion lines | `tldr chop` |
| "For this USE of variable X, which DEFs could be its source?" | Variables | 1 function (optionally filter by var/line) | `tldr reaching-defs` |
| "Which expressions are already computed and still valid here?" | Expressions | 1 function (optionally `--check`/`--at-line`) | `tldr available` |
| "Which assignments are written but never read?" | Variables | 1 function | `tldr dead-stores` |

**Default: `tldr slice` first** for the generic "what depends on this line?" question. It is the only deep-group command with a daemon cache (repeat queries are fast), and the direction knob (`-d backward|forward`) covers both "where did this value come from?" and "if I edit here, what breaks?". Escalate from there:

- Have **two endpoints** instead of one → `tldr chop` (intersection of forward and backward slices)
- Question is **about a variable's origin**, not a line → `tldr reaching-defs`
- Question is **about expressions** (CSE, redundancy) → `tldr available`
- Question is **"are any assignments wasted?"** → `tldr dead-stores`

**Naive-reader confusion pairs** (always disambiguate before reaching):

- **slice vs chop** — one criterion line is a slice; two criterion lines is a chop. Running slice twice and intersecting by hand is what chop already does in one call.
- **available vs reaching-defs** — both look like "where did this come from?" but answer different questions. If the question names a **variable** (`x`, `result`, `self.cache`), use reaching-defs. If the question names an **expression** (`a + b`, `len(items)`, `obj.method()`), use available.

## Tool reference

### `tldr slice` — PDG-based program slice from one line

PDG-based program slice from a single line — the exact set of lines that mathematically affect (backward) or are affected by (forward) the criterion.

**Why reach for it**:
- Replaces "read the whole 200-line function and trace by hand" with a compiler-grade dependency answer
- The only deep-group command with a daemon cache — repeat queries are fast
- Out-of-range criterion lines return an `explanation` field that includes the real function bounds, so the agent self-corrects without re-querying metadata
- Direction knob (`-d backward|forward`) covers both "where did this value come from?" and "if I change this, what breaks?"

**When to use**:
- Debugging a corrupt value and want the minimal backward set of contributing lines
- Planning a single-line edit and want every downstream line it could touch (forward)
- Tracing one variable through a multi-variable function — pass `--variable <name>`
- Have ONE criterion line; if there are two endpoints, use `tldr chop` instead

**Usage**:
```bash
tldr slice -F <file> -F <function> -L <line> [-d backward|forward] [--variable <name>]
```

**Output**: A list of line numbers in the slice plus a `slice_lines` array with code, definitions, and uses per line; `edges` carries data/control dependency links when the direct-compute path runs.

**Killer detail**: When the criterion line is outside the function, exit code is 0 — parse the `explanation` string, which embeds the actual bounds (e.g., `"line 9999 is outside function 'get_db_connection' (lines 48-53)"`) and retry inside that range.

---

### `tldr chop` — two-point program chop between A and B

Two-point program chop — the intersection of `forward_slice(source_line)` and `backward_slice(target_line)`, giving every line on the dependency path from A to B.

**Why reach for it**:
- Answers "what's actually between this read and that write?" with the precise compiler-grade line set
- One call replaces re-running `slice` twice and computing the intersection by hand
- Echoes the user-supplied file path verbatim (no `/private/tmp` canonicalization surprise) — round-trip-safe in agent pipelines
- Same-line query is a recognized special case, not an error

**When to use**:
- Have TWO specific lines in the same function and want the minimal set worth inspecting
- Planning a localized refactor and want to know which intermediate statements are on the data-flow path
- Investigating "did this assignment really reach that branch?" between two known points

**Usage**:
```bash
tldr chop -F <file> -F <function> --source-line <A> --target-line <B>
```

**Output**: A small JSON record with `lines` (the chop), `path_exists`, `source_line`, `target_line`, the input function name, and an `explanation` string that always carries either a success summary or the failure reason.

**Killer detail**: Exit code is 0 on every failure mode (function-not-found, line out of range, no PDG anchor, unknown language) — the real success signal is `path_exists: true`, and despite the name it does NOT check file existence; it means "chop was computed." **Always branch on `path_exists` and read `explanation`, never on exit code.**

**Other footguns**:
- A line WITHIN the function's byte range can still produce `path_exists: false` because docstrings, braces, and multi-line statement continuations have no PDG node — pick a neighbouring statement line. Use `tldr slice` or `tldr extract` first to find PDG-anchored lines.
- Reversed direction (source > target) works silently and returns valid output but the explanation may not reflect the input order — pass `min(source,target)` and `max(source,target)` conventionally.

---

### `tldr reaching-defs` — classical reaching-definitions dataflow

Classical reaching-definitions dataflow — for every USE of a variable, the set of DEFs that could be its source, plus per-block GEN/KILL/IN/OUT and a list of potentially uninitialized uses.

**Why reach for it**:
- Answers "where did this value come from?" across every variable in a function, in one call
- Returns both def-use AND use-def chains — no need to invert manually
- `--var X` and `--line N` filter the report to a single variable or a single line site
- Flags uninitialized uses up front; pass `--params 'self,a,b'` to silence false positives on parameters

**When to use**:
- Tracing the origin of a variable value to its possible definitions
- Auditing a function for potentially uninitialized reads
- Investigating control-flow merges (phi-like join points) where multiple defs can reach the same use
- Building targeted lookups — filter with `--var` plus `--line` for surgical queries

**Usage**:
```bash
tldr reaching-defs -F <file> -F <function> [--var <name>] [--line <N>] [--params 'self,a,b']
```

**Output**: A typed report with per-block `gen`/`kill`/`in`/`out` arrays, `def_use_chains` and `use_def_chains` linking definitions to use sites, an `uninitialized` list, and a `statistics` summary.

**Killer detail**: `-f compact` is wired to the pretty formatter — it produces output IDENTICAL to `-f json`, not minified. Pipe through `jq -c .` for actual one-line output.

**Other footguns**:
- `--show-chains=false` and `--show-uninitialized=false` are REJECTED by clap (exit 2) — both flags are declared as `default_value = "true"` on `bool`, which clap treats as a SetTrue flag with no value accepted. The flags are always-on and cannot be disabled.
- All four `--show-*` knobs (`--show-in-out`, `--chains-only`, `--show-chains`, `--show-uninitialized`) are text-format-only no-ops. JSON output always includes the full report regardless.
- Function-not-found returns exit 20 here but exit 1 from `tldr dead-stores` — cross-command exit-code drift.

---

### `tldr available` — available-expressions dataflow (CSE candidates)

Available-expressions dataflow — which expressions (e.g., `a + b`, `len(x)`) are already computed and still valid at every program point, with redundant-computation candidates surfaced for CSE.

**Why reach for it**:
- Surfaces `redundant_computations` automatically — actionable Common Subexpression Elimination targets without manual scanning
- Modal queries (`--check <expr>`, `--at-line <N>`, `--killed-by <expr>`) answer focused questions without parsing the full block-by-block report
- Per-block `avail_in`/`avail_out`/`gen`/`kill` sets expose the underlying dataflow for advanced consumers
- Compiler-grade precision for typed languages where the AST extractor catches arithmetic, comparison, and call expressions

**When to use**:
- Hunting CSE opportunities in performance-sensitive Rust/C/C++/Go/TypeScript code
- Confirming "is this exact expression already computed earlier?" — pass `--check`
- Investigating "what killed availability of expression E?" — pass `--killed-by`

**Usage**:
```bash
tldr available -F <file> -F <function> [--check <expr>] [--at-line <N>] [--killed-by <expr>]
```

**Output**: A JSON report with per-block availability sets, the full expression list, a `redundant_computations` array of CSE candidates, or — under a modal flag — a slim envelope shape specific to the query.

**Killer detail**: `--cse-only` is a TEXT-FORMAT-ONLY flag despite what `--help` suggests — in JSON or compact mode it has ZERO effect, and default output is byte-identical to `--cse-only` output. The flag only suppresses the per-block section in `-f text`.

**Python caveat**: The AST extractor is conservative on dynamic-typed code; expect mostly empty `redundant_computations` lists. The tool shines on Rust / C / C++ / Go / TypeScript.

---

### `tldr dead-stores` — SSA-based dead-store detector

SSA-based dead-store detector — assignments to variables whose values are never subsequently read, scoped to a single function.

**Why reach for it**:
- Compiler-grade detection catches control-flow-merge cases that grep misses (phi-node stores flagged via `is_phi`)
- `--compare` runs both SSA and live-variables analyses in one call — intersect the two for high-confidence findings
- Each finding carries `variable`, `ssa_name`, `line`, `block_id` — directly addressable for surgical refactors
- Default SSA-only output is conservative; opt into live-vars only when investigating

**When to use**:
- Refactoring a function and want every wasted assignment in one pass
- Catching typos like `result = compute()` followed by `return reseult`
- Auditing debug leftovers and unused intermediate values
- Cross-validating findings — pass `--compare` and treat the intersection of `dead_stores_ssa` and `dead_stores_live_vars` as actionable

**Usage**:
```bash
tldr dead-stores -F <file> -F <function> [--compare]
```

**Output**: A report with `dead_stores_ssa` (always populated) and `dead_stores_live_vars` (only when `--compare` is set, otherwise null), each entry naming the variable, its SSA-renamed form, line, and CFG block.

**Killer detail**: Function-not-found returns exit 1 here, NOT exit 20 — this command lives in the contracts namespace with its own `ContractsError` enum, breaking the convention used by every other deep-group command. Scripts cannot rely on the exit-20-means-function-not-found pattern when wrapping dead-stores.

## Common mistakes

- **Reaching for this skill when the question crosses function boundaries.** All five tools are intra-function. "Who calls `process_order`?" is `tldr-trace-relationships` territory, not slice. If the question requires traversing call edges, escalate back up to that skill first — use it to land on a specific function, then drop into this skill on that function.
- **Reaching for `tldr slice` when there are two endpoints.** Running slice twice and intersecting by hand is what `chop` already does in one call; the result is identical and you avoid an arithmetic error.
- **Confusing `available` with `reaching-defs`.** They look similar but answer different questions: `reaching-defs` is variable-centric ("which defs of `x` reach here?"), `available` is expression-centric ("is `a + b` already computed?"). If the question names a variable, use reaching-defs; if it names an expression, use available.
- **Treating a `chop` exit code as a success signal.** Exit code is 0 on every failure mode (function-not-found, line out of range, no PDG anchor). Branch on `path_exists` and read `explanation` — not on exit code. The same applies to `slice` on out-of-range lines: read `explanation`, not `$?`.
- **Picking a `chop` or `slice` line inside a docstring, brace, or multi-line continuation.** Those lines have no PDG node — `path_exists` will be false (chop) or `slice_lines` empty (slice) even when the line is "in" the function. Use `tldr extract` or a quick `tldr slice` first to find PDG-anchored lines.
- **Trusting `tldr available` on Python.** The AST extractor is conservative on dynamic-typed code; expect mostly empty `redundant_computations`. Available shines on Rust / C / C++ / Go / TypeScript.
- **Trying to disable `--show-chains` or `--show-uninitialized` on `reaching-defs`.** Both are clap-rejected (exit 2) because of a `default_value = "true"` quirk. Both flags are always on; JSON output always carries the full report regardless.
- **Assuming consistent exit codes across deep-group commands.** `dead-stores` returns exit 1 on function-not-found while the other four return exit 20 (it lives in a different Rust error namespace). Cross-command scripting cannot rely on `exit 20 == not found`.
- **Using `dead-stores` to find unused FUNCTIONS.** This tool is store-level inside one function. For unused functions, that's `tldr-trace-relationships` (the `dead` command), not here.
- **Using `chop` as a taint-flow check.** "Does untrusted input reach a sink?" looks like a chop but the right engine is taint analysis — see `tldr-audit-security`.

## See also

- `tldr-trace-relationships` — when the question is about function-to-function call relationships (callers, references, blast radius), not values inside one function. Land there first, then drop into this skill once the investigation collapses onto a single function.
- `tldr-understand-function` — when the question is "what does this function do" (signature, purity, complexity, both call directions) before deciding whether to escalate to variable-level analysis.
- `tldr-fix-and-detect` — once dataflow analysis pinpoints a corrupted line or wasted assignment, this is the skill that turns the diagnosis into a deterministic repair.
- `tldr-audit-security` — for taint/security flows ("does untrusted input reach a sink"). A chop-shaped question with a different engine; do not approximate with this skill's tools.
