# Command: `tldr reaching-defs`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; reaching-defs itself is non-semantic, uses CFG+DFG engines) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr reaching-defs` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`reaching-defs.probes/probe.sh`](./reaching-defs.probes/probe.sh).

---

## Ground Truth (`tldr reaching-defs --help`)

```text
Analyze reaching definitions for a function

Usage: tldr reaching-defs [OPTIONS] <FILE> <FUNCTION>

Arguments:
  <FILE>
          Source file to analyze

  <FUNCTION>
          Function name to analyze

Options:
  -l, --lang <LANG>
          Programming language (auto-detected from file extension if not specified)

      --var <VAR>
          Filter output to specific variable

      --line <LINE>
          Show definitions reaching specific line

      --show-chains
          Show def-use chains (enabled by default)

      --show-uninitialized
          Flag potentially uninitialized uses (enabled by default)

      --show-in-out
          Show IN/OUT sets per block

      --chains-only
          Show only def-use/use-def chains, hide header, blocks, and statistics

      --params <PARAMS>
          Function parameters (comma-separated, for uninit detection)

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
| Typical output size | medium (~440 lines pretty JSON) to heavy (~3000 lines on larger functions) |

**Top-level keys (JSON, `ReachingDefsReport`):**
- `function` (`string`) — input function name verbatim
- `file` (`string`) — input file path verbatim
- `blocks` (`array<Block>`) — per-CFG-block info: `{ id, lines, gen, kill, in, out }`
- `def_use_chains` (`array<DefUseChain>`) — for each definition, list of use sites it reaches
- `use_def_chains` (`array<UseDefChain>`) — for each use, list of definitions that reach it
- `uninitialized` (`array<UninitializedUse>`) — uses with no reaching def
- `statistics` (`object`) — summary counts (definitions, uses, blocks, uninitialized)

**`Block` shape:** `{ id, lines, gen: [Def], kill: [Def], in: [Def], out: [Def] }`. **`in` and `out` ARE ALWAYS PRESENT in JSON output** regardless of the `--show-in-out` flag (see Crucial Rules).

**`DefUseChain` shape:** `{ definition: { var, line, column, block }, used_at: [{ var, line, column, block }] }`.

**Text format (P06):** `"Reaching Definitions for: <fn> in <file>"` header; `"Def-Use Chains:"`, `"Use-Def Chains:"`, `"Potentially Uninitialized:"` sections; `"Definitions: N / Uses: M / Blocks: B / Uninitialized: U"` footer.

**`-f compact` is NOT minified JSON.** Per `reaching_defs.rs:135-139`, both `Json` and `Compact` formats call `format_reaching_defs_json` (the pretty formatter). The dedicated `format_reaching_defs_json_compact` (`format.rs:75`, which uses `serde_json::to_string` for one-line minification) is exported but **NOT USED by the CLI**. P07 produces 439 lines — identical to P01.

**Error shapes (all stderr):**
- Missing FUNCTION: clap-style → exit **2**
- File not found: `"Error: File not found: /no/such/file.py"` → exit **1** (capital "F" — matches `tldr available`, differs from `tldr chop`/`tldr dead-stores` lowercase)
- Function not found: `"Error: Function not found: <name>"` → exit **20** (TldrError::FunctionNotFound — DIFFERENT from `tldr dead-stores` which exits 1 for the same condition)
- Format reject sarif/dot: standard not-supported errors → exit **1** (NOT the "fall back to JSON" hinted at by `reaching_defs.rs:140-151` — that code is unreachable because the global format validator runs first)
- `--show-chains=false` / `--show-uninitialized=false`: clap rejects `"error: unexpected value 'false' for '--show-chains' found; no more were expected"` → exit **2** (the flag is a non-toggleable boolean despite `default_value = "true"` — same gotcha as `tldr calls --respect-ignore`)
- Bad `--lang`: clap-style → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr reaching-defs yahoo.py _to_finite_float` | happy | 0 | [`01-happy.*`](./reaching-defs.probes/) |
| P02 | `tldr reaching-defs yahoo.py fetch_historical_data` | happy-scale | 0 | [`02-happy-scale.*`](./reaching-defs.probes/) |
| P03 | `tldr reaching-defs <file>` *(no FUNCTION)* | failure-missing-input | 2 | [`03-missing-arg.*`](./reaching-defs.probes/) |
| P04 | `tldr reaching-defs /no/such/file.py some_fn` | failure-badpath | 1 | [`04-badpath.*`](./reaching-defs.probes/) |
| P05 | `tldr reaching-defs ... -f sarif` | format-reject sarif (NOT fallback) | 1 | [`05-format-reject-sarif.*`](./reaching-defs.probes/) |
| P06 | `tldr reaching-defs ... -f text` | format-text | 0 | [`06-format-text.*`](./reaching-defs.probes/) |
| P07 | `tldr reaching-defs ... -f compact` | format-compact (NOT minified) | 0 | [`07-format-compact.*`](./reaching-defs.probes/) |
| P08 | `tldr reaching-defs ... -f dot` | format-reject dot (NOT fallback) | 1 | [`08-format-dot.*`](./reaching-defs.probes/) |
| P09 | `tldr reaching-defs ... --var df` | var-filter | 0 | [`09-var-filter.*`](./reaching-defs.probes/) |
| P10 | `tldr reaching-defs ... --line 60` | line-filter | 0 | [`10-line-filter.*`](./reaching-defs.probes/) |
| P11 | `tldr reaching-defs ... --show-in-out` | show-in-out (JSON-shape no-op) | 0 | [`11-show-in-out.*`](./reaching-defs.probes/) |
| P12 | `tldr reaching-defs ... --chains-only` | chains-only (JSON-shape no-op) | 0 | [`12-chains-only.*`](./reaching-defs.probes/) |
| P13 | `tldr reaching-defs ... --show-chains=false` | non-toggleable bool (clap reject) | 2 | [`13-show-chains-false.*`](./reaching-defs.probes/) |
| P14 | `tldr reaching-defs ... --show-uninitialized=false` | non-toggleable bool (clap reject) | 2 | [`14-show-uninit-false.*`](./reaching-defs.probes/) |
| P15 | `tldr reaching-defs ... --params 'self,...'` | params-hint | 0 | [`15-params.*`](./reaching-defs.probes/) |
| P16 | `tldr reaching-defs ... no_such_function` | function-not-found | 20 | [`16-function-not-found.*`](./reaching-defs.probes/) |
| P17 | `tldr reaching-defs ... -l brainfuck` | bad-lang | 2 | [`17-bad-lang.*`](./reaching-defs.probes/) |
| P18 | `tldr reaching-defs ... --var nonexistent_var` | var-filter-empty | 0 | [`18-var-not-found.*`](./reaching-defs.probes/) |
| P19 | `tldr reaching-defs ... --line 999999` | line-filter-empty | 0 | [`19-line-oor.*`](./reaching-defs.probes/) |
| P20 | `tldr reaching-defs ... -q` | quiet | 0 | [`20-quiet.*`](./reaching-defs.probes/) |
| P21 | `tldr reaching-defs README.md anything` | non-source-md (silent Python fallback) | 20 | [`21-non-source-md.*`](./reaching-defs.probes/) |

