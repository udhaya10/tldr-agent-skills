# Command: `tldr definition`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified via runtime probe on other commands; `definition` itself is non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr definition` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`definition.probes/probe.sh`](./definition.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/overview/definition.md).

---

## Ground Truth (`tldr definition --help`)

```text
Go-to-definition - find where a symbol is defined

Usage: tldr definition [OPTIONS] [FILE] [LINE] [COLUMN]

Arguments:
  [FILE]
          Source file (positional, for position-based lookup)

  [LINE]
          line number (1-indexed, for position-based lookup)

  [COLUMN]
          column number (0-indexed, for position-based lookup)

Options:
      --symbol <SYMBOL>
          Find symbol by name instead of position

      --file <target_file>
          File to search in (used with --symbol)

      --project <PROJECT>
          Project root for cross-file resolution

      --workspace <WORKSPACE>
          Enable workspace-wide cross-file resolution.

          When enabled (default), if `--project` is not provided the project root is auto-detected from the source file by walking up looking for repository / package markers (`.git`, `Cargo.toml`, `pyproject.toml`, `package.json`, `go.mod`, `pom.xml`, `build.gradle`). Set to `false` (`--workspace=false`) to disable auto-detection and keep resolution strictly within the source file unless an explicit `--project` is provided.

          `definition-workspace-cross-file-v1`.

          [default: true]
          [possible values: true, false]

  -O, --output <OUTPUT>
          Output file (optional, stdout if not specified)

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
| Formats that error | `sarif`, `dot` (P05, P09: exit 1) |
| Typical output size | small (<1 KB) — single `DefinitionResult` record per call |

**Top-level keys (JSON, `DefinitionResult`):**
- `symbol` (`SymbolInfo`) — always present; describes the queried symbol
- `definition` (`Location` | omitted) — definition site; omitted via `serde(skip_serializing_if = "Option::is_none")` for builtins
- `type_definition` (`Location` | omitted) — reserved for future use; omitted in every probed call

**`symbol` (`SymbolInfo`) nested shape:**
- `name` (`string`) — symbol text resolved at the cursor (may be the FULL dotted module name on import sites — see P20)
- `kind` (`string`) — `snake_case` enum: `function`, `class`, `method`, `variable`, `parameter`, `constant`, `module`, `type`, `interface`, `property`, `unknown` (`types.rs:835`)
- `location` (`Location` | omitted) — present for resolved symbols; absent for builtins
- `type_annotation` (`string` | omitted) — never populated in probed calls
- `docstring` (`string` | omitted) — never populated in probed calls
- `is_builtin` (`bool`) — always serialized (`#[serde(default)]`); `true` only for Python builtins from `PYTHON_BUILTINS` (`definition.rs:44-116`)
- `module` (`string` | omitted) — `"builtins"` for builtin symbols; absent otherwise

**`Location` nested shape:** `{ file: string, line: u32 (1-indexed), column: u32 (0-indexed) }`. P01 confirms — note column is **0-indexed** despite line being 1-indexed.

**Builtin shape (P11):**
```json
{
  "symbol": {
    "name": "print",
    "kind": "function",
    "is_builtin": true,
    "module": "builtins"
  }
}
```
No `definition` field, no `location` field — both intentionally omitted.

