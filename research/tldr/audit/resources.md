# Command: `tldr resources`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; resources is AST + CFG-based, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr resources` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`resources.probes/probe.sh`](./resources.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/audit/resources.md).

---

## Ground Truth (`tldr resources --help`)

```text
Analyze resource lifecycle (leaks, double-close, use-after-close)

Usage: tldr resources [OPTIONS] <FILE> [FUNCTION]

Arguments:
  <FILE>
          Source file to analyze

  [FUNCTION]
          Function to analyze (optional; analyze all if omitted)

Options:
  -l, --lang <LANG>
          Language filter (auto-detected if omitted)

      --check-leaks
          Run leak detection (R2) - enabled by default

      --check-double-close
          Run double-close detection (R3)

      --check-use-after-close
          Run use-after-close detection (R4)

      --check-all
          Run all checks (R2, R3, R4)

      --suggest-context
          Suggest context manager usage (R6)

      --show-paths
          Show detailed leak paths (R7)

      --constraints
          Generate LLM constraints (R9)

      --summary
          Output summary statistics only

      --project-root <PROJECT_ROOT>
          Project root for path validation (optional)

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
| Formats that work | `json`, `text` (P01, P06) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| **Format BROKEN** | **`compact` returns pretty JSON, identical to default (P07 bug)** |
| Typical output size | small (~18 lines pretty JSON; larger when resources found) |

**Top-level keys (JSON, `ResourcesReport`):**
- `file` (`string`) — project-relative path (uses absolute when --project-root resolves)
- `language` (`string`) — detected language
- `function` (`string` | `null`) — function filter; null when analyzing whole file
- `resources` (`array<Resource>`) — detected resources
- `leaks` (`array<Leak>`) — leak findings
- `double_closes` (`array`) — double-close findings
- `use_after_closes` (`array`) — use-after-close findings
- `suggestions` (`array`) — context-manager refactor suggestions (with `--suggest-context`)
- `constraints` (`array`) — LLM constraint statements (with `--constraints`)
- `summary` (`object`) — `{ resources_detected, leaks_found, double_closes_found, use_after_closes_found }`
- `analysis_time_ms` (`u32`)

**`Resource` shape:** `{ name, resource_type, line, closed }` — `resource_type` observed values: `"connection"`, `"cursor"`.

**`Leak` shape:** `{ resource, line, paths }` — `paths` is `null` unless `--show-paths` is set.

**Empty-result shape (P01, yahoo.py has no resources):**
All arrays empty, summary all-zero, `analysis_time_ms: 1`. Schema identical to happy with results — agents must check `resources.length > 0` to detect non-empty.

**Error shapes (ContractsError-based):**
- Missing FILE: clap-style → exit **2**
- File not found: `"Error: file not found: /no/such/file.py"` → exit **1**
- Function not found: `"Error: function '<name>' not found in <ABS path>"` → exit **1** (ContractsError::FunctionNotFound — matches `tldr contracts`/`tldr dead-stores`)
- Non-source single file: `"Error: unsupported language: md"` → exit **1** (NOT 11!) — distinct from `tldr loc`/`tldr halstead`/`tldr patterns` which all use exit 11
- Directory as FILE: `"Error: IO error: Is a directory (os error 21)"` → exit **1** (**raw OS error leaks through!**)
- Format reject: `"Error: --format sarif not supported by resources. ..."` → exit **1**
- Bad `--lang`: clap-style → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr resources yahoo.py` | happy (empty result) | 0 | [`01-happy.*`](./resources.probes/) |
| P02 | `tldr resources yahoo.py fetch_historical_data` | happy-scale (function filter) | 0 | [`02-happy-scale.*`](./resources.probes/) |
| P03 | `tldr resources` *(no FILE)* | failure-missing-input | 2 | [`03-missing-arg.*`](./resources.probes/) |
| P04 | `tldr resources /no/such/file.py` | failure-badpath | 1 | [`04-badpath.*`](./resources.probes/) |
| P05 | `tldr resources ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./resources.probes/) |
| P06 | `tldr resources ... -f text` | format-text | 0 | [`06-format-text.*`](./resources.probes/) |
| P07 | `tldr resources ... -f compact` | **format-compact BROKEN (returns pretty)** | 0 | [`07-format-compact.*`](./resources.probes/) |
| P08 | `tldr resources ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./resources.probes/) |
| P09 | `tldr resources ... --check-leaks` | check-leaks | 0 | [`09-check-leaks.*`](./resources.probes/) |
| P10 | `tldr resources ... --check-double-close` | check-double-close | 0 | [`10-check-double-close.*`](./resources.probes/) |
| P11 | `tldr resources ... --check-use-after-close` | check-uac | 0 | [`11-check-uac.*`](./resources.probes/) |
| P12 | `tldr resources ... --check-all` | check-all | 0 | [`12-check-all.*`](./resources.probes/) |
| P13 | `tldr resources ... --suggest-context` | suggest-context | 0 | [`13-suggest-context.*`](./resources.probes/) |
| P14 | `tldr resources ... --show-paths` | show-paths | 0 | [`14-show-paths.*`](./resources.probes/) |
| P15 | `tldr resources ... --constraints` | generate-constraints | 0 | [`15-constraints.*`](./resources.probes/) |
| P16 | `tldr resources ... --summary` | summary-only | 0 | [`16-summary.*`](./resources.probes/) |
| P17 | `tldr resources ... --project-root backend` | project-root | 0 | [`17-project-root.*`](./resources.probes/) |
| P18 | `tldr resources yahoo.py no_such_function` | function-not-found | 1 | [`18-function-not-found.*`](./resources.probes/) |
| P19 | `tldr resources ... -l brainfuck` | bad-lang | 2 | [`19-bad-lang.*`](./resources.probes/) |
| P20 | `tldr resources ... -l python` | lang-python explicit | 0 | [`20-lang-python.*`](./resources.probes/) |
| P21 | `tldr resources ... -l typescript` | lang-mismatch (silent ignore) | 0 | [`21-lang-mismatch.*`](./resources.probes/) |
| P22 | `tldr resources README.md` | non-source-md (exit 1!) | 1 | [`22-non-source-md.*`](./resources.probes/) |
| P23 | `tldr resources backend/providers` | directory-as-FILE (raw OS error) | 1 | [`23-directory-arg.*`](./resources.probes/) |
| P24 | `tldr resources ... -o text` | legacy -o text | 0 | [`24-output-flag-text.*`](./resources.probes/) |
| P25 | `tldr resources ... -q` | quiet | 0 | [`25-quiet.*`](./resources.probes/) |

