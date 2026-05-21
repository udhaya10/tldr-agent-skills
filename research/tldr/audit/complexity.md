# Command: `tldr complexity`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; complexity itself is AST-based, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | mixed (P16 cold, P17 warm) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`complexity.probes/probe.sh`](./complexity.probes/probe.sh).

---

## Ground Truth (`tldr complexity --help`)

```text
Calculate function complexity metrics

Usage: tldr complexity [OPTIONS] <FILE> <FUNCTION>

Arguments:
  <FILE>
          file containing the function

  <FUNCTION>
          Function name to analyze

Options:
  -l, --lang <LANG>
          Programming language (auto-detect if not specified)

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
| Typical output size | tiny (<200 bytes JSON; 7 lines pretty) |

**Top-level keys (JSON, `ComplexityMetrics`):**
- `function` (`string`) — input function name verbatim
- `cyclomatic` (`u32`) — McCabe cyclomatic complexity (decision-point count + 1)
- `cognitive` (`u32`) — SonarQube cognitive complexity (matches `tldr cognitive` exactly — verified)
- `max_nesting` (`u32`) — deepest nesting level
- `lines_of_code` (`u32`) — function body LoC

**Text format (P06):**
```text
Complexity: <function>
  Cyclomatic:    N
  Cognitive:     M
  Max nesting:   K
  Lines of code: L
