# Command: `tldr halstead`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; halstead is AST-based, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr halstead` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`halstead.probes/probe.sh`](./halstead.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/audit/halstead.md).

---

## Ground Truth (`tldr halstead --help`)

```text
Calculate Halstead complexity metrics per function

Usage: tldr halstead [OPTIONS] [PATH]

Arguments:
  [PATH]
          File or directory to analyze

          [default: .]

Options:
      --function <FUNCTION>
          Specific function to analyze (analyzes all if not specified)

  -l, --lang <LANG>
          Programming language (auto-detect if not specified)

      --show-operators
          Show list of operators found

      --show-operands
          Show list of operands found

      --threshold-volume <THRESHOLD_VOLUME>
          Volume threshold for warnings (default: 1000)

          [default: 1000]

      --threshold-difficulty <THRESHOLD_DIFFICULTY>
          Difficulty threshold for warnings (default: 20)

          [default: 20]

      --top <TOP>
          Maximum functions to report (0 = all)

          [default: 0]

  -e, --exclude <EXCLUDE>
          Exclude patterns (glob syntax), can be specified multiple times

      --include-hidden
          Include hidden files (dotfiles)

      --max-files <MAX_FILES>
          Maximum files to process (0 = unlimited)

          [default: 0]

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
| Typical output size | medium (~220 lines for one file) to heavy (~600 lines for a small dir) |

**Top-level keys (JSON, `HalsteadReport`):**
- `functions` (`array<FunctionMetrics>`) — per-function Halstead metrics
- `violations` (`array<FunctionMetrics>`) — subset exceeding `--threshold-volume` OR `--threshold-difficulty`
- `summary` (`object`) — `{ total_functions, avg_volume, avg_difficulty, avg_effort, total_estimated_bugs, violations_count }`
- `warnings` (`array<string>`, omitted unless walk produced warnings) — present for lang-mismatch (P21), but NOT for empty-dir (P23) or function-not-found (P10)

**`FunctionMetrics` shape:**
- `name` (`string`)
- `file` (`string`) — project-relative path
- `line` (`u32`)
- `metrics` (`object`) — `{ n1, n2, N1, N2, vocabulary, length, volume, difficulty, effort, time, bugs }` (Halstead's classic measures)
- `operators` (`array<string>`, **omitted** unless `--show-operators`) — list of operator tokens found
- `operands` (`array<string>`, **omitted** unless `--show-operands`) — list of operand tokens found
- `status` (`string`) — `"good"`, `"warning"`, `"bad"` based on thresholds

**Silent-empty modes (THREE shapes, same as `tldr cognitive`):**
1. **Function not found (P10):** `{ functions: [], violations: [], summary: {zeros}, NO warnings }`
2. **Empty directory (P23):** Same shape as P10, NO warnings
3. **Language mismatch (P21):** Same shape PLUS `warnings: ["No supported source files found in <path>"]`

**Error shapes:**
- Path does not exist: `"Error: Path does not exist: /no/such/dir"` → exit **1** (matches `tldr cognitive`)
- Format reject: `"Error: --format sarif not supported by halstead. ..."` → exit **1**
- Non-source single file (`.md`): `"Error: Unsupported language: Could not detect language for: README.md"` → exit **11** (TldrError::UnsupportedLanguage — distinct from `tldr cognitive`'s silent fallback)
- Bad `--lang`: clap-style → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr halstead yahoo.py` | happy (single file) | 0 | [`01-happy.*`](./halstead.probes/) |
| P02 | `tldr halstead backend/providers` | happy-scale (directory) | 0 | [`02-happy-scale.*`](./halstead.probes/) |
| P03 | N/A: PATH defaults to `.`. | — | — | [`03-missing-arg.*`](./halstead.probes/) (placeholder) |
| P04 | `tldr halstead /no/such/dir` | failure-badpath | 1 | [`04-badpath.*`](./halstead.probes/) |
| P05 | `tldr halstead ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./halstead.probes/) |
| P06 | `tldr halstead ... -f text` | format-text | 0 | [`06-format-text.*`](./halstead.probes/) |
| P07 | `tldr halstead ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./halstead.probes/) |
| P08 | `tldr halstead ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./halstead.probes/) |
| P09 | `tldr halstead ... --function fetch_historical_data` | function-filter | 0 | [`09-function.*`](./halstead.probes/) |
| P10 | `tldr halstead ... --function no_such_function` | function-not-found (silent) | 0 | [`10-function-not-found.*`](./halstead.probes/) |
| P11 | `tldr halstead ... --show-operators` | show-operators | 0 | [`11-show-operators.*`](./halstead.probes/) |
| P12 | `tldr halstead ... --show-operands` | show-operands | 0 | [`12-show-operands.*`](./halstead.probes/) |
| P13 | `tldr halstead ... --threshold-volume 0` | all violations (volume) | 0 | [`13-threshold-vol-zero.*`](./halstead.probes/) |
| P14 | `tldr halstead ... --threshold-difficulty 0` | all violations (difficulty) | 0 | [`14-threshold-diff-zero.*`](./halstead.probes/) |
| P15 | `tldr halstead backend --top 1` | top-one | 0 | [`15-top-one.*`](./halstead.probes/) |
| P16 | `tldr halstead ... --top 0` | top-zero (all) | 0 | [`16-top-zero.*`](./halstead.probes/) |
| P17 | `tldr halstead ... --exclude '__init__.py'` | exclude-glob | 0 | [`17-exclude.*`](./halstead.probes/) |
| P18 | `tldr halstead ... --max-files 1` | max-files cap | 0 | [`18-max-files-low.*`](./halstead.probes/) |
| P19 | `tldr halstead ... --include-hidden` | include-hidden | 0 | [`19-include-hidden.*`](./halstead.probes/) |
| P20 | `tldr halstead ... -l brainfuck` | bad-lang | 2 | [`20-bad-lang.*`](./halstead.probes/) |
| P21 | `tldr halstead ... -l typescript` | lang-mismatch (with warning) | 0 | [`21-lang-mismatch.*`](./halstead.probes/) |
| P22 | `tldr halstead ... -q` | quiet | 0 | [`22-quiet.*`](./halstead.probes/) |
| P23 | `tldr halstead <empty-tmp-dir>` | empty-dir (no warning) | 0 | [`23-empty-dir.*`](./halstead.probes/) |
| P24 | `tldr halstead README.md` | non-source-md (exit 11) | 11 | [`24-non-source-md.*`](./halstead.probes/) |

### Observations

- **P01** — `yahoo.py`: 7 functions analyzed. Top function `fetch_intraday_chart` (line 87): `n1: 37, n2: 71, N1: 112, N2: 122, vocabulary: 108, length: 234, volume: 1580.64, difficulty: 31.79`. Standard Halstead software-science metrics.
- **P02** — `backend/providers/` (4 files): 23 functions, summary `avg_volume: 528.66, avg_difficulty: 13.70, avg_effort: 17472.94, total_estimated_bugs: 4.053, violations_count: 11`.
- **P03** — **N/A.** PATH defaults to `.`.
- **P04** — stderr `"Error: Path does not exist: /no/such/dir"`, exit `1`. Matches `tldr cognitive`'s wording.
- **P05** — stderr `"Error: --format sarif not supported by halstead. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format renders a tabular display: `Name | n1 | n2 | Volume | Difficulty | Effort | Status` columns. Summary header + violations count. Clean.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by halstead. ..."`, exit `1`.
- **P09** — `--function fetch_historical_data`: filters to one function. `functions[]` has one entry with full metrics.
- **P10** — **Silent empty:** `--function no_such_function` returns `{ functions: [], violations: [], summary: {zeros}, NO warnings }`. Exit 0. Agents must check `summary.total_functions > 0`.
- **P11** — `--show-operators` adds `operators: [...]` array per function. Each entry is a string operator name (e.g., `"return"`, `"try"`, `"subscript"`).
- **P12** — `--show-operands` adds `operands: [...]` array per function. String operand names.
- **P13** — `--threshold-volume 0`: every function exceeds volume threshold → all are violations. 723 lines stdout.
- **P14** — `--threshold-difficulty 0`: every function exceeds difficulty threshold → all violations. 716 lines.
- **P15** — `--top 1`: 1 function in `functions[]`. Summary unchanged.
- **P16** — `--top 0` (all): identical to P02 (default --top is also 0 per --help).
- **P17** — `--exclude '__init__.py'`: filters out `__init__.py`. Output slightly smaller (575 lines vs 597).
- **P18** — `--max-files 1`: limits to 1 file analyzed. Smaller output.
- **P19** — `--include-hidden`: same as default in this scope (no dotfiles present).
- **P20** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P21** — **Silent-with-warning:** `-l typescript` on Python-only dir: `{ functions: [], violations: [], summary: {zeros}, warnings: ["No supported source files found in backend/providers"] }`. Exit 0. Same `warnings`-as-signal pattern as `tldr cognitive`.
- **P22** — `-q` suppresses the `"Calculating Halstead metrics for N files in <path>..."` progress message.
- **P23** — Empty dir: same empty shape as P10, NO `warnings` field.
- **P24** — **DIFFERS from `tldr cognitive`:** Non-Python single FILE returns exit **11** (TldrError::UnsupportedLanguage) instead of empty result. `tldr cognitive README.md` returned empty + null language with exit 0; `tldr halstead README.md` errors clearly. **Better UX** — explicit error rather than silent.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/halstead.rs` (~292 lines)
- `crates/tldr-core/src/metrics/halstead.rs` (`analyze_halstead`, `merge_halstead_reports`)
- `crates/tldr-core/src/validation.rs` (`validate_file_path`, `detect_or_parse_language`)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/halstead.rs:24-69
#[derive(Debug, Args)]
pub struct HalsteadArgs {
    #[arg(default_value = ".")] pub path: PathBuf,
    #[arg(long)] pub function: Option<String>,
    #[arg(long, short = 'l')] pub lang: Option<Language>,
    #[arg(long)] pub show_operators: bool,
    #[arg(long)] pub show_operands: bool,
    #[arg(long, default_value = "1000")] pub threshold_volume: f64,
    #[arg(long, default_value = "20")] pub threshold_difficulty: f64,
    #[arg(long, default_value = "0")] pub top: usize,
    #[arg(long, short = 'e')] pub exclude: Vec<String>,
    #[arg(long)] pub include_hidden: bool,
    #[arg(long, default_value = "0")] pub max_files: usize,
}
```
Reveals: `--top 0` and `--max-files 0` both mean "unlimited" — consistent with `tldr cognitive`. Two threshold flags (`--threshold-volume` and `--threshold-difficulty`); a function in violation hits EITHER threshold.

**Three-way path dispatch:**
```rust
// halstead.rs:85-106
let report = if self.path.is_file() {
    // Single file
} else if self.path.is_dir() {
    // Directory walk
} else {
    return Err(anyhow::anyhow!("Path does not exist: {}", self.path.display()));
};
```
Reveals: same structure as `tldr cognitive`. Non-Python single FILE goes through `analyze_halstead` which calls `detect_or_parse_language`. That returns `TldrError::UnsupportedLanguage` (exit 11) for `.md` files (P24). **Distinct from cognitive's empty-result-silent-fallback path.**

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `halstead` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route halstead.rs` returns 0 matches.

