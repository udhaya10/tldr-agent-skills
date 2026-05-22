# Command: `tldr available`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; available itself is non-semantic, uses CFG+DFG engines) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr available` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`available.probes/probe.sh`](./available.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/deep/available.md).

---

## Ground Truth (`tldr available --help`)

```text
Analyze available expressions for CSE detection

Usage: tldr available [OPTIONS] <FILE> <FUNCTION>

Arguments:
  <FILE>
          Source file to analyze

  <FUNCTION>
          Function name to analyze

Options:
  -l, --lang <LANG>
          Programming language (auto-detected from file extension if not specified)

      --check <CHECK>
          Check if a specific expression is available (e.g., "a + b")

      --at-line <AT_LINE>
          Show expressions available at a specific line number

      --killed-by <KILLED_BY>
          Show what kills a specific expression

      --cse-only
          Show only CSE opportunities, skip per-block details

  -f, --format <FORMAT>
          Output format

          Supported by every command: json, text, compact.

          Command-specific formats (rejected at runtime by other commands): sarif  — only: vuln, clones dot    — only: calls, impact, hubs, inheritance, clones, deps

          cli-error-clarity-v2 (P2.BUG-5): possible values are hidden on the global help to avoid promising sarif/dot for every subcommand. Run `tldr <cmd> --help` to confirm what a specific command emits, and see `validate_format_for_command` in `output.rs` for the source of truth.

          [default: json]

  -q, --quiet
          Suppress progress output

  -v, --verbose
          Enable verbose/debug output

  -h, --help
          Print help (see a summary with '-h')
```

---

## Output Shape

| Aspect | Value |
|---|---|
| Default format | `json` |
| Formats that work | `json`, `text`, `compact` (P01, P06, P07) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| Typical output size | small (<1 KB for simple functions) to medium (~10 KB for multi-block functions) |

**Top-level keys (JSON, `AvailableExprsInfo`):**
- `avail_in` (`object<block_id, array<Expression>>`) — expressions available at block ENTRY, keyed by integer block id
- `avail_out` (`object<block_id, array<Expression>>`) — expressions available at block EXIT
- `gen_per_block`, `kill_per_block` (`object<block_id, array>`) — per-block gen/kill sets used in the dataflow equations
- `block_lines` (`object<block_id, array<line>>`) — line ranges per CFG block
- `expressions` (`array<Expression>`) — all unique expressions extracted from the function
- `redundant_computations` (`array<[text, first_line, redundant_line]>`) — CSE candidates (when present)

**`Expression` shape:** `{ text: string, gen_line: u32, kind: string, confidence: string }` — text is the source expression literal; kind = `"arithmetic"` / `"comparison"` / `"function_call"`; confidence = `"High"` / `"Medium"` / `"Low"`.

**`--check <expr>` modal shape (P09):**
```json
{ "expression": "<query>", "available_in_blocks": [0, 3, 5], "is_redundant": true }
```

**`--at-line <N>` modal shape (P10):**
```json
{ "line": 21, "available_expressions": [{ Expression, ... }] }
```

**`--killed-by <expr>` modal shape (P11):**
```json
{ "expression": "<query>", "killed_by_redefinition_of": ["var1", "var2"] }
```

**Empty modal results** (e.g., P16 check-missing, P17 at-line-out-of-range): same shape but with empty arrays. Exit 0 — modal queries do NOT error on missing data.