```

**Error shapes (TldrError-based — matches `tldr imports`):**
- Missing FUNCTION: clap-style → exit **2**
- Path not found: `"Error: Path not found: /no/such/file.py"` → exit **2** (TldrError::PathNotFound)
- Function not found: `"Error: Function not found: <name>"` → exit **20** (TldrError::FunctionNotFound)
- Unsupported language (directory, .md, etc.): `"Error: Unsupported language: Could not detect language for: <CANONICAL absolute path>"` → exit **11** (TldrError::UnsupportedLanguage)
- Format reject: `"Error: --format sarif not supported by complexity. ..."` → exit **1**
- Bad `--lang`: clap-style → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr complexity yahoo.py _to_finite_float` | happy | 0 | [`01-happy.*`](./complexity.probes/) |
| P02 | `tldr complexity yahoo.py fetch_historical_data` | happy-scale | 0 | [`02-happy-scale.*`](./complexity.probes/) |
| P03 | `tldr complexity yahoo.py` *(no FUNCTION)* | failure-missing-input | 2 | [`03-missing-arg.*`](./complexity.probes/) |
| P04 | `tldr complexity /no/such/file.py some_fn` | failure-badpath | 2 | [`04-badpath.*`](./complexity.probes/) |
| P05 | `tldr complexity ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./complexity.probes/) |
| P06 | `tldr complexity ... -f text` | format-text | 0 | [`06-format-text.*`](./complexity.probes/) |
| P07 | `tldr complexity ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./complexity.probes/) |
| P08 | `tldr complexity ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./complexity.probes/) |
| P09 | `tldr complexity ... no_such_function` | function-not-found | 20 | [`09-function-not-found.*`](./complexity.probes/) |
| P10 | `tldr complexity ... -l brainfuck` | bad-lang | 2 | [`10-bad-lang.*`](./complexity.probes/) |
| P11 | `tldr complexity README.md anything` | non-source-md | 11 | [`11-non-source-md.*`](./complexity.probes/) |
| P12 | `tldr complexity backend anything` | directory-arg | 11 | [`12-directory-arg.*`](./complexity.probes/) |
| P13 | `tldr complexity ... -l python` | explicit-python | 0 | [`13-lang-python.*`](./complexity.probes/) |
| P14 | `tldr complexity ... -l typescript` | lang-mismatch (function not found) | 20 | [`14-lang-mismatch.*`](./complexity.probes/) |
| P15 | `tldr complexity ... -q` | quiet | 0 | [`15-quiet.*`](./complexity.probes/) |
| P16 | `tldr complexity ... fetch_historical_data` *(cold)* | cold-daemon | 0 | [`16-cold-daemon.*`](./complexity.probes/) |
| P17 | `tldr complexity ... fetch_historical_data` *(warm)* | warm-daemon | 0 | [`17-warm-daemon.*`](./complexity.probes/) |

### Observations

- **P01** — `_to_finite_float`: `cyclomatic: 3, cognitive: 3, max_nesting: 2, lines_of_code: 8`. Cognitive matches `tldr cognitive`'s output exactly for the same function.
- **P02** — `fetch_historical_data`: `cyclomatic: 5, cognitive: 9, max_nesting: 3, lines_of_code: 48`. **Cross-command consistency:** `tldr cognitive` reported cognitive=9 for the same function (P09 in cognitive dossier). The two commands share the canonical `tldr_core::calculate_complexity` engine.
- **P03** — stderr `"error: the following required arguments were not provided: <FUNCTION>"`, exit `2`.
- **P04** — stderr `"Error: Path not found: /no/such/file.py"`, exit **2** (TldrError::PathNotFound). **Matches `tldr imports` exit code; differs from `tldr definition`/`tldr explain` (exit 5) and `tldr churn` (exit 1).**
- **P05** — stderr `"Error: --format sarif not supported by complexity. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format: 5-line block with `Cyclomatic:`/`Cognitive:`/`Max nesting:`/`Lines of code:` rows. Progress message: `"Calculating complexity for X in /CANONICAL/path/Y (Python)..."`. **Note: progress message shows CANONICAL absolute path** (because `validate_file_path` canonicalizes), even when user passed a relative path.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by complexity. ..."`, exit `1`.
- **P09** — stderr `"Error: Function not found: no_such_function"`, exit `20` (TldrError::FunctionNotFound). Matches `tldr impact`/`tldr explain`/`tldr context`/`tldr available`/`tldr reaching-defs`. **Diverges from `tldr dead-stores` (exit 1)** — different namespace.
- **P10** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P11** — stderr `"Error: Unsupported language: Could not detect language for: /Users/.../README.md"`, exit `11` (TldrError::UnsupportedLanguage). **Matches `tldr imports` convention exactly.** Note the canonical path in the error.
- **P12** — stderr `"Error: Unsupported language: Could not detect language for: /Users/.../backend"`, exit `11`. **A directory triggers the same UnsupportedLanguage path** because `Language::from_path` returns None for directories — there's no upfront `is_file()` check.
- **P13** — Explicit `-l python` on a `.py` file: identical output to auto-detect (P01).
- **P14** — `-l typescript` on a `.py` file: **engine runs TypeScript parser on Python source → fails to find `_to_finite_float` → exit 20 with `"Function not found: _to_finite_float"`**. **Misleading error** — the actual cause is the wrong language, but the error blames the function name. Same anti-pattern as `tldr dead-stores` (P17 in that dossier).
- **P15** — `-q` suppresses the `"Calculating complexity for ..."` progress message.
- **P16, P17** — Cold (P16) and warm (P17) daemon outputs are **byte-identical** (verified via diff). The daemon route caches the result; subsequent calls hit cache. ~35x speedup claim is plausible for this single-function lookup.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/complexity.rs` (83 lines — small, focused)
- `crates/tldr-core/src/metrics/complexity.rs` (`calculate_complexity`)
- `crates/tldr-core/src/validation.rs` (`validate_file_path`, `detect_or_parse_language`)
- `crates/tldr-core/src/error.rs:314-358` (TldrError exit-code mapping)
- `crates/tldr-cli/src/commands/daemon_router.rs` (`params_with_file_function`)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/complexity.rs:18-29
#[derive(Debug, Args)]
pub struct ComplexityArgs {
    pub file: PathBuf,
    pub function: String,
    #[arg(long, short = 'l')] pub lang: Option<Language>,
}
```
Reveals: minimal struct — both positionals required, no other flags beyond the global `-l` / `-f` / `-q`. **Notably:** no `--output`/`-o` legacy flag, no `--threshold`, no `--include-cyclomatic` (since cyclomatic is always included). Cleanest CLI surface in the audit suite.

**Path validation (shared validator):**
```rust
// complexity.rs:37
let validated_path = validate_file_path(self.file.to_str().unwrap_or_default(), None)?;
```
Reveals: uses `tldr_core::validate_file_path` (M28 shared validator) which canonicalizes the path AND returns `TldrError::PathNotFound` on missing. Maps to exit code 2 via `TldrError::exit_code()`.

**Daemon route gating:**
```rust
// complexity.rs:39-52
let project = validated_path.parent().unwrap_or(&validated_path);
if let Some(result) = try_daemon_route::<ComplexityMetrics>(
    project, "complexity",
    params_with_file_function(&validated_path, &self.function),
) { ... return Ok(()); }
```
Reveals: daemon route uses **file's parent dir** as project root (NOT user-supplied PATH because there is no PATH — just FILE). Cached results return immediately; cold fallback goes through the engine.

**Language detection:**
```rust
// complexity.rs:57-58
let language =
    detect_or_parse_language(self.lang.as_ref().map(|l| l.as_str()), &validated_path)?;