### Observations

- **P01** — `yahoo.py`: no resources detected. All arrays empty; summary all-zero. `analysis_time_ms: 1`. (Note: `backend/db.py` DOES contain resources — 5 detected, 5 leaks reported — confirming the engine works.)
- **P02** — `yahoo.py fetch_historical_data`: same empty result with `"function": null` (NOT the supplied name!). Interesting: the function arg is parsed but not propagated to output's `function` field if no resources match.
- **P03** — stderr `"error: the following required arguments were not provided: <FILE>"`, exit `2`.
- **P04** — stderr `"Error: file not found: /no/such/file.py"`, exit `1`. Lowercase "file" — matches `tldr chop`/`tldr contracts`/`tldr cohesion`.
- **P05** — stderr `"Error: --format sarif not supported by resources. ..."`, exit `1`.
- **P06** — Text format: `"Resource Analysis: <file>\nLanguage: python\n\nResources detected: 0\n\nLeaks found: 0\n\nSummary:\n  resources_detected: 0\n  ...\n\nAnalysis completed in 1ms"`. Clean per-file summary.
- **P07** — **CONFIRMED BUG: `-f compact` returns PRETTY JSON identical to default.** File sizes verified: `01-happy.out` and `07-format-compact.out` are byte-identical (370 bytes). Single-line minified output is NOT produced. Possible cause: the legacy `output_format` enum (`-o`) only supports `Json`/`Text`, and the global format dispatcher may not honor the `Compact` variant for this command. **Document and avoid `-f compact` on this command.**
- **P08** — stderr `"Error: --format dot not supported by resources. ..."`, exit `1`.
- **P09–P12** — All check flags: identical output (no resources in yahoo.py). On `db.py`: each flag enables a specific detector. `--check-leaks` is on by default per `--help`; `--check-all` enables R2+R3+R4.
- **P13** — `--suggest-context`: adds `suggestions: []` content (in this case empty). Output identical to P01 since no suggestions could be made.
- **P14** — `--show-paths`: would populate `leaks[].paths` (currently `null`). Empty result here means no leaks → no paths.
- **P15** — `--constraints`: populates `constraints: []` array with LLM-consumable rule statements.
- **P16** — `--summary`: per `--help` should output statistics only, but observed output is FULL JSON (18 lines, same as default). **Possible second bug** — `--summary` flag may not be honored. Investigation note.
- **P17** — `--project-root backend`: identical output, no observable effect on yahoo.py (path is inside backend already).
- **P18** — stderr `"Error: function 'no_such_function' not found in /Users/.../yahoo.py"`, exit `1` (ContractsError::FunctionNotFound). Matches `tldr contracts` (exit 1), differs from `tldr complexity`/`tldr explain` (exit 20).
- **P19** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P20** — Explicit `-l python`: identical to default.
- **P21** — **SILENT IGNORE:** `-l typescript` on `.py`: exit 0 with same output. The lang flag is parsed but doesn't affect parsing. Same anti-pattern as `tldr cohesion`/`tldr coupling`/`tldr interface`/`tldr invariants`.
- **P22** — stderr `"Error: unsupported language: md"`, exit **1** (NOT 11!). **Cross-command divergence:** `tldr loc`/`tldr halstead`/`tldr patterns` use exit 11 for the same error class; `tldr resources` uses exit 1. Same EXTENSION-ONLY wording as `tldr patterns` (`"unsupported language: md"`).
- **P23** — **RAW OS ERROR LEAKS THROUGH:** stderr `"Error: IO error: Is a directory (os error 21)"`, exit `1`. The CLI doesn't pre-check `is_file()` on FILE arg; the engine's file-read fails with raw stdlib I/O error (errno 21 = EISDIR). **Bug:** should be a clean "FILE must be a regular file" error.
- **P24** — Legacy `-o text`: produces same text output as `-f text` (P06).
- **P25** — `-q`: identical output (no progress message observed for this command).

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/patterns/resources.rs` (~3700 lines — large because of per-language CFG construction)
- `crates/tldr-core/src/...` (resource lifecycle analyzers per language)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/patterns/resources.rs:664-720
#[derive(Debug, Args, Clone)]
pub struct ResourcesArgs {
    pub file: PathBuf,
    pub function: Option<String>,
    #[arg(long, short = 'l')] pub lang: Option<Language>,
    #[arg(long, default_value = "true")] pub check_leaks: bool,
    #[arg(long)] pub check_double_close: bool,
    #[arg(long)] pub check_use_after_close: bool,
    #[arg(long)] pub check_all: bool,
    #[arg(long)] pub suggest_context: bool,
    #[arg(long)] pub show_paths: bool,
    #[arg(long)] pub constraints: bool,
    #[arg(long)] pub summary: bool,
    #[arg(long = "output", short = 'o', hide = true, default_value = "json", value_enum)]
    pub output_format: OutputFormat,  // ← LOCAL enum, NOT global OutputFormat
    #[arg(long)] pub project_root: Option<PathBuf>,
}
```
Reveals: legacy `output_format` is a LOCAL enum (only `Json`/`Text`) — not the global one. This is why `-f compact` (which is on the global enum) doesn't properly cascade through the formatter — the local fallback only knows JSON and Text.