### Observations

- **P01** — `_to_finite_float` (8 CFG blocks): JSON has `blocks[]` with full GEN/KILL/IN/OUT sets, `def_use_chains` (2 entries), `use_def_chains` (6 entries), `uninitialized` (3 entries — `float`, `math`, `isfinite` flagged because the analyzer doesn't recognize them as Python builtins). Output ~440 lines.
- **P02** — `fetch_historical_data`: ~3000 lines pretty JSON. Same schema, more chains.
- **P03** — stderr `"error: the following required arguments were not provided: <FUNCTION>"`, exit `2`.
- **P04** — stderr `"Error: File not found: /no/such/file.py"`, exit `1`. **Capital "File"** — matches `tldr available`'s convention; differs from `tldr chop`/`tldr dead-stores` ("file not found:" lowercase) and `tldr calls` ("Path not found:").
- **P05** — stderr `"Error: --format sarif not supported by reaching-defs. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`. **Source-code drift:** `reaching_defs.rs:146-151` has a `OutputFormat::Sarif => /* fall back to JSON */` branch, but that branch is **unreachable** because the global `validate_format_for_command` (output.rs:113) rejects sarif before the run() method is invoked.
- **P06** — Text format renders human-readable chains and a footer summary `"Definitions: 2 / Uses: 6 / Blocks: 8 / Uninitialized: 3"`. Identifiers without reaching defs get `"(no reaching definition)"`. Progress message on stderr.
- **P07** — **`-f compact` produces pretty-printed JSON identical to default**, NOT minified. The CLI routes Compact through `format_reaching_defs_json` (the pretty formatter), ignoring the dedicated `format_reaching_defs_json_compact` helper. 439 lines, byte-identical to `-f json` per `diff` (verified).
- **P08** — stderr `"Error: --format dot not supported by reaching-defs. ..."`, exit `1`. Same source-code-drift: the DOT fallback branch is unreachable.
- **P09** — `--var df` on `fetch_historical_data`: filters to definitions/uses involving `df`. Output is reduced but still large because each chain is preserved in full.
- **P10** — `--line 60` filters to chains touching line 60. The filter keeps all `blocks[]` for context but trims `def_use_chains`/`use_def_chains`/`uninitialized` to relevant entries (per `filter_report_by_line` at `reaching_defs.rs:163`).
- **P11** — **`--show-in-out` is a TEXT-FORMAT-ONLY flag.** JSON output already includes `in` and `out` arrays per block. P01 and P11 differ only in trivial ordering of `gen` entries (likely HashMap iteration order). Confirmed via grep: both have 8 `"in":` keys and 8 `"out":` keys. **The flag has no effect on JSON output.** Source-comment drift from `--help`.
- **P12** — **`--chains-only` is a TEXT-FORMAT-ONLY flag.** JSON output retains all keys (`blocks`, `def_use_chains`, `use_def_chains`, etc.) regardless. The flag only suppresses sections in `format_reaching_defs_text_with_options`. Source confirmed at `format.rs:142, 1156-1163` (test confirms it hides blocks IN TEXT).
- **P13** — `--show-chains=false`: stderr `"error: unexpected value 'false' for '--show-chains' found; no more were expected"`, exit `2`. **The flag is declared as `bool` with `default_value = "true"`, which clap parses as a `SetTrue` flag (no value accepted).** Same gotcha as `tldr calls --respect-ignore=false`. **`--show-chains` is always-on; you CANNOT disable it via CLI.** Same applies to `--show-uninitialized` (P14).
- **P14** — Same shape as P13: `"error: unexpected value 'false' for '--show-uninitialized' found"`, exit `2`. Both "default-on toggles" are non-toggleable.
- **P15** — `--params 'self,symbol,start_date,end_date'`: declares which names are function parameters (suppressing "uninitialized" warnings for them). Used in `--show-uninitialized` heuristic. Output shape unchanged in this case because the function's parameters are already detected from the AST.
- **P16** — stderr `"Error: Function not found: no_such_function"`, exit `20`. Uses `TldrError::FunctionNotFound` → exit 20, matching `tldr impact`/`tldr explain`/`tldr context`. **Diverges from `tldr dead-stores` (exit 1 for the same error)** because that command uses `ContractsError`.
- **P17** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P18** — `--var nonexistent_var`: returns valid report with EMPTY chains (filtered to nothing), exit 0. **Silent empty result** — no error or hint. Verify with `def_use_chains.length === 0` to detect.
- **P19** — `--line 999999`: similar empty-filter result, exit 0. No range validation.
- **P20** — `-q` suppresses progress; stdout JSON unaffected.
- **P21** — Markdown file: stderr `"Error: Function not found: anything"`, exit `20`. Silent language fallback to Python; surfaces as function-not-found.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/reaching_defs.rs` (~200 lines)
- `crates/tldr-core/src/dfg/reaching.rs` (`build_reaching_defs_report`, `filter_reaching_defs_by_variable`)
- `crates/tldr-core/src/dfg/format.rs` (`format_reaching_defs_json`, `format_reaching_defs_text_with_options`, `ReachingDefsFormatOptions`)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/reaching_defs.rs:23-61
#[derive(Debug, Args)]
pub struct ReachingDefsArgs {
    pub file: PathBuf,
    pub function: String,
    #[arg(long, short = 'l')] pub lang: Option<Language>,
    #[arg(long)] pub var: Option<String>,
    #[arg(long)] pub line: Option<usize>,
    #[arg(long, default_value = "true")] pub show_chains: bool,
    #[arg(long, default_value = "true")] pub show_uninitialized: bool,
    #[arg(long)] pub show_in_out: bool,
    #[arg(long)] pub chains_only: bool,
    #[arg(long)] pub params: Option<String>,
}
```
Reveals: `show_chains` and `show_uninitialized` use `default_value = "true"` on `bool` — same anti-pattern as `tldr calls --respect-ignore` (non-toggleable boolean). The flags appear in `--help` as "(enabled by default)" but you CANNOT disable them.

**Unreachable format fallback branches (the P05/P08 source-comment drift):**
```rust
// reaching_defs.rs:140-151
OutputFormat::Dot => {
    // DOT not supported for reaching defs, fall back to JSON
    let json = format_reaching_defs_json(&report)
        .map_err(|e| anyhow::anyhow!("JSON serialization failed: {}", e))?;
    writer.write_text(&json)?;
}
OutputFormat::Sarif => {
    // SARIF not supported, fall back to JSON
    let json = format_reaching_defs_json(&report)
        .map_err(|e| anyhow::anyhow!("JSON serialization failed: {}", e))?;
    writer.write_text(&json)?;
}
```
Reveals: these branches claim to "fall back to JSON" but are **UNREACHABLE**. The global `validate_format_for_command` (output.rs:113) is called in main.rs BEFORE this command's run() is invoked, and it rejects sarif/dot with exit 1. So users see the rejection error, not the fallback. **Dead code with misleading comments.**

**Format-options only used in text path:**
```rust
// reaching_defs.rs:130-152
match format {
    OutputFormat::Text => {
        let text = format_reaching_defs_text_with_options(&report, &format_options);
        writer.write_text(&text)?;
    }
    OutputFormat::Json | OutputFormat::Compact => {
        let json = format_reaching_defs_json(&report)
            .map_err(|e| anyhow::anyhow!("JSON serialization failed: {}", e))?;
        writer.write_text(&json)?;
    }
    ...
}
```
Reveals: `format_options` (built from `--show-in-out`, `--chains-only`, `--show-chains`, `--show-uninitialized`) is passed only to `format_reaching_defs_text_with_options`. JSON and Compact both call `format_reaching_defs_json` (NO options arg). **All four `--show-*` flags are text-format-only no-ops in JSON mode.**

**Compact is NOT minified:**
The Json and Compact arms both invoke `format_reaching_defs_json` which uses `serde_json::to_string_pretty`. The dedicated minifying helper `format_reaching_defs_json_compact` (`format.rs:75`, returns one-line via `serde_json::to_string`) exists in core but is NEVER called from the CLI. **`-f compact` and `-f json` produce identical output.**

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `reaching-defs` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`. Sarif/dot are rejected globally.

**No daemon route:** `grep -n try_daemon_route reaching_defs.rs` returns 0 matches. Every call rebuilds CFG + DFG. `tldr warm` is a no-op.

---

## Architectural Deep Dive

- **Under the hood:** Three-stage analysis. (1) Build CFG via `get_cfg_context`. (2) Build DFG via `get_dfg_context` (yields variable refs). (3) Run forward dataflow: `IN[B] = ∪ OUT[pred(B)]`, `OUT[B] = (IN[B] − KILL[B]) ∪ GEN[B]`. Build def-use and use-def chains from the IN/OUT sets. Flag uses with no reaching def as "potentially uninitialized" (gated by `--params` heuristic).
- **Performance:** Cold per call (no daemon). ~100-300ms per function. CFG+DFG construction dominates.
- **LLM cognitive load:** Compiler-grade dataflow. Useful for: tracing variable origins (`--var X` shows all defs reaching uses of X), debugging "where did this value come from?", and finding potential null/uninit dereferences. Pairs with `tldr available` (expression-level) and `tldr dead-stores` (wasted defs).

---

## Intent & Routing

- **User/Agent Goal:** answer "for each use of variable X, which definitions could be the source?" — classic compiler dataflow.
- **When to choose this over similar tools:**
  - Over `tldr definition <symbol>`: `definition` is symbol-name based (project-wide); `reaching-defs` is intra-function variable-flow.
  - Over `tldr available`: `available` is expression-centric (CSE); `reaching-defs` is variable-centric (origin tracing).
  - Over `tldr dead-stores`: `dead-stores` finds wasted definitions; `reaching-defs` finds where defs go. Complementary.
- **Prerequisites (composition):**
  - Pre-discover function names with `tldr extract <file>`.
  - For Python parameter detection, pass `--params 'self,arg1,arg2'` to suppress false-positive "uninitialized" warnings.
  - For mixed-language projects, supply `-l <lang>` explicitly.

---

## Agent Synthesis

> **How to use `tldr reaching-defs`:**
> Classical dataflow analysis. `tldr reaching-defs <FILE> <FUNCTION>` returns JSON `{ function, file, blocks, def_use_chains, use_def_chains, uninitialized, statistics }`. Each `Block` has `gen`, `kill`, `in`, `out` arrays. Use `--var X` to filter to one variable; `--line N` to filter to chains touching line N; `--params 'a,b'` to declare parameters for uninit-detection. Default JSON pretty; `-f text` for human display; `-f compact` is IDENTICAL to `-f json` (NOT minified); sarif/dot rejected. Exit codes: 0 ok, 1 file-not-found / format-reject, 2 clap missing-arg / bad-lang / `--show-chains=false` / `--show-uninitialized=false`, 20 function-not-found (TldrError).
>
> **Crucial Rules:**
> - **`--show-chains=false` and `--show-uninitialized=false` are REJECTED by clap with exit 2.** Both flags use `default_value = "true"` on `bool`, which clap parses as `SetTrue` (no value accepted). **You CANNOT disable these defaults via CLI** (P13/P14). Same anti-pattern as `tldr calls --respect-ignore`. To suppress chains in text output, use `--chains-only` (which IS toggleable).
> - **`--show-in-out`, `--chains-only`, `--show-chains`, `--show-uninitialized` are ALL text-format-only no-ops in JSON mode.** JSON output always includes the full report (blocks with in/out, all chains, uninitialized). The flags only affect `format_reaching_defs_text_with_options`. Probe-confirmed via byte-identical JSON between P01/P11 (modulo trivial ordering).
> - **`-f compact` is NOT minified — identical to `-f json` pretty-print.** The CLI routes Compact through `format_reaching_defs_json` (pretty formatter) instead of the dedicated `format_reaching_defs_json_compact` (minifier). Workaround: pipe JSON through `jq -c .` for genuine one-line output.
> - **Unreachable dead code for sarif/dot fallback.** `reaching_defs.rs:140-151` claims to "fall back to JSON" for sarif/dot, but the global format validator in `output.rs:113` rejects these formats with exit 1 BEFORE this code runs. Source-comment drift; sarif/dot are properly rejected, NOT silently converted.
> - **Function-not-found returns exit 20 (TldrError::FunctionNotFound).** Matches `tldr impact`/`tldr explain`. **Diverges from `tldr dead-stores` (exit 1)** — that command lives in the contracts namespace with its own `ContractsError`. Cross-namespace inconsistency for the same semantic error.
> - **File-not-found uses "File not found:" with capital F.** Matches `tldr available`; differs from `tldr chop`/`tldr dead-stores` ("file not found:" lowercase) and `tldr calls`/`tldr importers` ("Path not found:"). Three conventions across CLI.
> - **`--var <nonexistent>` and `--line <out-of-range>` silently return empty filtered results** (P18, P19). No error or hint. Always verify `def_use_chains.length > 0` after filter operations.
> - **Markdown / unknown extensions silently fall back to Python parsing** (P21), then surface as `"Function not found"` exit 20.
> - **NO daemon route.** Every call rebuilds CFG + DFG. `tldr warm` is a no-op.
>
> **Command:** `tldr reaching-defs <FILE> <FUNCTION>`
>
> **With common flags:** `tldr reaching-defs <FILE> <FN> -l <lang> --var <X> --line <N> --params 'self,a,b' -f compact | jq -c .` (use --var + --line for targeted lookups; jq -c for true one-line output since -f compact is not actually minified).