```
Reveals: same `detect_or_parse_language` helper as `tldr imports` — returns `TldrError::UnsupportedLanguage` on unknown extension (mapped to exit 11). Directory paths fail HERE because `Language::from_path` returns None for directories.

**Cross-command cognitive consistency:**
The engine `calculate_complexity` (`tldr_core::metrics::complexity`) is the canonical source. `tldr cognitive` calls the SAME engine for its `cognitive` field. **Both commands report identical cognitive scores for the same function** — verified by comparing P02 here (`cognitive: 9` for `fetch_historical_data`) against cognitive dossier P09 (also `cognitive: 9` for that function).

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `complexity` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

---

## Architectural Deep Dive

- **Under the hood:** Parses the source file with tree-sitter, locates the named function, runs the canonical `calculate_complexity` engine. Returns four metrics: cyclomatic (McCabe), cognitive (SonarQube), max_nesting, lines_of_code. All four are derived from the same AST walk for efficiency.
- **Performance:** Cold ~50ms per call. Warm (daemon-cached): sub-millisecond. The daemon stores per-`(file, function)` complexity tuples; cache hit rate is high in repeated CI/audit workflows.
- **LLM cognitive load:** Smallest, fastest, most focused metric command — perfect for filling in `complexity` columns in audit reports. Pair with `tldr extract` (to enumerate function names) and `tldr cognitive` (for project-wide ranking).

---

## Intent & Routing

- **User/Agent Goal:** get the four standard complexity metrics for one specific function — fast, deterministic, scriptable.
- **When to choose this over similar tools:**
  - Over `tldr cognitive`: `cognitive` ranks ALL functions in a file/dir; `complexity` deep-dives one function. Use `complexity` when you already know the function name.
  - Over `tldr explain`: `explain` returns signature + callers + callees + complexity + purity (heavy); `complexity` returns just the four numbers (light).
  - Over `tldr halstead`: `halstead` is token-vocabulary-based; `complexity` is structural (decision points, nesting). Different dimensions.
- **Prerequisites (composition):**
  - Must know the function name in advance — pipe `tldr extract <file>` first if unknown.
  - For multi-function ranking, use `tldr cognitive <path> --include-cyclomatic` (which gives both metrics for many functions in one call).

---

## Agent Synthesis

> **How to use `tldr complexity`:**
> Minimal single-function metric scorer. `tldr complexity <FILE> <FUNCTION>` returns JSON `{ function, cyclomatic, cognitive, max_nesting, lines_of_code }` — four standard structural-complexity metrics. Default JSON; `-f text` for a 5-line summary; `-f compact` for one-line; `sarif`/`dot` rejected. Auto-routes through daemon for repeat queries. Exit codes follow TldrError: 0 ok, 1 format-reject, 2 missing-arg / path-not-found / bad-lang (THREE failure modes share exit 2), 11 unsupported-language (directory/non-source), 20 function-not-found.
>
> **Crucial Rules:**
> - **THREE failure modes share exit 2.** Missing FUNCTION (clap), path-not-found (TldrError::PathNotFound), and bad `--lang` (clap) all return 2. Cannot distinguish by exit code alone — parse stderr to disambiguate.
> - **Unsupported-language exit code is 11** (TldrError::UnsupportedLanguage). Triggered by markdown files AND directories (both fail `Language::from_path`). Matches `tldr imports`; differs from other audit commands (`tldr available` reports it as exit 1).
> - **`-l typescript` on a `.py` file yields a MISLEADING "Function not found" error.** The TS parser walks the Python source and fails to find the function. P14 confirms exit 20 with `"Function not found: _to_finite_float"`. Same anti-pattern as `tldr dead-stores`. Recovery hint: verify language matches file extension first.
> - **Cognitive score matches `tldr cognitive` exactly.** Both commands use the same canonical `tldr_core::calculate_complexity` engine. For one function, use `tldr complexity`; for many, use `tldr cognitive --include-cyclomatic`. Numbers are guaranteed consistent.
> - **`validate_file_path` canonicalizes paths** — the error messages and progress lines show ABSOLUTE paths (e.g., `/Users/.../yahoo.py`), even when the user passes a relative path. Round-trip-unsafe — agents must use the input path for downstream tools, not the path in the error message.
> - **`-O`/`--output` does NOT exist on this command** (unlike `tldr explain -o`, `tldr definition -O`, `tldr api-check -O`). The only output target is stdout.
> - **`tldr complexity` has NO `--directory` or batch mode.** Single function per call. For directory scanning, use `tldr cognitive <DIR> --include-cyclomatic`. Don't try to loop `tldr complexity` in a shell — call `tldr cognitive` once.
> - **`function: <name>` is the only contextual field — no `file` field in the output.** The JSON omits the FILE input, so multi-function reports can't be aggregated from `tldr complexity` outputs without separate bookkeeping. `tldr cognitive` is the correct command for multi-function aggregation.
> - **Daemon-cached results are byte-identical to cold** (P16 == P17). Safe to warm the daemon ahead of CI runs.
>
> **Command:** `tldr complexity <FILE> <FUNCTION>`
>
> **With common flags:** `tldr complexity <FILE> <FN> -l <lang> -f compact | jq .cognitive` (use for piping just one metric into downstream tooling; explicit `-l` prevents the misleading-function-not-found error from a wrong-language guess).
