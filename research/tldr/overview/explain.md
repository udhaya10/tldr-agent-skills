# Command: `tldr explain`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (cross-command enrichment via project call graph) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr explain` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`explain.probes/probe.sh`](./explain.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/overview/explain.md).

---

## Ground Truth (`tldr explain --help`)

```text
Comprehensive function analysis (signature, purity, complexity, callers, callees)

Usage: tldr explain [OPTIONS] <FILE> <FUNCTION>

Arguments:
  <FILE>
          Source file to analyze

  <FUNCTION>
          Function name to explain

Options:
      --depth <DEPTH>
          Call graph depth for callers/callees

          [default: 2]

  -o, --output <OUTPUT>
          Output file (stdout if not specified)

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
| Typical output size | medium (~1–4 KB for a real method, depending on caller/callee fan-out) |

**Top-level keys (JSON, `ExplainReport`):**
- `function` (`string`) — echoes the input function name VERBATIM (qualified `Class.method` is preserved, see P12)
- `file` (`string`) — input file path as given
- `line_start` (`u32`, 1-indexed) — first line of the function definition
- `line_end` (`u32`, 1-indexed) — last line of the function definition
- `line` (`u32`) — duplicate of `line_start` (legacy compatibility field)
- `language` (`string`) — auto-detected language name (`"python"`, `"rust"`, …; matches `Language::from_path`)
- `signature` (`SignatureInfo`) — see below
- `purity` (`PurityInfo`) — see below
- `complexity` (`ComplexityInfo`) — see below
- `callers` (`array<CallInfo>`) — same-file walker + cross-file project graph + references-based fallback (merged with path-aware dedup)
- `callees` (`array<CallInfo>`) — local AST walker; module-prefixed names like `math.isfinite` are emitted with `file: "<external>"`

**`signature` shape:** `{ params: [{ name, type }], return_type: string | null, decorators: [string], is_async: bool, docstring: string | null }`.

**`purity` shape:** `{ classification: "pure" | "impure" | "unknown", effects: [string], confidence: "high" | "medium" | "low" }`.
- `effects` values: `"global_write"`, `"attribute_write"`, `"io"`, `"collection_modify"` (`explain.rs:780-827`).
- `classification: "unknown"` with `confidence: "medium"` → "function calls something we don't know"; with `confidence: "low"` → "function has no calls at all, can't claim" (`explain.rs:756-770`).

**`complexity` shape:** `{ cyclomatic: u32, num_blocks: u32, num_edges: u32, has_loops: bool }`. `cyclomatic` is sourced from canonical `tldr_core::calculate_complexity` so it matches `tldr complexity`; the local walker fills only `num_blocks` / `num_edges` / `has_loops` (`explain.rs:2244-2251`).

**`CallInfo` shape:** `{ name: string, file: string, line: u32 }`. Same-file callees use the source file path; cross-module/external callees use the sentinel `file: "<external>"`.

**Error shapes (all stderr):**
- File-not-found: `"Error: file not found: /no/such/file.py"` → exit **5**
- Missing FUNCTION arg: clap-style `"error: the following required arguments were not provided: <FUNCTION> …"` → exit **2** (clap-level, NOT 1)
- Function not found in file: `"Error: symbol 'X' not found in <file>"` → exit **20** (name preserved verbatim, so `YahooProvider.no_such_method` appears as-is — P18)
- Format reject: `"Error: --format sarif not supported by explain. Use --format json. SARIF is only emitted by: vuln, clones."` → exit **1**
- Bad `--lang`: clap-style `"error: invalid value 'X' for '--lang <LANG>': Unknown language: X"` → exit **2**
- Non-source / directory FILE: `"Error: parse error in <path>: Unsupported language"` → exit **1** (a directory's "language" is None, so it falls into the parse-error wrapper, NOT a special directory check — P17)

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr explain backend/providers/yahoo.py _to_finite_float` | happy (module-level fn) | 0 | [`01-happy.*`](./explain.probes/) |
| P02 | `tldr explain backend/providers/yahoo.py fetch_historical_data` | happy-scale (instance method) | 0 | [`02-happy-scale.*`](./explain.probes/) |
| P03 | `tldr explain backend/providers/yahoo.py` *(no FUNCTION)* | failure-missing-input | 2 | [`03-missing-arg.*`](./explain.probes/) |
| P04 | `tldr explain /no/such/file.py some_fn` | failure-badpath | 5 | [`04-badpath.*`](./explain.probes/) |
| P05 | `tldr explain ... -f sarif` | format-reject | 1 | [`05-format-reject-sarif.*`](./explain.probes/) |
| P06 | `tldr explain ... -f text` | format-text | 0 | [`06-format-text.*`](./explain.probes/) |
| P07 | `tldr explain ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./explain.probes/) |
| P08 | `tldr explain ... -f dot` | format-reject-dot | 1 | [`08-format-reject-dot.*`](./explain.probes/) |
| P09 | `tldr explain ... --depth 0` | depth-zero (no-op) | 0 | [`09-depth-zero.*`](./explain.probes/) |
| P10 | `tldr explain ... --depth 5` | depth-five (no-op) | 0 | [`10-depth-five.*`](./explain.probes/) |
| P11 | `tldr explain ... no_such_function` | symbol-not-found | 20 | [`11-function-not-found.*`](./explain.probes/) |
| P12 | `tldr explain ... YahooProvider.fetch_historical_data` | qualified Class.method | 0 | [`12-qualified-name.*`](./explain.probes/) |
| P13 | `tldr explain ... -l python` | lang-flag | 0 | [`13-lang-flag.*`](./explain.probes/) |
| P14 | `tldr explain ... -l brainfuck` | bad-lang (clap) | 2 | [`14-bad-lang.*`](./explain.probes/) |
| P15 | `tldr explain ... -o <tmp> && cat <tmp>` | output-file (also prints to stdout) | 0 | [`15-output-file.*`](./explain.probes/) |
| P16 | `tldr explain README.md anything` | non-source-md | 1 | [`16-non-source-md.*`](./explain.probes/) |
| P17 | `tldr explain backend anything` | directory-arg | 1 | [`17-directory-arg.*`](./explain.probes/) |
| P18 | `tldr explain ... YahooProvider.no_such_method` | qualified-miss | 20 | [`18-qualified-miss.*`](./explain.probes/) |
| P19 | `tldr explain ... -q` | quiet (suppress progress) | 0 | [`19-quiet.*`](./explain.probes/) |

### Observations

- **P01** — Module-level `_to_finite_float` returns 5 callers (3 same-file via the AST walker; 2 cross-file via the project graph enrichment at `explain.rs:2270`) and 2 callees (`float`, `math.isfinite`). Both callees show `file: "<external>"` because the resolver can't anchor builtins / module-qualified names to a source file. `purity.classification = "unknown"` with `confidence: "medium"` — driven by `math.isfinite` not being in `PURE_BUILTINS` (`explain.rs:144-187`).
- **P02** — Instance method `fetch_historical_data` resolves correctly **without** the `YahooProvider.` qualifier. The bare-name lookup finds the first matching `function_definition` in the AST. `line_start=38`, `line_end=85` — same range as P12 with the qualified name.
- **P03** — stderr `"error: the following required arguments were not provided: <FUNCTION>"`, exit **2**. **Important divergence from `tldr definition`:** because `ExplainArgs.file` and `ExplainArgs.function` are NOT `Option<…>` (`explain.rs:47-50`), clap enforces them and returns exit 2, not the runtime exit-1 used by `definition`'s missing-arg path. Agents checking exit codes must treat both 1 and 2 as "missing args" depending on command.
- **P04** — stderr `"Error: file not found: /no/such/file.py"`, exit `5`. Matches the standardized N9 mapping in `RemainingError::exit_code()`.
- **P05** — stderr `"Error: --format sarif not supported by explain. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Renders a human-readable block (`Function:`, `File:`, `Lines:`, `Signature:`, `Purity:`, `Complexity:`, `Callers (N):`, `Callees (M):`). Progress message `"Analyzing function _to_finite_float in backend/providers/yahoo.py..."` lands on **stderr** (not stdout) and is suppressed by `-q`.
- **P07** — Single-line minified JSON, identical schema to P01. ~1KB for a small function.
- **P08** — stderr `"Error: --format dot not supported by explain. Use --format json. DOT is only emitted by: clones, deps, calls, impact, hubs, inheritance."`, exit `1`.
- **P09 & P10** — `--depth 0`, `--depth 2` (default, P02), and `--depth 5` all produce **byte-identical** output. The flag is declared (`explain.rs:52-54`) but **never read anywhere else in the source** (verified via `grep -n depth explain.rs` — only 4 hits, all in the docstring/struct). **`--depth` is dead code as of v0.4.0.** Cross-file enrichment via the project call graph (`explain.rs:2270` `enrich_with_project_graph`) does not take a depth parameter and walks transitively without bound.
- **P11** — stderr `"Error: symbol 'no_such_function' not found in backend/providers/yahoo.py"`, exit `20`. Mirrors the `definition`/`impact` exit-20 convention via `RemainingError::symbol_not_found` (`explain.rs:2194`).
- **P12** — `YahooProvider.fetch_historical_data` finds the same function as the bare name (P02) and emits the qualified name verbatim in the `function` field. The qualified-name resolver (`explain.rs:283-301`) first looks for a class, then the method inside the class subtree, then falls back to the last component as a bare name.
- **P13** — Explicit `-l python` produces output identical to auto-detect for a `.py` file. The `--lang` flag is plumbed through but the implementation in `explain.rs:2160` uses `Language::from_path` regardless — meaning **`--lang` is currently ignored by explain on files whose extension auto-detects correctly**. (To verify the dead-flag claim, a probe with a mis-extension file would be needed; not run here.)
- **P14** — clap-style error: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`. Same pre-parse rejection as `tldr definition` — the `Language` enum is typed at clap level.
- **P15** — `-o <path>` writes JSON to `<path>` AND ALSO prints the JSON to stdout (140 lines = 70 from `writer.write(&report)` + the bash `&& cat` showing the saved file contents). The source confirms this dual-write at `explain.rs:2283-2299` — there is no `if writer.is_text() { … } else if let Some(output) = … { … }` branching, so the writer fires unconditionally before the optional file write. Agents must redirect stdout (`> /dev/null`) if they want the file-only path.
- **P16** — stderr `"Error: parse error in README.md: Unsupported language"`, exit `1`. The error wrapper uses `RemainingError::parse_error` (`explain.rs:2161`) rather than a typed `UnsupportedLanguage`, so the message format reads "parse error … Unsupported language" — confusing but consistent.
- **P17** — Same shape as P16: `"Error: parse error in backend: Unsupported language"`, exit `1`. A directory passes the `file.exists()` check (directories exist!) but `Language::from_path` returns `None`, so it falls into the parse-error wrapper. **No upfront `is_file()` validation.**
- **P18** — stderr `"Error: symbol 'YahooProvider.no_such_method' not found in backend/providers/yahoo.py"`, exit `20`. The qualified name is preserved verbatim in the error — the fallback to the LAST component (`no_such_method`, also missing) is invisible to the user; they see only the original qualified name.
- **P19** — `-q` suppresses the `"Analyzing function ..."` progress message on stderr; stdout (the JSON report) is unaffected.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/remaining/explain.rs` (2400+ lines)
- `crates/tldr-cli/src/commands/remaining/error.rs:162-179` (exit codes)
- `crates/tldr-cli/src/commands/remaining/types.rs` (`ExplainReport`, `SignatureInfo`, `PurityInfo`, `ComplexityInfo`, `CallInfo`, `ParamInfo`)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/remaining/explain.rs:44-59
#[derive(Debug, Clone, Args)]
pub struct ExplainArgs {
    /// Source file to analyze
    pub file: PathBuf,
    /// Function name to explain
    pub function: String,
    /// Call graph depth for callers/callees
    #[arg(long, default_value = "2")]
    pub depth: u32,
    /// Output file (stdout if not specified)
    #[arg(long, short = 'o')]
    pub output: Option<PathBuf>,
}
```
Reveals: `file` and `function` are required positionals (not `Option<…>`), so clap enforces them → exit 2 on missing args (vs `tldr definition`'s exit 1 runtime check). `depth` is a `u32` with default `2`. `--output` short flag is **lowercase `-o`** (cf. `tldr definition` which uses uppercase `-O`).

**Dead `--depth` flag:**
```bash
$ grep -n "depth" crates/tldr-cli/src/commands/remaining/explain.rs
15://! # With call graph depth
16://! tldr explain src/utils.py calculate_total --depth 3
52:    /// Call graph depth for callers/callees
54:    pub depth: u32,
```
Reveals: `self.depth` is declared but **never accessed** anywhere in the file. The cross-file enrichment (`explain.rs:2270`) and reference-based enrichment (`explain.rs:2281`) both walk without a depth parameter. P09/P10 prove the empirical impact: byte-identical output for depth=0/2/5.

**Path validation:**
```rust
// explain.rs:2154-2161
if !self.file.exists() {
    return Err(RemainingError::file_not_found(&self.file).into());
}
let language = Language::from_path(&self.file)
    .ok_or_else(|| RemainingError::parse_error(&self.file, "Unsupported language"))?;