**Error shapes:**
- Missing FUNCTION arg: clap-style `"error: the following required arguments were not provided: <FUNCTION> …"` → exit **2**
- File not found: `"Error: File not found: /no/such/file.py"` → exit **1** (anyhow!; capitalized "File" — different message than other commands)
- Function not found (engine): `"Error: Function not found: <name>"` → exit **20** (TldrError::FunctionNotFound)
- Format reject: `"Error: --format sarif not supported by available. Use --format json. SARIF is only emitted by: vuln, clones."` → exit **1**
- Bad `--lang`: clap-style → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr available backend/providers/yahoo.py _to_finite_float` | happy | 0 | [`01-happy.*`](./available.probes/) |
| P02 | `tldr available backend/providers/yahoo.py fetch_historical_data` | happy-scale | 0 | [`02-happy-scale.*`](./available.probes/) |
| P03 | `tldr available <file>` *(no FUNCTION)* | failure-missing-input | 2 | [`03-missing-arg.*`](./available.probes/) |
| P04 | `tldr available /no/such/file.py some_fn` | failure-badpath | 1 | [`04-badpath.*`](./available.probes/) |
| P05 | `tldr available ... -f sarif` | format-reject | 1 | [`05-format-reject-sarif.*`](./available.probes/) |
| P06 | `tldr available ... -f text` | format-text | 0 | [`06-format-text.*`](./available.probes/) |
| P07 | `tldr available ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./available.probes/) |
| P08 | `tldr available ... -f dot` | format-reject-dot | 1 | [`08-format-reject-dot.*`](./available.probes/) |
| P09 | `tldr available ... --check 'float(value)'` | modal-check | 0 | [`09-check.*`](./available.probes/) |
| P10 | `tldr available ... --at-line 21` | modal-at-line | 0 | [`10-at-line.*`](./available.probes/) |
| P11 | `tldr available ... --killed-by 'value'` | modal-killed-by | 0 | [`11-killed-by.*`](./available.probes/) |
| P12 | `tldr available ... --cse-only` | cse-only (JSON, no-op) | 0 | [`12-cse-only.*`](./available.probes/) |
| P13 | `tldr available ... no_such_function` | function-not-found | 20 | [`13-function-not-found.*`](./available.probes/) |
| P14 | `tldr available ... -l brainfuck` | bad-lang | 2 | [`14-bad-lang.*`](./available.probes/) |
| P15 | `tldr available README.md anything` | non-source-md (silent python fallback) | 20 | [`15-non-source-md.*`](./available.probes/) |
| P16 | `tldr available ... --check 'totally_made_up'` | check-missing (empty result) | 0 | [`16-check-missing.*`](./available.probes/) |
| P17 | `tldr available ... --at-line 999999` | at-line-out-of-range (empty result) | 0 | [`17-at-line-oor.*`](./available.probes/) |
| P18 | `tldr available ... -q` | quiet | 0 | [`18-quiet.*`](./available.probes/) |

### Observations