**Error shapes (all stderr):**
- File-not-found: `"Error: file not found: /no/such/path.py"` → exit **5**
- Symbol-not-found (name mode): `"Error: symbol 'X' not found in <file>"` → exit **20**
- Unresolved at cursor (position mode): `"Error: invalid argument: unresolved at FILE:LINE:COL — symbol 'X' not found in scope"` → exit **1**
- Format reject: `"Error: --format sarif not supported by definition. Use --format json. SARIF is only emitted by: vuln, clones."` → exit **1**
- Bad `--lang`: clap-style `"error: invalid value 'X' for '--lang <LANG>': Unknown language: X"` → exit **2**
- Range error: `"Error: definition not found for FILE:L:C: invalid argument: column 9999 out of range on line 40 (line has 20 bytes)"` → exit **1**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr definition backend/providers/yahoo.py 40 12` | happy-pos | 0 | [`01-happy-pos.*`](./definition.probes/) |
| P02 | `tldr definition --symbol HistoricalDataProvider --file backend/providers/yahoo.py --project .` | happy-name (negative — not imported) | 20 | [`02-happy-name.*`](./definition.probes/) |
| P03 | `tldr definition` *(no args)* | failure-missing-input | 1 | [`03-missing-arg.*`](./definition.probes/) |
| P04 | `tldr definition /no/such/path.py 1 1` | failure-badpath | 5 | [`04-badpath.*`](./definition.probes/) |
| P05 | `tldr definition ... -f sarif` | format-reject | 1 | [`05-format-reject-sarif.*`](./definition.probes/) |
| P06 | `tldr definition ... -f text` | format-text | 0 | [`06-format-text.*`](./definition.probes/) |
| P07 | `tldr definition ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./definition.probes/) |
| P08 | `tldr definition --symbol HistoricalDataProvider` *(no --file)* | failure-missing-file | 1 | [`08-symbol-no-file.*`](./definition.probes/) |
| P09 | `tldr definition ... -f dot` | format-reject-dot | 1 | [`09-format-reject-dot.*`](./definition.probes/) |
| P10 | `tldr definition --symbol NoSuchSymbol --file ... --project .` | symbol-not-found | 20 | [`10-symbol-not-found.*`](./definition.probes/) |
| P11 | `tldr definition ... --symbol print --file backend/db.py` | builtin (Python) | 0 | [`11-builtin-print.*`](./definition.probes/) |
| P12 | `tldr definition --symbol Provider --file ... --workspace=false` *(no --project)* | workspace-disabled | 20 | [`12-workspace-false.*`](./definition.probes/) |
| P13 | `tldr definition ... -l brainfuck` | bad-lang | 2 | [`13-bad-lang.*`](./definition.probes/) |
| P14 | `tldr definition README.md 1 1` | unsupported-language (md) | 1 | [`14-non-source-md.*`](./definition.probes/) |
| P15 | `tldr definition backend/providers/yahoo.py 1 0` | pos-unresolved | 1 | [`15-pos-unresolved.*`](./definition.probes/) |
| P16 | `tldr definition ... 40 9999` | col-out-of-range | 1 | [`16-col-out-of-range.*`](./definition.probes/) |
| P17 | `tldr definition ... 999999 0` | line-out-of-range | 1 | [`17-line-out-of-range.*`](./definition.probes/) |
| P18 | `tldr definition ... -O <tmp> && cat <tmp>` | output-file | 0 | [`18-output-file.*`](./definition.probes/) |
| P19 | `tldr definition --symbol Provider --file backend/providers/yahoo.py --project .` | imported-symbol | 0 | [`19-imported-symbol.*`](./definition.probes/) |
| P20 | `tldr definition backend/providers/yahoo.py 12 0` | usage-site-on-import | 1 | [`20-usage-site.*`](./definition.probes/) |

### Observations