```
Reveals: only `exists()` is checked, not `is_file()`. A directory survives the existence check and trips the parse-error wrapper (P17).

**`--output` writes to file AND stdout (P15):**
```rust
// explain.rs:2283-2299
// Output based on format
if writer.is_text() {
    let text = format_explain_text(&report);
    writer.write_text(&text)?;
} else {
    writer.write(&report)?;  // <-- always writes to stdout
}

// Write to output file if specified
if let Some(ref output_path) = self.output {
    let output_str = if format == OutputFormat::Text {
        format_explain_text(&report)
    } else {
        serde_json::to_string_pretty(&report)?
    };
    std::fs::write(output_path, &output_str)?;
}
```
Reveals: stdout write and file write are sequential, not mutually exclusive. There's no `else { std::fs::write… }` — both fire when `--output` is set.

**Function lookup with qualified-name support:**
```rust
// explain.rs:283-301 (excerpt)
if function_name.contains('.') {
    let parts: Vec<&str> = function_name.split('.').collect();
    if parts.len() >= 2 {
        let class_name = parts[0];
        let remainder = parts[1..].join(".");
        if let Some(class_node) = find_class_node_explain(root, class_name, source) {
            let scope = class_node.child_by_field_name("body").unwrap_or(class_node);
            if let Some(found) = find_function_recursive(scope, source, &remainder, func_kinds) {
                return Some(found);
            }
        }
        // Fallback: try the LAST component as a bare name.
        let last = *parts.last().unwrap();
        return find_function_recursive(root, source, last, func_kinds);
    }
}
```
Reveals: qualified-miss probes (P18) attempt class-scope lookup, then fall back to bare-name lookup of the trailing segment. The error message still echoes the original qualified name (P18), not the trailing segment that was actually searched last.

**Purity 4-state classifier (`explain.rs:756-770`):**
```rust
if !effects.is_empty() {
    PurityInfo::impure(effects)
} else if has_unknown_calls {
    PurityInfo::unknown().with_confidence("medium")
} else if has_any_calls {
    PurityInfo::pure()
} else {
    PurityInfo::unknown().with_confidence("low")
}
```
Reveals: a function with zero call edges gets `unknown` (low confidence), not `pure` — "absence of evidence is not evidence of purity" (source comment line 766). Functions that ONLY call known-pure builtins get `pure`; functions that call ANY unknown name (e.g. `math.isfinite` because `isfinite` isn't in `PURE_BUILTINS`) get `unknown` (medium confidence).

**Cross-command consistency (cyclomatic):**
```rust
// explain.rs:2244-2251
let mut complexity_info = compute_complexity(func_node);
if let Ok(canonical) = tldr_core::calculate_complexity(
    self.file.to_str().unwrap_or_default(),
    &self.function,
    language,
) {
    complexity_info.cyclomatic = canonical.cyclomatic;
}
```
Reveals: `tldr explain` and `tldr complexity` are guaranteed to report the **same cyclomatic value** (per `cross-command-consistency-v3 P5.BUG-N2`). `num_blocks`/`num_edges`/`has_loops` come from the local walker only.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `explain` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route explain.rs` returns 0 matches. `explain` is pure cold-compute. The cross-file enrichment functions (`enrich_with_project_graph`, `enrich_with_references`) build the project call graph on every call via `tldr_core::build_project_call_graph` — this is the most expensive part of the command on real-size projects.

