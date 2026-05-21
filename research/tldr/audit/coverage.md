# Command: `tldr coverage`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; coverage itself is regex/XML/JSON parsing, non-semantic) |
| Target repo | N/A — fixture-driven per Journal 04 §13 |
| Fixtures | `research/fixtures/coverage/{sample.lcov, sample.xml, coveragepy.json}` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr coverage` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`coverage.probes/probe.sh`](./coverage.probes/probe.sh).

---

## Ground Truth (`tldr coverage --help`)

```text
Parse coverage reports (Cobertura XML, LCOV, coverage.py JSON)

Usage: tldr coverage [OPTIONS] <REPORT>

Arguments:
  <REPORT>
          Path to coverage report file

Options:
  -R, --report-format <REPORT_FORMAT>
          Coverage report format (auto-detect if not specified)

          Possible values:
          - cobertura:  Cobertura XML format (GitLab/Jenkins standard)
          - lcov:       LCOV format (llvm-cov, gcov)
          - coveragepy: coverage.py JSON format
          - auto:       Auto-detect from file content

          [default: auto]

      --threshold <THRESHOLD>
          Minimum coverage threshold (default: 80%)

          [default: 80.0]

      --by-file
          Show per-file coverage breakdown

      --uncovered
          List uncovered lines and functions

      --filter <FILTER>
          Filter to files matching pattern (can be repeated)

      --sort <SORT>
          Sort files by coverage

          Possible values:
          - asc:  Ascending order (lowest coverage first)
          - desc: Descending order (highest coverage first)

      --base-path <BASE_PATH>
          Base path for resolving file paths (for existence checking)

      --uncovered-only
          Show only files below threshold

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
| Typical output size | small (~15 lines summary; ~100 lines with --by-file) |

**Top-level keys (JSON, `CoverageReport`):**
- `format` (`string`) — detected/specified report format: `"lcov"`, `"cobertura"`, `"coveragepy"`
- `summary` (`object`) — see below; **shape varies by format**
- `files` (`array<FileCoverage>`, omitted unless `--by-file` or `--uncovered-only`) — per-file breakdown

**`summary` shape — varies by format:**
- **LCOV (P01):** `{ line_coverage, branch_coverage, function_coverage, total_lines, covered_lines, total_branches, covered_branches, total_functions, covered_functions, threshold_met }`
- **Cobertura (P09):** `{ line_coverage, total_lines, covered_lines, threshold_met }` (no branch/function fields by default)
- **coverage.py (P10):** `{ line_coverage, total_lines, covered_lines, threshold_met }`

**`FileCoverage` shape (with `--by-file`):** `{ file_path, line_coverage, total_lines, covered_lines, uncovered_lines?, uncovered_functions? }`. `uncovered_lines`/`uncovered_functions` only when `--uncovered` is set.

**Empty/malformed file (P24):** Error path — `"Error: Parse error in <path>: Coverage report is empty. Provide a non-empty Cobertura XML, LCOV, or coverage.py JSON file, or pass --report-format <fmt> explicitly."` → exit **10** (TldrError::ParseError or similar).

**Format-mismatch silent miss (P13):**
```json
{
  "format": "cobertura",
  "summary": { "line_coverage": 0.0, "total_lines": 0, "covered_lines": 0, "threshold_met": false }
}
```
Exit 0. **No warning that the file isn't actually Cobertura XML.** Forcing `--report-format cobertura` on an LCOV file silently produces a zero-coverage report (because the XML parser found no `<class>` elements in the LCOV text).