- **P01** — Cursor on `symbol` parameter token in `def fetch_historical_data(self, symbol: str, ...)` resolves via Pass 1 (local-scope) to the parameter declaration at line 40 col 8. Output proves `kind: "parameter"` and confirms column is **0-indexed** (cursor at col 12, definition at col 8). `type_annotation` and `docstring` fields are absent — never populated by current scanners despite being on the schema.
- **P02** — Counterintuitive miss: `HistoricalDataProvider` IS defined in `backend/providers/base.py` and `--project .` is set, but cross-file resolution returned exit 20 with `Error: symbol 'HistoricalDataProvider' not found in backend/providers/yahoo.py`. Reason: yahoo.py does NOT import `HistoricalDataProvider` (only `Provider`). Confirmed against `resolve_cross_file_python` (`definition.rs:3651`) — Python cross-file is **import-driven**, not project-walk. **Recovery hint:** pass `--file` pointing at the file that actually imports / defines the symbol, or use a position lookup on a usage site.
- **P03** — stderr `"Error: invalid argument: file argument is required"`, exit `1`. clap accepts the call (all positionals are `Option<…>`) and the runtime validator inside `DefinitionArgs::run` rejects it. **Recovery hint:** supply `FILE LINE COLUMN` (position mode) or `--symbol X --file Y` (name mode).
- **P04** — stderr `"Error: file not found: /no/such/path.py"`, exit `5` (standardized by `med-low-schema-cleanup-v1` N9, see `error.rs:165`).
- **P05** — stderr `"Error: --format sarif not supported by definition. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`. Confirms `validate_format_for_command` (`output.rs:113`) — `definition` is in neither SARIF_SUPPORTED nor DOT_SUPPORTED lists.
- **P06** — Text format renders `=== Definition Result ===` banner plus `Symbol`, `Kind`, and `Definition Location:` block. Progress message `Finding definition at <file>:<line>:<col>...` lands on stderr (not suppressed because `-q` was not passed).
- **P07** — Compact format is single-line minified JSON identical in shape to P01; ideal for piping into `jq` / agents.
- **P08** — stderr `"Error: invalid argument: --file is required with --symbol"`, exit `1`. Confirmed at `definition.rs:228`. **Recovery hint:** always pair `--symbol` with `--file`.
- **P09** — stderr `"Error: --format dot not supported by definition. Use --format json. DOT is only emitted by: clones, deps, calls, impact, hubs, inheritance."`, exit `1`.
- **P10** — stderr `"Error: symbol 'NoSuchSymbol' not found in backend/providers/yahoo.py"`, exit `20`. Mirrors `tldr impact`'s exit-20 convention (per `error.rs:155-168`).
- **P11** — Builtin path: `is_builtin: true`, `module: "builtins"`, NO `location` field, NO `definition` field. Exit 0 even though there is no source location — agents must check `is_builtin` before assuming `definition` is present. The probe passed BOTH positional and `--symbol`/`--file`: source confirms `--symbol` takes precedence (`definition.rs:226`).
- **P12** — stderr `"Error: symbol 'Provider' not found in backend/providers/yahoo.py"`, exit `20`. With `--workspace=false` AND no `--project`, the resolver never gets a `project_root`, so the cross-file branch (`definition.rs:400-407`) is skipped. The symbol IS imported, but without a project context the import-walker cannot run.
- **P13** — clap-style error: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`. **Important:** `--help` says "auto-detect if not specified" with no `[possible values:]` list, but `--lang` IS a typed enum that clap pre-validates BEFORE our `detect_language()` runs. Agents must spell language names from the canonical set (see `types/Language::all()`).
- **P14** — stderr `"Error: definition not found for README.md:1:1: unsupported language: md"`, exit `1`. Note: the `UnsupportedLanguage` variant has no special exit code (only `FileNotFound→5` and `SymbolNotFound→20` got N9 treatment); also the `anyhow::anyhow!` wrapper at `definition.rs:323` re-stringifies the error which would discard typed exit codes even if they existed.
- **P15** — stderr `"Error: invalid argument: unresolved at backend/providers/yahoo.py:1:0 — symbol '' not found in scope"`, exit `1`. Cursor on the docstring (line 1 col 0) — tree-sitter's `descendant_for_point_range` lands on a node whose extracted text is empty. Exit code is 1, NOT 20, because the error is wrapped as `InvalidArgument` (the unresolved sentinel from `definition.rs:489-495`), not `SymbolNotFound`. **Recovery hint:** put the cursor on the symbol's identifier, not whitespace.
- **P16** — stderr `"Error: definition not found for backend/providers/yahoo.py:40:9999: invalid argument: column 9999 out of range on line 40 (line has 20 bytes)"`, exit `1`. Note the message reports **byte length**, not character length — relevant for non-ASCII source.
- **P17** — stderr `"Error: definition not found for backend/providers/yahoo.py:999999:0: invalid argument: line 999999 out of range (file has 239 lines)"`, exit `1`.
- **P18** — `-O <path>` writes the same pretty JSON as stdout to the path; stdout is **empty** (compare `18-output-file.out` — only the `cat` after `&&` shows content). For text format, `format_definition_text(&result)` is written instead of JSON.
- **P19** — Cross-file resolution succeeds for `Provider` because yahoo.py contains `from backend.providers.base import Provider`. Output shows `kind: "class"`, `file: "./backend/providers/base.py"`, `line: 155`, `column: 6`. Note the resolved path is prefixed with `./` (relative to project root passed via `--project .`).
- **P20** — stderr `"Error: invalid argument: unresolved at backend/providers/yahoo.py:12:0 — symbol 'pandas' not found in scope"`, exit `1`. Cursor on `import pandas as pd`. The position resolver extracts `pandas` (the module name) NOT `pd` (the alias), then fails because `pandas` isn't a bound name in any scope. **Hidden quirk:** cursor on an import statement is treated as a lookup of the dotted module name, not the import alias. **Recovery hint:** to resolve an alias like `pd`, place the cursor on a USE site (e.g. `pd.DataFrame`).

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/remaining/definition.rs` (4894 lines)
- `crates/tldr-cli/src/commands/remaining/error.rs` (220 lines)
- `crates/tldr-cli/src/commands/remaining/types.rs:830-900` (`SymbolKind`, `SymbolInfo`, `DefinitionResult`)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/remaining/definition.rs:167-207
#[derive(Debug, Args)]
pub struct DefinitionArgs {
    /// Source file (positional, for position-based lookup)
    pub file: Option<PathBuf>,
    /// line number (1-indexed, for position-based lookup)
    pub line: Option<u32>,
    /// column number (0-indexed, for position-based lookup)
    pub column: Option<u32>,
    /// Find symbol by name instead of position
    #[arg(long)]
    pub symbol: Option<String>,
    /// File to search in (used with --symbol)
    #[arg(long = "file", name = "target_file")]
    pub target_file: Option<PathBuf>,
    /// Project root for cross-file resolution
    #[arg(long)]
    pub project: Option<PathBuf>,
    /// Enable workspace-wide cross-file resolution.
    #[arg(long, default_value_t = true, action = clap::ArgAction::Set)]
    pub workspace: bool,
    /// Output file (optional, stdout if not specified)
    #[arg(long, short = 'O')]
    pub output: Option<PathBuf>,
}
```
Reveals: every positional is `Option<…>`, so clap can't enforce "required" — `DefinitionArgs::run` does runtime validation that returns `InvalidArgument` (exit 1). Workspace is a **typed bool** (`--workspace=false` works; `--no-workspace` does not).

**Mode-selection logic (`--symbol` wins over positionals):**
```rust
// definition.rs:226-329
let result = if let Some(ref symbol_name) = self.symbol {
    // Name-based mode - require --file
    let file = self.target_file.as_ref().ok_or_else(|| {
        RemainingError::invalid_argument("--file is required with --symbol")
    })?;
    ...
} else {
    // Position-based mode
    let file = self.file.as_ref().ok_or_else(|| ...)?;
    let line = self.line.ok_or_else(|| ...)?;
    let column = self.column.ok_or_else(|| ...)?;
    ...
};
```
Reveals: passing BOTH positional and `--symbol` (as P11 did) routes through the **name path** with positionals silently ignored.

**Exit-code standardization (N9):**
```rust
// definition.rs:300-326 (excerpt)
match e {
    RemainingError::FileNotFound { .. }
    | RemainingError::SymbolNotFound { .. } => return Err(e.into()),
    _ => {
        let msg = e.to_string();
        let detail = if msg.contains("unresolved at") { msg } else {
            format!("definition not found for {}:{}:{}: {}", ...)
        };
        return Err(anyhow::anyhow!(detail));
    }
}
```
And the exit-code mapping in `error.rs:162-179`:
```rust
pub fn exit_code(&self) -> i32 {
    match self {
        Self::FileNotFound { .. } => 5,
        Self::SymbolNotFound { .. } => 20,
        Self::FindingsDetected { .. } => 2,
        Self::AutodetectUnsupported { .. } => 2,
        _ => 1,
    }
}
```
Reveals: only `FileNotFound` (5) and `SymbolNotFound` (20) get standardized codes in the position-mode error wrapper. Every other failure (parse, unsupported language, unresolved-at-cursor, file too large) collapses onto exit **1** because the wrapper drops the typed error into `anyhow::anyhow!(detail)`.

**Python cross-file is import-driven (`definition.rs:3651`):**
```rust
fn resolve_cross_file_python(...) {
    let imports = extract_imports(&source);
    for (module_path, imported_names) in imports {
        let is_imported = imported_names.is_empty()
            || imported_names.contains(&symbol.to_string());
        if is_imported { ... }
    }
}
```
Contrast generic walker (`definition.rs:3705`) which scans every project file matching the language's extensions. **Asymmetry:** Python uses imports; all other 17 languages use `walkdir`. P02 vs P19 prove this empirically.

**Three-pass position resolver (`definition.rs:431-499`, `definition-name-resolution-v1`):**
1. **Local scope** (`resolve_local_scope`) — walks tree-sitter ancestors looking at parameter lists / let-bindings of each enclosing scope. Implemented for 17 of the 18 supported languages (only the bare engine languages opt out — see `definition.rs:537-559`).
2. **File scope + cross-file** (`find_definition_by_name`) — top-level defs.
3. **Import scope** (`resolve_import_scope`) — if cursor is on an imported alias, resolves to the `import` line.

If all three miss, returns the `unresolved at FILE:LINE:COL — symbol 'X' not found in scope` sentinel (P15).

**Workspace auto-detection markers (`definition.rs:3770-3783`):**
```rust
const MARKERS: &[&str] = &[
    ".git", "Cargo.toml", "pyproject.toml", "setup.py",
    "package.json", "go.mod", "pom.xml", "build.gradle",
    "build.gradle.kts", "composer.json", "Gemfile", "mix.exs",
];
```
Reveals: `--help` understates the marker list (claims 7, actually 12). Walks up from `<file>.parent()` and returns the first ancestor containing any marker.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `definition` is in neither `SARIF_SUPPORTED` (`["vuln","clones"]`) nor `DOT_SUPPORTED` (`["clones","deps","calls","impact","hubs","inheritance"]`).

**No daemon route:** `grep -n try_daemon_route definition.rs` returns 0 matches. `definition` is a **pure cold-compute** command — every invocation reparses the file from disk via `PARSER_POOL.parse_with_path` (`definition.rs:561`). The shared tree-sitter parser pool is the only cache.

---

## Architectural Deep Dive

- **Under the hood:** tree-sitter AST per call. `definition` does not use the SQLite scope cache, the daemon, the call-graph, or the PDG. It parses the source via `PARSER_POOL.parse_with_path`, walks ancestors for local-scope binding scrapers (17 language-specific scanners), and falls through to file-scope / cross-file passes if local resolution misses.
- **Performance:** O(parse) per call. The parser pool amortizes parser construction across calls within a process, but invocations from the shell each get a fresh process and re-parse from scratch. There is **no SQLite cache** to warm — `tldr warm` and `tldr daemon start` do nothing for this command. Cross-file walks (Python imports OR generic project walker) add O(N×parse) over imported / matching files, with `MAX_IMPORT_DEPTH = 10` (`definition.rs:41`) to bound recursion.
- **LLM cognitive load:** replaces "grep for `def X(` and hope the first hit is the definition" — handles parameters, local variables, imported symbols, cross-file Python imports, and language-specific scope rules. Returns a typed `SymbolKind` (`parameter` vs `class` vs `method`) so the agent immediately knows the shape of what it found. The 0-indexed column convention is the main footgun: editors / `tldr extract` return 1-indexed columns, so agents must subtract 1 when piping coordinates from those tools.

---

## Intent & Routing

- **User/Agent Goal:** answer "where is X defined?" for a symbol seen at a particular cursor position OR by name — without loading the surrounding file into the agent's context window.
- **When to choose this over similar tools:**
  - Over `grep "def X"`: handles imports, local scopes, classes, builtins, and Python module aliasing — fewer false positives.
  - Over `tldr references` (reverse direction): use `definition` to jump from a USE site to the declaration; use `references` to find every USE of a known declaration.
  - Over `tldr extract`: `extract` lists every function in a file; `definition` answers "for this specific cursor position, what's the binding?"
- **Prerequisites (composition):**
  - For Python cross-file lookups: query against the file that *imports* the symbol, not just any file in the project (P02 vs P19).
  - For position mode with `tldr extract` line numbers: subtract 1 from the column if the upstream tool emits 1-indexed columns.
  - For workspace auto-detection: the file's ancestor chain must contain `.git` / `pyproject.toml` / etc. — opt out with `--workspace=false` when working with synthetic fixtures.

---

## Agent Synthesis

> **How to use `tldr definition`:**
> Two mutually exclusive modes share one command. Position mode — `tldr definition FILE LINE COLUMN` — jumps from a cursor (1-indexed line, **0-indexed column**) to the binding at that point, running a three-pass resolver (local-scope → file-scope → import-scope). Name mode — `tldr definition --symbol NAME --file PATH [--project ROOT]` — searches a specific file then optionally walks cross-file. The two modes diverge in error semantics: position-mode misses yield `unresolved at FILE:L:C` (exit 1) while name-mode misses yield `symbol 'X' not found in <file>` (exit 20). All other failures fall onto exit 1 except `file not found` (exit 5) and clap-level `--lang` validation (exit 2). Default output is pretty JSON `{ symbol, definition }`; switch to `-f compact` for one-line piping or `-f text` for human display. `sarif` and `dot` are rejected at runtime. No daemon route exists — `tldr warm` has no effect on this command.
>
> **Crucial Rules:**
> - **Column is 0-indexed, line is 1-indexed.** Mismatched indexing is the most common cause of `unresolved at` (P01 explicitly shows: cursor `40 12` resolves to declaration at `column: 8`).
> - **Python cross-file is import-driven, not project-walk.** If you ask for `--symbol X --file Y --project Z` and `Y` doesn't `import X`, the resolver will NOT find `X` even if it's defined elsewhere in `Z`. Other 17 languages use a generic project walker (`walkdir`). For Python misses, point `--file` at a file that imports the symbol, or use position mode on a usage site. (Source: `definition.rs:3651` Python branch vs `:3705` generic walker; proved by P02 vs P19.)
> - **`--symbol` silently wins over positional `FILE LINE COLUMN`** — supplying both routes to name mode and ignores the positionals (`definition.rs:226`).
> - **`--workspace=false` without `--project` disables cross-file entirely** — no project root means the cross-file branch (`definition.rs:400-407`) is skipped. P12 confirms.
> - **Builtins return `is_builtin: true` with no `location` and no `definition`** — agents must check `is_builtin` before assuming `definition.file` exists. Only Python participates; all other languages return `is_builtin: false` (`definition.rs:3951-3956`).
> - **Cursor on an import statement extracts the dotted module name, not the alias.** `import pandas as pd` → cursor on line 12 reports `symbol 'pandas'`, not `pd`. Use a USE site to resolve aliases (P20).
> - **Exit codes are partially standardized.** `FileNotFound→5`, `SymbolNotFound→20`, clap `--lang→2`, everything else `→1`. The wrapper at `definition.rs:323` collapses parse / unsupported-language / column-range / unresolved-at-cursor errors all onto exit 1 by re-stringifying through `anyhow::anyhow!`.
> - **No daemon route.** `tldr definition` re-parses on every call; do not waste time `tldr warm`-ing for this command.
>
> **Command:** `tldr definition <FILE> <LINE> <COLUMN>` *(position mode)*
>
> **With common flags:** `tldr definition --symbol <NAME> --file <PATH> --project <ROOT>` (use when you know the name but not the position; pair `--workspace=false` when running on synthetic / non-VCS trees).
