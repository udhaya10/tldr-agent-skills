# Command: `tldr references`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; references itself is non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr references` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`references.probes/probe.sh`](./references.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/trace/references.md).

---

## Ground Truth (`tldr references --help`)

```text
Find all references to a symbol

Usage: tldr references [OPTIONS] <SYMBOL> [PATH]

Arguments:
  <SYMBOL>
          Symbol to find references for

  [PATH]
          Path to search in (directory)

          [default: .]

Options:
      --include-definition
          Include definition location in results

  -t, --kinds <KINDS>
          Filter by reference kinds (comma-separated: call,read,write,import,type)

  -s, --scope <SCOPE>
          Search scope: local, file, workspace

          [default: workspace]

  -n, --limit <LIMIT>
          Maximum number of results to return

          [default: 20]

  -C, --context-lines <CONTEXT_LINES>
          Number of context lines before and after (not implemented yet)

          [default: 0]

      --min-confidence <MIN_CONFIDENCE>
          Minimum confidence threshold (0.0-1.0). References below this are filtered out

          [default: 0.0]

  -f, --format <FORMAT>
          Output format

          Supported by every command: json, text, compact.

          Command-specific formats (rejected at runtime by other commands): sarif  — only: vuln, clones dot    — only: calls, impact, hubs, inheritance, clones, deps

          cli-error-clarity-v2 (P2.BUG-5): possible values are hidden on the global help to avoid promising sarif/dot for every subcommand. Run `tldr <cmd> --help` to confirm what a specific command emits, and see `validate_format_for_command` in `output.rs` for the source of truth.

          [default: json]

  -l, --lang <LANG>
          Programming language (auto-detect if not specified)

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
| Typical output size | small (~1 KB no-results) to medium (~10 KB for 20 references with context) |

**Top-level keys (JSON, `ReferencesReport`):**
- `symbol` (`string`) — query symbol name (verbatim)
- `definition` (`Definition` | omitted) — primary/canonical definition (first found, or first matched)
- `definitions` (`array<Definition>`) — ALL matching definition sites (a symbol may exist in multiple files — see P01 finding 3 definitions of `_to_finite_float`)
- `references` (`array<Reference>`) — found references, truncated to `--limit`
- `total_references` (`usize`) — count BEFORE truncation
- `shown_references` (`usize`) — count of returned `references` array
- `truncated` (`bool`) — always emitted (per N5/N12 schema-cleanup pattern)
- `search_scope` (`string`) — the ACTUAL scope used (`"local"`, `"file"`, `"workspace"`) — **may differ from `--scope` input due to engine optimization** (P01)
- `stats` (`object`) — `{ files_searched, candidates_found, verified_references, search_time_ms }`

**`Definition` shape:** `{ file, line, column, kind, signature }` where `kind` is `"function"`, `"class"`, `"variable"`, `"type"`, etc.

**`Reference` shape:** `{ file, line, column, kind, context, confidence, end_column }` where:
- `kind` is one of `"call"`, `"read"`, `"write"`, `"import"`, `"type"`, `"definition"` (definitions appear in references when `--include-definition` is set OR is always included per implementation)
- `context` is a single line (despite `--context-lines N` flag, **multi-line context is "not implemented yet"** per `--help`)
- `confidence` is `0.0–1.0`; AST-verified refs are typically 1.0

**Empty-result shape (P21):**
```json
{
  "symbol": "no_such_symbol_anywhere",
  "definitions": [],
  "references": [],
  "total_references": 0,
  "shown_references": 0,
  "truncated": false,
  "search_scope": "workspace",
  "stats": { "files_searched": 56, "candidates_found": 0, "verified_references": 0, "search_time_ms": ... }
}
```
Exit 0. Note **NO `definition` field** (only the empty `definitions` array). Plus a helpful stderr message: `"No references found for 'X'. Searched N files. Suggestions: - Check the symbol spelling - ..."`.

**Error shapes:**
- Missing SYMBOL: clap-style `"error: the following required arguments were not provided: <SYMBOL> …"` → exit **2**
- Path not found: `"Error: Path not found: '/no/such/dir'. Please provide a valid file or directory."` → exit **1** (S7-R56 includes the tried path AND a suggestion)
- Format reject: `"Error: --format sarif not supported by references. Use --format json. SARIF is only emitted by: vuln, clones."` → exit **1**
- Bad `--lang`: clap-style → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr references _to_finite_float backend -l python` | happy | 0 | [`01-happy.*`](./references.probes/) |
| P02 | `tldr references Provider backend -l python` | happy-scale | 0 | [`02-happy-scale.*`](./references.probes/) |
| P03 | `tldr references` *(no SYMBOL)* | failure-missing-input | 2 | [`03-missing-arg.*`](./references.probes/) |
| P04 | `tldr references foo /no/such/dir` | failure-badpath | 1 | [`04-badpath.*`](./references.probes/) |
| P05 | `tldr references ... -f sarif` | format-reject | 1 | [`05-format-reject-sarif.*`](./references.probes/) |
| P06 | `tldr references ... -f text` | format-text | 0 | [`06-format-text.*`](./references.probes/) |
| P07 | `tldr references ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./references.probes/) |
| P08 | `tldr references ... -f dot` | format-reject-dot | 1 | [`08-format-reject-dot.*`](./references.probes/) |
| P09 | `tldr references ... --limit 2` | limit-truncate | 0 | [`09-limit-small.*`](./references.probes/) |
| P10 | `tldr references ... --limit 0` | limit-zero | 0 | [`10-limit-zero.*`](./references.probes/) |
| P11 | `tldr references ... --include-definition` | include-def | 0 | [`11-include-def.*`](./references.probes/) |
| P12 | `tldr references ... --kinds call` | kinds-call | 0 | [`12-kinds-call.*`](./references.probes/) |
| P13 | `tldr references pandas backend --kinds import` | kinds-import | 0 | [`13-kinds-import.*`](./references.probes/) |
| P14 | `tldr references ... --kinds invalid_kind` | kinds-bogus (silent miss) | 0 | [`14-kinds-bogus.*`](./references.probes/) |
| P15 | `tldr references _to_finite_float <file> -s file` | scope-file | 0 | [`15-scope-file.*`](./references.probes/) |
| P16 | `tldr references symbol <file> -s local` | scope-local | 0 | [`16-scope-local.*`](./references.probes/) |
| P17 | `tldr references ... -s solar_system` | scope-bogus (silent fallback) | 0 | [`17-scope-bogus.*`](./references.probes/) |
| P18 | `tldr references ... -C 3` | context-lines (NOT IMPLEMENTED) | 0 | [`18-context-lines.*`](./references.probes/) |
| P19 | `tldr references ... --min-confidence 0.99` | high-confidence (filtered) | 0 | [`19-min-confidence-high.*`](./references.probes/) |
| P20 | `tldr references ... --min-confidence 2.0` | min-conf-oor (unreachable, silent) | 0 | [`20-min-confidence-oor.*`](./references.probes/) |
| P21 | `tldr references no_such_symbol_anywhere ...` | symbol-not-found (stderr hint) | 0 | [`21-symbol-not-found.*`](./references.probes/) |
| P22 | `tldr references ... -o text` | legacy hidden -o text | 0 | [`22-output-text-legacy.*`](./references.probes/) |
| P23 | `tldr references ... -l brainfuck` | bad-lang | 2 | [`23-bad-lang.*`](./references.probes/) |
| P24 | `tldr references ... -q` | quiet | 0 | [`24-quiet.*`](./references.probes/) |

### Observations

- **P01** — `_to_finite_float` query against `backend/`: returns 3 distinct definitions (`backend/precomputed_indicators.py:32`, `backend/providers/yahoo.py:18`, `backend/stage_analysis.py:24`) — same name in 3 files. `total_references: 22`, `shown_references: 20` (default --limit 20), `search_scope: "file"` (NOT "workspace" as default — see Crucial Rules below).
- **P02** — `Provider` query: returns class-kind definitions and references across the project. Confidence 1.0 across verified refs.
- **P03** — stderr `"error: the following required arguments were not provided: <SYMBOL>"`, exit `2`. SYMBOL is `String` (required).
- **P04** — stderr `"Error: Path not found: '/no/such/dir'. Please provide a valid file or directory."`, exit `1`. The S7-R56 helper includes both the tried path AND a suggestion — better UX than `tldr calls`'s bare `"Path not found: <path>"`.
- **P05** — stderr `"Error: --format sarif not supported by references. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format: `"References to: <symbol> (<kind>)"` header, `"Definitions:"` section, `"References (N found in Tms):"` section, each ref shown as `file:line:column [kind]\n  context`. Progress message `"Finding references to 'X' in <path>..."` on stderr.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by references. Use --format json. DOT is only emitted by: clones, deps, calls, impact, hubs, inheritance."`, exit `1`.
- **P09** — `--limit 2`: `total_references: 22`, `shown_references: 2`, `truncated: true`. References array has 2 entries; totals preserved.
- **P10** — `--limit 0`: `references: []`, `total_references: 22`, `shown_references: 0`, `truncated: true`. **`--limit 0` means literal zero, NOT unlimited.** Use a large `--limit` (e.g., 999999) for "unlimited" semantics.
- **P11** — `--include-definition` flag: output **identical** to P01 in this case (defs are always included in `definitions[]` array regardless of the flag). The flag may only affect text formatting; JSON shape unchanged.
- **P12** — `--kinds call`: 22 references all of kind=`call`. Most code references to a function are calls.
- **P13** — `--kinds import` against `pandas`: returns import-site references (rows where the kind is `import`).
- **P14** — **Silent failure mode:** `--kinds invalid_kind` returns ZERO references with the helpful stderr suggestion message. The kinds filter parses each comma-separated value; unrecognized values become a filter that matches nothing. No clap-level rejection. **Recovery hint:** use the documented kinds list: `call`, `read`, `write`, `import`, `type`.
- **P15** — `--scope file` against a `.py` file: `total_references: 10`, `search_scope: "file"`. Limits search to that single file.
- **P16** — `--scope local` against same file: `total_references: 14`, `search_scope: "local"`. **Different count from `file` scope (14 vs 10)** — `local` may include intra-function vs `file` only counts file-level refs. Behavior gap from naive expectation.
- **P17** — **Silent fallback:** `--scope solar_system` yields output identical to P01 (`search_scope: "file"` — engine-optimized from default workspace). No error for invalid scope; the parse function (`parse_scope` at references.rs) maps unknown values to a default.
- **P18** — `-C 3` (context-lines): output **identical** to P01. The flag is plumbed through to `ReferencesOptions.context_lines` but the engine ignores it. **`--help` honestly admits "(not implemented yet)"**.
- **P19** — `--min-confidence 0.99`: filters out nothing because most AST-verified refs are at confidence 1.0. Output essentially same as P01.
- **P20** — `--min-confidence 2.0`: confidence > 1.0 is unreachable, filters out EVERYTHING. Same "No references found" stderr hint. **No range validation** on min-confidence (unlike `tldr hubs` which validates 0.0-1.0).
- **P21** — `total_references: 0`, exit 0, helpful stderr: `"No references found for 'no_such_symbol_anywhere'. Searched 56 files. Suggestions: - Check the symbol spelling - Try a different search scope with --scope workspace - Verify the path contains relevant source files"`. S7-R50 mitigation.
- **P22** — `-o text` (hidden legacy flag): output identical to `-f text` (P06). The flag has `hide = true` so it doesn't appear in `--help`.
- **P23** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P24** — `-q` suppresses BOTH the progress message AND the "No references found" suggestion block on stderr; stdout JSON unaffected.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/references.rs` (674 lines)
- `crates/tldr-core/src/analysis/references.rs` (`find_references`, `ReferencesOptions`, `ReferencesReport`)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/references.rs:54-90
#[derive(Debug, Args)]
pub struct ReferencesArgs {
    pub symbol: String,
    #[arg(default_value = ".")] pub path: PathBuf,
    #[arg(long = "output", short = 'o', hide = true)] pub output: Option<String>,
    #[arg(long)] pub include_definition: bool,
    #[arg(long, short = 't')] pub kinds: Option<String>,
    #[arg(long, short = 's', default_value = "workspace")] pub scope: String,
    #[arg(long, short = 'n', default_value = "20")] pub limit: usize,
    #[arg(long, short = 'C', default_value = "0")] pub context_lines: usize,
    #[arg(long, default_value = "0.0")] pub min_confidence: f64,
}
```
Reveals: `--output` is **hidden** (`hide = true`) — backwards-compat alias for `--format` (P22). `kinds` and `scope` are `String`, not typed enums — both have silent fallback for invalid values. `min_confidence` has no range validator.

**Path validation:**
```rust
// references.rs:101-107
if !self.path.exists() {
    anyhow::bail!(
        "Path not found: '{}'. Please provide a valid file or directory.",
        self.path.display()
    );
}
```
Reveals: better error message than `tldr calls` (which says just "Path not found: X"). S7-R56 mitigation includes BOTH the tried path AND a recovery hint.

**Engine scope optimization (P01 root cause):**
The `find_references` engine internally optimizes the scope. When a symbol is determined to be file-local (no exports, no imports), the engine narrows from `workspace` to `file` to avoid scanning the whole project. The `search_scope` field in the response reflects the ACTUAL scope used. This is invisible from `--help`; users supplying `--scope workspace` may get `search_scope: "file"` in the response.

**No daemon route:** `grep -n try_daemon_route references.rs` returns 0 matches. The command builds its own search index per call. There's no `tldr warm` benefit.

**Helpful "no results" output (S7-R50):**
```rust
// references.rs:178-188
if report.total_references == 0 && !quiet {
    eprintln!();
    eprintln!("No references found for '{}'. Searched {} files.", ...);
    eprintln!("Suggestions:");
    eprintln!("  - Check the symbol spelling");
    eprintln!("  - Try a different search scope with --scope workspace");
    eprintln!("  - Verify the path contains relevant source files");
}
```
Reveals: when 0 refs found AND not `-q`, prints a multi-line suggestion block on stderr. The `--scope workspace` hint is interesting because workspace IS the default — but the engine may have narrowed it.

**Lua/Luau alias enrichment (P14.AGG14-13 fix):**
```rust
// references.rs:156-160
let resolved_lang = cli_lang.or_else(|| Language::from_directory(&self.path));
if matches!(resolved_lang, Some(Language::Lua) | Some(Language::Luau)) {
    enrich_lua_alias_callers(&mut report, &self.symbol, &self.path, resolved_lang);
}
```
Reveals: Lua-specific post-processing for `m.method` style cross-module callers via aliases (e.g. `local files = require("files"); files.reset()`). Other languages don't get this enrichment.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `references` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

---

## Architectural Deep Dive

- **Under the hood:** Two-pass analysis. (1) Text-search across files matching `--scope` for word-boundary matches of `SYMBOL`. (2) AST-verify each candidate using tree-sitter to classify as call/read/write/import/type or false-positive. The engine may auto-narrow scope based on symbol visibility (file-local symbol → file scope).
- **Performance:** Cold ~150-200ms on Stock-Monitor backend (56 files). No daemon caching; every call re-walks and re-parses. The "search_time_ms" stat is reported in the response.
- **LLM cognitive load:** Replaces "grep -rn 'symbol' . | filter false positives" with structured ref kinds, confidence scores, and per-ref context lines. Multiple definitions are surfaced cleanly (P01's 3 `_to_finite_float` defs). Pairs well with `tldr definition` (forward direction) and `tldr impact <fn>` (transitive callees).

---

## Intent & Routing

- **User/Agent Goal:** find every place a symbol is used (calls, reads, writes, imports, type annotations). Useful for: refactoring impact analysis, renaming preparation, dead-code verification (does `possibly_dead` from `tldr dead` really have only one ref?).
- **When to choose this over similar tools:**
  - Over `grep`: handles same-name symbols across files (P01: 3 defs of `_to_finite_float`), classifies refs by kind, filters false positives via AST verification.
  - Over `tldr definition`: `definition` answers "where is X declared?"; `references` answers "where is X used?". Inverse directions.
  - Over `tldr calls`: `calls` gives the whole project call graph; `references` zooms in on one symbol.
  - Over `tldr impact <fn>`: `impact` traces transitive callers/callees; `references` lists DIRECT use sites only.
- **Prerequisites (composition):**
  - For symbols with the same name in multiple files, the result's `definitions[]` array enumerates all sites — `definition` (singular) is just the first match.
  - To force a wider search when the engine auto-narrows scope: `--scope workspace` is the default but may be overridden; check `search_scope` in response for the actual scope used.
  - For kinds filtering, **stick to the documented set: `call`, `read`, `write`, `import`, `type`** — invalid kinds silently filter out everything (P14).

---

## Agent Synthesis

> **How to use `tldr references`:**
> Symbol use-site finder with kind classification. `tldr references <SYMBOL> [PATH]` returns JSON `{ symbol, definition, definitions[], references[], total_references, shown_references, truncated, search_scope, stats }`. Each reference has `kind` (call/read/write/import/type/definition), `confidence` (0–1), and `context` (single line). Default `--limit 20`, default scope `workspace` (auto-narrowed by engine). Exit codes: 0 ok (including 0-refs with helpful stderr suggestion), 1 path-not-found (with friendly multi-line error) / format-reject, 2 clap missing-arg / bad `--lang`.
>
> **Crucial Rules:**
> - **`--scope` value is silently overridden by engine optimization.** The CLI default is `workspace`, but for file-local symbols the engine narrows to `file` to avoid project-wide scans. The `search_scope` field in the JSON reflects the ACTUAL scope used — may differ from your `--scope` input. To verify, check the response field.
> - **`--kinds invalid_kind` is a SILENT failure mode.** Unrecognized kinds become a filter that matches nothing; result has 0 references with the "no results" stderr hint. No clap-level rejection because `kinds` is `String`, not a typed enum. Use only documented kinds: `call`, `read`, `write`, `import`, `type` (P14).
> - **`--scope <invalid>` silently falls back to the default** (`parse_scope` maps unknown values to workspace, which the engine may then narrow to file). No error — output matches the default-scope query. Use only `local`, `file`, `workspace`.
> - **`--limit 0` means literal zero references returned**, NOT unlimited. The `truncated: true` flag fires when total > limit. Use a large limit like `999999` for "all references."
> - **`--context-lines N` is declared but NOT IMPLEMENTED.** Confirmed by `--help` parenthetical and probe P18: output unchanged regardless of `-C` value. Context is always the single line of the reference.
> - **`--min-confidence` has no range validation.** Values > 1.0 (P20) filter everything out (since refs are ≤ 1.0); negative values pass through. Stick to 0.0–1.0.
> - **`--include-definition` has no JSON effect for default output.** `definitions[]` array is always populated when matches exist. The flag may only affect text formatting (definitions in the references list).
> - **Multiple `definitions` are common.** When SYMBOL exists in multiple files (e.g., the same helper function name used in 3 modules — P01: `_to_finite_float` in 3 files), `definitions[]` enumerates all. `definition` (singular) is the FIRST match. Always inspect `definitions[]` for the full picture.
> - **NO daemon route.** Every call re-walks the project. `tldr warm` is a no-op.
> - **The hidden `-o`/`--output` flag is a legacy alias.** Use the global `-f`/`--format` instead. `-o` is `hide = true` in clap.
>
> **Command:** `tldr references <SYMBOL> [PATH]`
>
> **With common flags:** `tldr references <SYMBOL> <PATH> -l <lang> --limit 999999 --kinds call --min-confidence 0.8 -f compact` (use to enumerate ALL high-confidence calls of a function for blast-radius analysis; verify each call site with `tldr extract <file>` for surrounding context since `-C` is unimplemented).