---

## Architectural Deep Dive

- **Under the hood:** Five sub-analyzers run sequentially over a single tree-sitter parse: (1) signature extraction (`extract_signature`), (2) purity (4-state classifier with effects), (3) complexity (local walker + canonical cyclomatic from `tldr_core::calculate_complexity`), (4) caller/callee discovery via three sources merged with path-aware dedup — local AST walker, project call graph (`build_project_call_graph`), and references-based fallback (`find_references` from `tldr-core`).
- **Performance:** O(tree-sitter parse of source file) + O(project call graph build). The project call graph dominates on real codebases — every `explain` invocation rebuilds it from scratch because there is no daemon cache. The dead `--depth` flag means there is no way to limit the call-graph build cost.
- **LLM cognitive load:** consolidates what would otherwise be ~5 separate commands (`extract` for signature, `complexity` for metrics, `calls` for callees, `references` for callers, `secure` / pattern matching for purity heuristics) into a single typed report. Particularly valuable when an agent needs to decide "should I edit this function?" — the purity field + caller count + complexity together signal blast radius.

---

## Intent & Routing

- **User/Agent Goal:** answer "what does this function do, what depends on it, and what does it depend on?" in a single call, without piping through multiple sub-commands.
- **When to choose this over similar tools:**
  - Over `tldr complexity`: when you also need signature, purity, and call relationships — `complexity` only returns the numeric metric.
  - Over `tldr calls` / `tldr references`: when you want **both directions** (callers + callees) plus context. `calls` gives callees only; `references` gives callers / use-sites only.
  - Over `tldr extract`: `extract` lists every function in a file; `explain` deep-analyzes one named function.