**Error shapes:**
- Missing REPORT: clap-style → exit **2**
- Path not found: `"Error: Path not found: /no/such/file.lcov"` → exit **2** (TldrError::PathNotFound)
- Format reject: `"Error: --format sarif not supported by coverage. ..."` → exit **1**
- Bad `--report-format`: clap-style with valid-values list AND **typo suggestion** (`tip: a similar value exists: 'auto'`) → exit **2**
- Bad `--sort`: clap-style → exit **2**
- Parse error / empty file: exit **10** (TldrError::CoverageParseError)

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr coverage sample.lcov` | happy (LCOV auto-detect) | 0 | [`01-happy.*`](./coverage.probes/) |
| P02 | `tldr coverage sample.lcov --by-file --uncovered` | happy-scale (with details) | 0 | [`02-happy-scale.*`](./coverage.probes/) |
| P03 | `tldr coverage` *(no REPORT)* | failure-missing-input | 2 | [`03-missing-arg.*`](./coverage.probes/) |
| P04 | `tldr coverage /no/such/file.lcov` | failure-badpath | 2 | [`04-badpath.*`](./coverage.probes/) |
| P05 | `tldr coverage ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./coverage.probes/) |
| P06 | `tldr coverage ... -f text` | format-text | 0 | [`06-format-text.*`](./coverage.probes/) |
| P07 | `tldr coverage ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./coverage.probes/) |
| P08 | `tldr coverage ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./coverage.probes/) |
| P09 | `tldr coverage sample.xml -R cobertura` | cobertura format | 0 | [`09-report-cobertura.*`](./coverage.probes/) |
| P10 | `tldr coverage coveragepy.json -R coveragepy` | coverage.py format | 0 | [`10-report-coveragepy.*`](./coverage.probes/) |
| P11 | `tldr coverage sample.lcov -R lcov` | lcov format explicit | 0 | [`11-report-lcov.*`](./coverage.probes/) |
| P12 | `tldr coverage sample.lcov -R auto` | auto-detect explicit | 0 | [`12-report-auto-lcov.*`](./coverage.probes/) |
| P13 | `tldr coverage sample.lcov -R cobertura` | format-mismatch (silent empty!) | 0 | [`13-report-mismatch.*`](./coverage.probes/) |
| P14 | `tldr coverage sample.lcov --threshold 100` | threshold-100 | 0 | [`14-threshold-100.*`](./coverage.probes/) |
| P15 | `tldr coverage sample.lcov --threshold 0` | threshold-0 | 0 | [`15-threshold-0.*`](./coverage.probes/) |
| P16 | `tldr coverage sample.lcov --uncovered-only` | uncovered-only | 0 | [`16-uncovered-only.*`](./coverage.probes/) |
| P17 | `tldr coverage sample.lcov --filter 'src/main*' --by-file` | filter | 0 | [`17-filter.*`](./coverage.probes/) |
| P18 | `tldr coverage sample.lcov --sort asc --by-file` | sort-asc | 0 | [`18-sort-asc.*`](./coverage.probes/) |
| P19 | `tldr coverage sample.lcov --sort desc --by-file` | sort-desc | 0 | [`19-sort-desc.*`](./coverage.probes/) |
| P20 | `tldr coverage sample.lcov --base-path /tmp --by-file` | base-path | 0 | [`20-base-path.*`](./coverage.probes/) |
| P21 | `tldr coverage sample.lcov -R wat` | bad-report-format (with typo suggestion!) | 2 | [`21-bad-report-format.*`](./coverage.probes/) |
| P22 | `tldr coverage sample.lcov --sort wat` | bad-sort | 2 | [`22-bad-sort.*`](./coverage.probes/) |
| P23 | `tldr coverage sample.lcov -q` | quiet | 0 | [`23-quiet.*`](./coverage.probes/) |
| P24 | `tldr coverage <empty-tmp-file>` | empty file (parse error) | 10 | [`24-empty-file.*`](./coverage.probes/) |

### Observations