**Format-compact bug:**
The `run()` function dispatches output based on `output_format` (the local enum, json/text only). When global `-f compact` is set, the global path doesn't reach the local formatter to produce compact output. Engine returns pretty JSON unconditionally for non-text modes.

**Path-validation fallthrough:**
The CLI does NOT validate `path.is_file()` upfront. Directory-as-FILE goes through to the engine which calls `fs::read_to_string()` → returns `IO error: Is a directory (os error 21)` from the standard library. Raw error wrapping leaks through to user.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `resources` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route patterns/resources.rs` returns 0 matches.

---

## Architectural Deep Dive

- **Under the hood:** Per-file CFG (control-flow graph) construction. Tracks resource acquisitions (`open`, `connect`, `cursor`) → checks for matching releases (`close`, `__exit__`) along all CFG paths. Reports: R2 (leak = no close on some path), R3 (double-close = close called twice), R4 (use-after-close = read/write after close on same resource). R6 (suggestion = "use `with` statement"), R7 (path = sequence of statements leading to leak), R9 (constraints = LLM-consumable summary).
- **Performance:** Cold ~1-50ms per file depending on CFG size. NO daemon caching.
- **LLM cognitive load:** Resource-leak finder — the modern static-analysis equivalent of `find . -name '*.py' | xargs grep -L 'with '`. For Python projects, the actionable signal is `--suggest-context` (push `open()` → `with open() as f:`). For multi-language projects, look at `resource_type` field to filter to the resource class you care about (DB connections vs file handles vs sockets).

---

## Intent & Routing

- **User/Agent Goal:** find resource lifecycle bugs — leaks (forgotten close), double-close, use-after-close. Suggest context-manager refactors.
- **When to choose this over similar tools:**
  - Over `tldr secure`: secure looks for security patterns; resources looks for resource management.
  - Over `tldr smells`: smells is broader anti-pattern; resources is focused on lifecycle.
  - Over manual review: CFG-based, considers all execution paths.
- **Prerequisites (composition):**
  - Pass a single FILE; directories fail with raw OS error (P23).
  - Optional FUNCTION arg to focus on one function — though function-not-found is exit 1 (ContractsError::FunctionNotFound).
  - For LLM workflows, combine `--constraints` (generates rule statements) with `--suggest-context` (refactor hints).

---

## Agent Synthesis

> **How to use `tldr resources`:**
> Resource-lifecycle analyzer. `tldr resources <FILE> [FUNCTION]` returns JSON `{ file, language, function, resources, leaks, double_closes, use_after_closes, suggestions, constraints, summary, analysis_time_ms }`. Each `Resource` has `{ name, resource_type, line, closed }`; each `Leak` has `{ resource, line, paths }` (paths null unless `--show-paths`). Default `--check-leaks` enabled; `--check-all` adds double-close and use-after-close detectors. `--suggest-context` populates suggestions[]; `--constraints` populates LLM constraint statements. Default JSON; `-f text` for human-readable summary; **`-f compact` is BROKEN (returns pretty JSON)**; `sarif`/`dot` rejected. Exit codes: 0 ok (including empty result), 1 file-not-found / function-not-found / unsupported-language / directory-as-FILE / format-reject, 2 missing FILE / bad-lang.
>
> **Crucial Rules:**
> - **`-f compact` IS BROKEN.** P07: produces byte-identical output to default JSON (370 bytes), not single-line minified. **Cause** (verified in source at resources.rs:715): the legacy `output_format` enum (`-o`/`--output`) is LOCAL to this command (only `Json`/`Text`); the global `-f compact` doesn't cascade through. **Workaround:** pipe through `jq -c` for compact output.
> - **`--summary` flag may not be honored.** P16: passing `--summary` returns full output (18 lines), identical to default. The flag is declared but observed not to filter to summary-only. Possible second bug.
> - **Non-source single file returns exit 1, NOT 11.** P22: `tldr resources README.md` → `"Error: unsupported language: md"`, exit `1`. **Cross-command divergence:** `tldr loc`/`tldr halstead`/`tldr patterns` use exit 11 for the same error class. The wording matches `tldr patterns` (extension-only) but the exit code differs.
> - **Directory-as-FILE leaks raw OS error.** P23: `tldr resources <directory>` → `"Error: IO error: Is a directory (os error 21)"`, exit 1. The CLI doesn't pre-check `is_file()`; the engine's `fs::read_to_string()` fails with raw stdlib error. Always pass a single regular file.
> - **Function-not-found exit code is 1** (ContractsError::FunctionNotFound — matches `tldr contracts`, `tldr dead-stores`, `tldr chop`). Differs from `tldr complexity`/`tldr explain`/`tldr impact`/`tldr available`/`tldr reaching-defs` (exit 20).
> - **`-l <lang>` is silently IGNORED.** P21: `-l typescript` on `.py` file returns same output as default. Same anti-pattern as `tldr cohesion`/`tldr coupling`/`tldr interface`/`tldr invariants` (patterns-namespace consistency).
> - **`resource_type` observed values:** `"connection"`, `"cursor"` (from db.py exploration). Likely includes file handle, socket, lock variants per language. Filter on this field to focus.
> - **`function` field in JSON is `null` when no resources match, even if argument was supplied.** P02: passing function name still produces null `function` in output when no resources detected. Bookkeeping: track which function was supplied externally.
> - **Default `--check-leaks` is `true`.** Per source: `#[arg(long, default_value = "true")]`. The other detectors (`--check-double-close`, `--check-use-after-close`) default to false — `--check-all` enables them.
> - **NO daemon route.** Every call re-parses and re-builds CFG.
>
> **Command:** `tldr resources <FILE> [FUNCTION]`
>
> **With common flags:** `tldr resources <FILE> --check-all --suggest-context --constraints | jq '{ leaks: (.leaks | length), suggestions, constraints }'` (use for full audit with refactor hints + LLM-consumable rules).