---

## Architectural Deep Dive

- **Under the hood:** Walks the AST per function, classifies each token as operator or operand. Counts `n1` (unique operators), `n2` (unique operands), `N1` (total operators), `N2` (total operands). Derives the classic Halstead measures: `vocabulary = n1+n2`, `length = N1+N2`, `volume = length * log2(vocabulary)`, `difficulty = (n1/2) * (N2/n2)`, `effort = volume * difficulty`, `bugs = volume / 3000`, `time = effort / 18`.
- **Performance:** Cold ~50-100ms per file × N files. NO daemon caching.
- **LLM cognitive load:** Halstead is token-vocabulary based; complements `tldr complexity` (decision-points) and `tldr cognitive` (nesting). Use Halstead's `bugs` estimate as a sanity check for which functions warrant additional testing. The `--show-operators`/`--show-operands` flags expose the raw token classification for debugging unexpected scores.

---

## Intent & Routing

- **User/Agent Goal:** quantify function complexity along the vocabulary/length axis (Halstead software science). Predict bug count via the `bugs` formula. Find functions that exceed volume/difficulty thresholds.
- **When to choose this over similar tools:**
  - Over `tldr complexity`: complexity is structural (cyclomatic); halstead is lexical (tokens). Different complexity dimensions.
  - Over `tldr cognitive`: cognitive penalizes nesting; halstead doesn't care about nesting.
  - Over `tldr debt`: debt aggregates many rules into minutes; halstead is a single-metric per-function view.