- **Prerequisites (composition):**
  - If you don't know the function name, pipe `tldr extract <file> -f compact | jq '.functions[].name'` first.
  - For qualified `Class.method` lookups, the class must be findable by `find_class_node_explain` — Python class definitions, JS/TS class declarations, Rust `impl` blocks, etc. Closures / inner functions are searched intra-class only.
  - To use the file-only output, redirect stdout: `tldr explain F FN -o report.json > /dev/null` (because `-o` does not suppress stdout — P15).

---

## Agent Synthesis

> **How to use `tldr explain`:**
> Single command for "deep-dive on one function." Required positionals are FILE and FUNCTION; FUNCTION can be bare (`fetch_historical_data`) or qualified (`YahooProvider.fetch_historical_data`) — both resolve to the same function via class-then-bare fallback. Default JSON shape has eight top-level keys (`function`, `file`, `line_start`, `line_end`, `line`, `language`, `signature`, `purity`, `complexity`, `callers`, `callees`). `-f text` for human display, `-f compact` for one-line JSON; `sarif` and `dot` are rejected. Exit codes: 0 ok, 1 format-reject / parse-error / unsupported-language / directory-as-file, 2 clap missing-arg or bad `--lang`, 5 file-not-found, 20 function-not-found. No daemon route — every call rebuilds the project call graph from scratch (the dominant cost on real codebases).
>
> **Crucial Rules:**
> - **`--depth` is dead code in v0.4.0.** Declared on the struct (`explain.rs:54`) but never read — depths 0, 2, and 5 produce byte-identical output. Do not waste tokens specifying it; rely on default behavior (which is "follow all edges, no limit") and prune callers/callees client-side if needed (P09, P10).
> - **`-o <path>` writes to file AND stdout simultaneously.** No `else` branch separates the two (`explain.rs:2283-2299`). To get file-only output, redirect: `tldr explain F FN -o out.json > /dev/null` (P15).
> - **Missing required args returns exit 2 (clap), not 1 (runtime).** `ExplainArgs.file` and `ExplainArgs.function` are required positionals, unlike `tldr definition` whose positionals are `Option<…>`. Cross-command exit-code expectation: 1 ≠ 2 — check both as "missing input" when scripting.
> - **A directory argument passes the existence check.** `if !self.file.exists()` only checks existence, not file-vs-dir. `tldr explain backend something` exits 1 with `"parse error in backend: Unsupported language"` (P17). Pass an actual `.py`/`.rs`/etc. file.
> - **Purity `unknown` has two confidences with different meanings.** `confidence: "medium"` = "we saw calls we couldn't classify"; `confidence: "low"` = "function has no calls at all" (`explain.rs:756-770`). Don't conflate the two when reasoning about side-effects.
> - **External callees show `file: "<external>"`.** Module-prefixed names like `math.isfinite` and Python builtins like `float` get the sentinel string, not a real path. Skip them when computing same-project blast radius (P01).
> - **The qualified-name search silently falls back to bare-name on the LAST segment.** `Class.no_such_method` first tries class-scoped lookup, then `find_function_recursive(root, "no_such_method")`. The error still echoes the qualified form, hiding the fallback (P18).
> - **Cyclomatic is canonical, blocks/edges/loops are local.** `cyclomatic` matches `tldr complexity`; the other complexity sub-fields come from a local walker that doesn't agree with the canonical engine. Use cyclomatic for cross-command comparisons.
>
> **Command:** `tldr explain <FILE> <FUNCTION>`
>
> **With common flags:** `tldr explain <FILE> <FUNCTION> -f compact` (use when feeding JSON to another agent step); `tldr explain <FILE> <FUNCTION> -f text -q` (use for terminal display without the progress noise).