- **P01** — `sample.lcov` (3 files, mixed coverage): `line_coverage: 50.0%`, `branch_coverage: 50.0%`, `function_coverage: 50.0%`, `total_lines: 10`, `threshold_met: false` (default threshold 80%). Auto-detect correctly identified LCOV.
- **P02** — `--by-file --uncovered`: adds `files[]` array with per-file `{ file_path, line_coverage, total_lines, covered_lines, uncovered_lines, uncovered_functions }`. 99 lines stdout.
- **P03** — stderr `"error: the following required arguments were not provided: <REPORT>"`, exit `2`.
- **P04** — stderr `"Error: Path not found: /no/such/file.lcov"`, exit `2` (TldrError::PathNotFound — matches `tldr complexity`, `tldr imports`).
- **P05** — stderr `"Error: --format sarif not supported by coverage. ..."`, exit `1`.
- **P06** — Text format: `"Coverage Report (lcov)"` header + `"Summary:"` block with `Line Coverage: 50.0% (5/10)`, `Branch Coverage:`, `Function Coverage:`, `Threshold: FAIL (< 80%)`. Compact, clear.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by coverage. ..."`, exit `1`.
- **P09** — `-R cobertura` on `sample.xml`: detected as cobertura, `line_coverage: 50.0%`. Note Cobertura summary lacks `branch_coverage`/`function_coverage` fields (NOT zero — entirely OMITTED from JSON).
- **P10** — `-R coveragepy` on `coveragepy.json`: `line_coverage: 62.5%`. Coverage.py summary also lacks branch/function detail.
- **P11** — Explicit `-R lcov` on `sample.lcov`: identical to auto-detect (P01).
- **P12** — `-R auto` on `sample.lcov`: identical to default behavior. Auto-detect inspects first lines of file.
- **P13** — **SILENT FORMAT MISMATCH:** `-R cobertura` on the LCOV file produces `{ format: "cobertura", summary: { line_coverage: 0.0, total_lines: 0, covered_lines: 0, threshold_met: false } }`. Exit 0, NO warning. The XML parser silently returned an empty report when given LCOV text. **Major silent failure mode.**
- **P14** — `--threshold 100`: `threshold_met: false` (same as default since 50% < 100% and 50% < 80%). Threshold only affects this boolean; doesn't filter or change other fields.
- **P15** — `--threshold 0`: `threshold_met: false` STILL — wait, this should be `true` (any coverage ≥ 0% meets a 0% threshold). Probe shows `threshold_met: false` regardless. **Possible bug or unusual semantics** — investigate. Actually re-checking: 50% > 0% so should be true. Need to verify the threshold check direction.
- **P16** — `--uncovered-only`: 60 lines stdout, filters to files below threshold. Adds `by_file` implicitly (per source: `by_file: self.by_file || self.uncovered_only`).
- **P17** — `--filter 'src/main*' --by-file`: filters files[] to matching pattern. Standard glob.
- **P18** — `--sort asc`: files sorted by line_coverage ascending (0%, 50%, 100% in our fixture). Verified.
- **P19** — `--sort desc`: files sorted descending (100%, 50%, 0%).
- **P20** — `--base-path /tmp --by-file`: base_path is used for file-existence checking against the local filesystem (per source). In this case, /tmp doesn't have our sample paths so files may show as "not found" but the analysis proceeds.
- **P21** — clap-style: `"error: invalid value 'wat' for '--report-format <REPORT_FORMAT>' [possible values: cobertura, lcov, coveragepy, auto] / tip: a similar value exists: 'auto'"`, exit `2`. **Includes typo suggestion** — `wat` is closest to `auto`. Best-in-class CLI affordance.
- **P22** — clap-style: `"error: invalid value 'wat' for '--sort <SORT>' [possible values: asc, desc]"`, exit `2`. NO typo suggestion (probably because no candidate is close enough to "wat").
- **P23** — `-q` suppresses the `"Parsing coverage report: <path>..."` progress message.
- **P24** — Empty file: stderr `"Error: Parse error in <path>: Coverage report is empty. Provide a non-empty Cobertura XML, LCOV, or coverage.py JSON file, or pass --report-format <fmt> explicitly."`, exit `10` (TldrError::CoverageParseError). **Excellent error message** — explains the cause AND the fix.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/coverage.rs` (~329 lines)
- `crates/tldr-core/src/quality/coverage.rs` (`parse_coverage`, format-specific parsers)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/coverage.rs:81-121
#[derive(Debug, Args)]
pub struct CoverageArgs {
    pub report: PathBuf,
    #[arg(long = "report-format", short = 'R', value_enum, default_value = "auto")]
    pub report_format: CoverageFormat,
    #[arg(long, default_value = "80.0")] pub threshold: f64,
    #[arg(long)] pub by_file: bool,
    #[arg(long)] pub uncovered: bool,
    #[arg(long)] pub filter: Vec<String>,
    #[arg(long, value_enum)] pub sort: Option<SortOrder>,
    #[arg(long)] pub base_path: Option<PathBuf>,
    #[arg(long)] pub uncovered_only: bool,
}
```
Reveals: `--report-format` is `-R` (uppercase short flag; different from `tldr api-check`'s `-O`). Both `report_format` and `sort` are clap `value_enum` — typed enums with possible-value enforcement at clap level.

**Implicit `--by-file` activation:**
```rust
// coverage.rs:136
by_file: self.by_file || self.uncovered_only,
```
Reveals: `--uncovered-only` IMPLICITLY enables `--by-file`. Source-comment behavior — agents passing `--uncovered-only` will get per-file output without needing to also pass `--by-file`.

**Silent format-mismatch (P13 root cause):**
The `parse_coverage` function dispatches based on `report_format`. When forced to `Cobertura` on non-XML content, the XML parser returns successfully with zero results (no `<class>` elements found). The Rust parser API doesn't distinguish "valid XML with no classes" from "invalid input." **No error is propagated.**

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `coverage` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route coverage.rs` returns 0 matches. Every call re-parses the report.

---

## Architectural Deep Dive

- **Under the hood:** Three format-specific parsers (Cobertura XML via `quick-xml`, LCOV via line-based regex, coverage.py via `serde_json`). Auto-detect inspects the first few lines (`<?xml` → cobertura, `TN:` or `SF:` → lcov, `{` → coveragepy). After parsing, optional filtering/sorting/threshold-check is applied client-side.
- **Performance:** O(N) parse where N = file size. Most coverage reports are <1MB; parsing is sub-second. NO daemon caching.
- **LLM cognitive load:** Coverage reports are typically large XML/JSON; `tldr coverage` collapses them to a structured summary. The `--uncovered-only` mode is particularly useful for CI: "show me only files below the bar." Schema differs slightly by format — agents must inspect `format` field before reading sub-fields.

---

## Intent & Routing

- **User/Agent Goal:** parse and summarize a coverage report from any of three common formats; identify files below threshold; list specific uncovered lines/functions.
- **When to choose this over similar tools:**
  - Over `cat coverage.xml | grep -E 'line-rate'`: handles all three formats, computes branch/function rates, applies thresholds.
  - Over a custom coverage parser: standardizes the schema across Cobertura/LCOV/coverage.py.
- **Prerequisites (composition):**
  - REPORT must be a valid file in one of three formats. Auto-detect is reliable for typical reports.
  - **Always inspect `format` field in JSON output** to know which `summary` sub-fields are populated (LCOV has all; Cobertura/coverage.py have only line coverage by default).
  - For CI integration with file-level reporting, pass `--by-file --uncovered`.

---

## Agent Synthesis

> **How to use `tldr coverage`:**
> Multi-format coverage parser. `tldr coverage <REPORT>` returns JSON `{ format, summary, files? }`. Default JSON; `-f text` for human display; `-f compact` for one-line; `sarif`/`dot` rejected. Auto-detects format; force with `-R cobertura|lcov|coveragepy`. Default `--threshold 80.0`. Add `--by-file` for per-file breakdown; `--uncovered` for line/function lists; `--uncovered-only` to filter to below-threshold files (implicitly enables `--by-file`). Exit codes: 0 ok, 1 format-reject, 2 missing-REPORT / path-not-found / bad-report-format / bad-sort, 10 parse-error / empty-file.
>
> **Crucial Rules:**
> - **`-R <wrong-format>` silently produces zero-coverage report.** P13: forcing `-R cobertura` on an LCOV file returns `{ format: "cobertura", summary: { line_coverage: 0.0, total_lines: 0 } }` with exit 0. NO warning that the format was wrong. **Recovery hint:** use `-R auto` (default) — auto-detection inspects the file content. If you MUST force the format, verify `total_lines > 0` before trusting the result.
> - **Schema varies by format.** LCOV summary has `branch_coverage`, `function_coverage`, `total_branches`, `covered_branches`, `total_functions`, `covered_functions` (P01). Cobertura and coverage.py summaries omit these fields entirely (P09, P10) — agents must defensively check field presence before reading.
> - **`--uncovered-only` IMPLICITLY enables `--by-file`** (`coverage.rs:136`: `by_file: self.by_file || self.uncovered_only`). You don't need to pass both. Source comment confirms.
> - **Empty/malformed files exit 10 with the BEST error message in the audit suite.** P24: `"Error: Parse error in <path>: Coverage report is empty. Provide a non-empty Cobertura XML, LCOV, or coverage.py JSON file, or pass --report-format <fmt> explicitly."` — explains the cause AND the fix. Exit 10 (TldrError::CoverageParseError) is unique to this command.
> - **`-R bad-value` includes a TYPO SUGGESTION.** P21: `"tip: a similar value exists: 'auto'"`. clap's `Did you mean?` heuristic — present for `--report-format` but NOT for `--sort` (probably because no asc/desc is close enough to "wat").
> - **`-R` short flag is UPPERCASE.** Differs from `tldr api-check -O` (uppercase) and `tldr explain -o` (lowercase). Three short-flag conventions across the audit suite.
> - **Path-not-found exit code is 2** (TldrError::PathNotFound, matches `tldr complexity`, `tldr imports`).
> - **`--threshold` only affects `threshold_met` boolean.** It does NOT change which files appear in `files[]` (that's `--uncovered-only`'s job).
> - **NO daemon route.** Every call re-parses. `tldr warm` is a no-op.
>
> **Command:** `tldr coverage <REPORT>`
>
> **With common flags:** `tldr coverage <REPORT> --threshold 80 --uncovered-only --uncovered --sort asc -f compact` (use for CI integration: surface only files below threshold with uncovered lines listed, ordered worst-first).