- **P01** — `_to_finite_float` (simple Python function with `float(value)` and `math.isfinite()` calls): 8 CFG blocks, all with empty `avail_in` arrays — Python's dynamic typing means the AST extractor doesn't catch function-call expressions as available for CSE. `redundant_computations` is empty. Output 77 lines pretty-printed.
- **P02** — `fetch_historical_data` (larger function with df operations): 313 lines stdout; more blocks, more entries in gen/kill sets, but still no redundant_computations detected — Python CSE on dataframe ops is hard.
- **P03** — stderr `"error: the following required arguments were not provided: <FUNCTION>"`, exit `2`. Both FILE and FUNCTION are required positionals.
- **P04** — stderr `"Error: File not found: /no/such/file.py"`, exit `1`. Uses `anyhow!` with capitalized "File" (cf. `tldr calls`/`tldr dead` say "Path not found:..." with capital P — close convention but different word). Cross-command divergence.
- **P05** — stderr `"Error: --format sarif not supported by available. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format renders a minimal report: `"Available Expressions Analysis: <fn> in <file>"` header, `"No redundant computations detected."`, then `"Available expressions by block:"` section. Progress message on stderr.
- **P07** — Single-line minified JSON, same schema as P01.
- **P08** — stderr `"Error: --format dot not supported by available. Use --format json. DOT is only emitted by: clones, deps, calls, impact, hubs, inheritance."`, exit `1`.
- **P09** — `--check 'float(value)'` returns 5-line modal shape: `{ expression, available_in_blocks: [], is_redundant: false }`. `available_in_blocks: []` because the expression wasn't found in any block's avail_in set — likely because the AST extractor on Python function-call expressions doesn't index `float(value)` as an available expression. **Verbatim text matching:** the query must match `Expression.text` exactly, including whitespace.
- **P10** — `--at-line 21` returns 4-line modal shape: `{ line: 21, available_expressions: [] }`. Empty because no expressions are available at that specific line.
- **P11** — `--killed-by 'value'` returns 4-line modal: `{ expression: 'value', killed_by_redefinition_of: [] }`. Empty because no variables are redefined that would kill this expression.
- **P12** — **`--cse-only` is a TEXT-FORMAT-ONLY flag.** JSON output is byte-identical to P01 (verified via `diff`). The flag is only consulted in `format_text_output` (`available.rs:284`) to suppress the "Available expressions by block:" section. With JSON/compact, `--cse-only` has **zero effect**.
- **P13** — stderr `"Error: Function not found: no_such_function"`, exit `20` (TldrError::FunctionNotFound). Matches the standard impact/explain convention.
- **P14** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P15** — **Silent language-fallback:** `tldr available README.md anything` exits with `"Error: Function not found: anything"`, exit `20`. The `Language::from_path(README.md).unwrap_or(Language::Python)` falls back to Python (`available.rs:71-72`), then the engine fails to find `anything` in the markdown. **No "unsupported language" error** — the .md file is silently parsed as Python, and only the function-not-found error surfaces. **Recovery hint:** pass `-l <real_lang>` or use a source file with an unambiguous extension.
- **P16** — `--check 'totally_made_up'`: same shape as P09 with `available_in_blocks: []` and `is_redundant: false`. **Indistinguishable from "expression exists but isn't available anywhere"** (P09). Agents cannot tell "wrong query" from "valid query, no matches" from the response alone.
- **P17** — `--at-line 999999`: same shape as P10 with empty `available_expressions: []`. No range validation — out-of-range line numbers silently produce empty results.
- **P18** — `-q` suppresses the "Analyzing available expressions..." progress message; stdout JSON unaffected.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/available.rs` (412 lines)
- `crates/tldr-core/src/dataflow/available.rs` (`compute_available_exprs_with_source_and_lang`)
- `crates/tldr-core/src/cfg.rs` (`get_cfg_context`), `crates/tldr-core/src/dfg.rs` (`get_dfg_context`)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/available.rs:33-60
#[derive(Debug, Args)]
pub struct AvailableArgs {
    pub file: PathBuf,
    pub function: String,
    #[arg(long, short = 'l')] pub lang: Option<Language>,
    #[arg(long)] pub check: Option<String>,
    #[arg(long)] pub at_line: Option<usize>,
    #[arg(long)] pub killed_by: Option<String>,
    #[arg(long)] pub cse_only: bool,
}
```
Reveals: both positionals required (clap exit 2). Three modal flags (`--check`, `--at-line`, `--killed-by`) are mutually exclusive in practice — the first one set wins via the if-let chain at `available.rs:112-123`.

**Path validation:**
```rust
// available.rs:81-83
if !self.file.exists() {
    return Err(anyhow::anyhow!("File not found: {}", self.file.display()));
}
```
Reveals: capitalized "File not found:..." — slightly different from `tldr calls`/`tldr dead`'s "Path not found:..." even though both use anyhow!. Cross-command message inconsistency.

**Silent language fallback (P15 root cause):**
```rust
// available.rs:70-72
let language = self
    .lang
    .unwrap_or_else(|| Language::from_path(&self.file).unwrap_or(Language::Python));