- **Prerequisites (composition):**
  - For mixed-language projects, pass `-l <lang>` explicitly — `-l typescript` on Python yields a clear "no supported source files" warning (P21).
  - For visibility into WHY a function has high volume/difficulty, use `--show-operators --show-operands` to inspect the token classification.

---

## Agent Synthesis

> **How to use `tldr halstead`:**
> Token-vocabulary complexity scorer. `tldr halstead [PATH]` returns JSON `{ functions, violations, summary, warnings? }`. Each `FunctionMetrics` has `name, file, line, metrics: { n1, n2, N1, N2, vocabulary, length, volume, difficulty, effort, time, bugs }`, plus optional `operators[]` (with `--show-operators`) and `operands[]` (with `--show-operands`). Violation = exceeds `--threshold-volume 1000` OR `--threshold-difficulty 20`. Default JSON; `-f text` for table; `-f compact` for one-line; `sarif`/`dot` rejected. Exit codes: 0 ok (including silent empties), 1 path-does-not-exist / format-reject, 2 bad-lang, 11 unsupported-language (non-source single FILE).
>
> **Crucial Rules:**
> - **THREE silent-empty modes** (mirror `tldr cognitive`): function-not-found (P10), empty-dir (P23), and lang-mismatch (P21). Only the lang-mismatch case includes `warnings: ["No supported source files found in <path>"]`. P10/P23 have NO warnings field. The warning is the ONLY way to disambiguate.
> - **Non-source single FILE returns exit 11** (P24) — DIFFERS from `tldr cognitive` which silently returns empty. `tldr halstead README.md` errors clearly with `"Unsupported language: Could not detect language for: README.md"`. Better UX than cognitive's silent fallback.
> - **`--top 0` AND `--max-files 0` both mean "unlimited"** (consistent with `tldr cognitive`).
> - **`--show-operators` and `--show-operands` are additive fields.** When NOT set, `operators[]` and `operands[]` are OMITTED entirely (not null). Defensive parsing: check field presence before accessing.
> - **Violation triggers on EITHER threshold.** `--threshold-volume 0 --threshold-difficulty 20` would flag every function since `volume > 0` for any real function. P13/P14 confirm independent thresholds.
> - **Path-does-not-exist wording is "Path does not exist:"** (matches `tldr cognitive`; differs from `tldr churn` "Path not found:", `tldr available` "File not found:", `tldr chop` "file not found:" lowercase).
> - **NO daemon route.** Every call walks + parses. `tldr warm` is a no-op.
> - **`bugs` field in metrics is the actionable prediction.** Halstead's classic `bugs ≈ volume / 3000` formula; useful for "where should I add more tests?"
>
> **Command:** `tldr halstead [PATH]`
>
> **With common flags:** `tldr halstead <PATH> -l <lang> --threshold-volume 500 --threshold-difficulty 15 --top 10 --show-operators -f compact` (use for high-signal violation list with operator detail for refactor planning).