```
Reveals: `.md` files (where `Language::from_path` returns None) silently get Python. No UnsupportedLanguage error.

**Modal dispatch:**
```rust
// available.rs:112-123
if let Some(ref expr) = self.check {
    return self.handle_check_query(&result, expr, &writer);
}
if let Some(line) = self.at_line {
    return self.handle_at_line_query(&result, line, &writer);
}
if let Some(ref expr) = self.killed_by {
    return self.handle_killed_by_query(&result, expr, &writer);
}
// Default: full result
```
Reveals: order is `--check` → `--at-line` → `--killed-by` → default. If a user passes multiple modal flags, only the first one (check) runs. Other flags are silently ignored.

**`--cse-only` is text-only (P12 root cause):**
```rust
// available.rs:283-301
// Show available expressions per block (unless --cse-only)
if !self.cse_only {
    output.push_str("Available expressions by block:\n");
    ...
}
```
Reveals: the only consumer of `self.cse_only` is `format_text_output`. JSON output emits the full `avail_in`/`avail_out` maps regardless of the flag. **Source-comment drift:** `--help` says "Show only CSE opportunities, skip per-block details" — true only for text format.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `available` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

---

## Architectural Deep Dive

- **Under the hood:** Three-stage pipeline. (1) Build CFG via `get_cfg_context`. (2) Build DFG via `get_dfg_context`. (3) Run forward dataflow equations: `avail_in[B] = ⋂ avail_out[pred(B)]`, `avail_out[B] = (avail_in[B] − kill[B]) ∪ gen[B]`. Expressions are AST-extracted from source via `compute_available_exprs_with_source_and_lang`. Python's AST extractor captures arithmetic and comparison expressions but is conservative about function calls (P09: `float(value)` not detected).
- **Performance:** Cold per call (no daemon). On a small function ~50ms; on a large function ~200ms. The CFG+DFG construction dominates.
- **LLM cognitive load:** Useful for compiler-grade redundancy analysis — finding expressions computed twice in the same flow. For dynamic languages like Python the signal is weak because of side-effect concerns; for Rust/C/Go this is much more useful.

---

## Intent & Routing

- **User/Agent Goal:** identify Common Subexpression Elimination (CSE) opportunities — expressions computed multiple times that could be cached. Useful for performance refactoring.
- **When to choose this over similar tools:**
  - Over `tldr slice`: `slice` answers "what affects this line?" (dataflow); `available` answers "what expressions are available here and could be reused?" Different dataflow questions.
  - Over `tldr reaching-defs`: `reaching-defs` tracks variable definitions; `available` tracks expression availability. Reaching-defs is variable-centric; available is expression-centric.
  - Over manual CSE inspection: surfaces `redundant_computations` automatically, which is the actionable CSE signal.
- **Prerequisites (composition):**
  - FUNCTION must exist in FILE — pass `tldr extract <file>` first to enumerate function names.
  - For `--check`, the query expression must match `Expression.text` **verbatim** (including whitespace). No fuzzy match.
  - For dynamic languages, expect weak signal — Python returns mostly empty results (P01, P09).

---

## Agent Synthesis

> **How to use `tldr available`:**
> CFG+DFG-based available-expressions analysis for CSE detection. `tldr available <FILE> <FUNCTION>` returns JSON `{ avail_in, avail_out, gen_per_block, kill_per_block, block_lines, expressions, redundant_computations }`. Modal queries via `--check <expr>` / `--at-line <N>` / `--killed-by <expr>` return slim envelope shapes specific to each query. Default format is JSON; `-f text` produces a human summary; `-f compact` is single-line JSON; `sarif`/`dot` are rejected. Exit codes: 0 ok (including empty modal results), 1 file-not-found / format-reject, 2 missing-arg / bad-lang, 20 function-not-found (TldrError::FunctionNotFound).
>
> **Crucial Rules:**
> - **`--cse-only` is a TEXT-FORMAT-ONLY flag.** Has zero effect on JSON output — P01 (default) and P12 (`--cse-only`) are byte-identical in JSON mode. Only in text format does it suppress the "Available expressions by block:" section (`available.rs:283-301`). `--help` claim "skip per-block details" applies to text format only.
> - **Modal flags are mutually exclusive: order `--check` → `--at-line` → `--killed-by`.** If multiple are set, only `--check` runs (`available.rs:112-123`). Pass at most one modal flag per invocation.
> - **`--check` and `--killed-by` require VERBATIM string match against `Expression.text`.** No fuzzy/regex match. `--check 'float(value)'` and `--check 'totally_made_up'` BOTH return empty `available_in_blocks: []` (P09 vs P16) — indistinguishable. Agents cannot tell "wrong query" from "valid query, no matches" by the response alone. To explore valid queries, first run without modal flags and inspect the `expressions` array.
> - **Markdown/unknown extensions silently fall back to Python parsing.** `Language::from_path(README.md)` returns None → `unwrap_or(Language::Python)` → engine runs Python tree-sitter on markdown, then yields "Function not found" (exit 20) — NOT "Unsupported language" (P15). Pass `-l <real_lang>` to avoid the silent fallback.
> - **`--at-line N` has no range validation.** Out-of-range line numbers return empty `available_expressions: []` (P17). No error; agents must compare line N to the function's actual line range (visible in `block_lines`).
> - **Python dataflow signal is weak.** Most function calls are NOT extracted as available expressions (P01: `_to_finite_float` has empty `avail_in` for every block). Python's dynamic typing makes CSE inference conservative. Use this command primarily for typed languages (Rust, C/C++, Go, TypeScript) where the AST extractor catches more.
> - **File-not-found uses "File not found:" (capital F);** other commands use "Path not found:" — cross-command message inconsistency for the same error class. Match on the path-not-found substring, not the prefix.
> - **NO daemon route.** Every call rebuilds the CFG + DFG. `tldr warm` is a no-op for this command.
>
> **Command:** `tldr available <FILE> <FUNCTION>`
>
> **With common flags:** `tldr available <FILE> <FUNCTION> -f text --cse-only` (use to surface only the actionable CSE candidates without block-level noise — text format with `--cse-only` is the clean human-readable view).
