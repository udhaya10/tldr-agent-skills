# Command: `tldr cognitive`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; cognitive itself is AST-based, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr cognitive` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`cognitive.probes/probe.sh`](./cognitive.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/audit/cognitive.md).

---

## Ground Truth (`tldr cognitive --help`)

```text
Calculate cognitive complexity for functions (SonarQube algorithm)

Usage: tldr cognitive [OPTIONS] [PATH]

Arguments:
  [PATH]
          File or directory to analyze

          [default: .]

Options:
      --function <FUNCTION>
          Specific function to analyze (analyzes all if not specified) Note: --function is the long form; -f short flag is NOT used to avoid collision with --format

  -l, --lang <LANG>
          Programming language (auto-detect if not specified)

      --threshold <THRESHOLD>
          Complexity threshold for violations (default: 15)

          [default: 15]

      --high-threshold <HIGH_THRESHOLD>
          High threshold for severe violations (default: 25)

          [default: 25]

      --show-contributors
          Show line-by-line complexity contributors

      --include-cyclomatic
          Include cyclomatic complexity comparison

      --top <TOP>
          Maximum functions to report (0 = all)

          [default: 50]

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
| Typical output size | medium (~70 lines for one file with 5 funcs; ~220 lines for a small dir) |

**Top-level keys (JSON, `CognitiveReport`):**
- `functions` (`array<FunctionCognitive>`) — per-function metrics, sorted descending by `cognitive`, truncated to `--top` (default 50)
- `violations` (`array<FunctionCognitive>`) — subset of `functions` where `cognitive > --threshold`
- `summary` (`object`) — `{ total_functions, total_cognitive, avg_cognitive, max_cognitive, violations_count, severe_violations_count, compliance_rate }`
- `warnings` (`array<string>`, omitted unless walk produced warnings) — present when lang filter excludes all files (P22), but NOT for empty-dir (P24) or function-not-found (P10) cases

**`FunctionCognitive` shape:**
- `name` (`string`) — function name; methods may include class prefix
- `file` (`string`) — project-relative path
- `line` (`u32`) — definition line
- `cognitive` (`u32`) — SonarQube cognitive complexity score
- `max_nesting` (`u32`) — deepest nesting level reached
- `nesting_penalty` (`u32`) — portion of `cognitive` attributable to nesting
- `threshold_status` (`string`) — `"ok"`, `"warning"` (above threshold), `"severe"` (above high_threshold)
- `cyclomatic` (`u32`, **omitted** unless `--include-cyclomatic`)
- `contributors` (`array<Contributor>`, **omitted** unless `--show-contributors`) — `{ line, construct, base_increment, nesting_increment, nesting_level }`

**Silent-empty modes** — THREE distinct cases, all exit 0:
1. **Function not found (P10):** `{ functions: [], violations: [], summary: {zeros}, NO warnings }`
2. **Empty directory (P24):** Same shape as P10, NO warnings
3. **Language mismatch (P22):** `{ functions: [], violations: [], summary: {zeros}, warnings: ["No supported source files found in <path>"] }`

**Error shapes:**
- Path does not exist: `"Error: Path does not exist: /no/such/dir"` → exit **1** (anyhow! — note "Path does not exist:" wording, distinct from `tldr churn`'s "Path not found:")
- Format reject: `"Error: --format sarif not supported by cognitive. ..."` → exit **1**
- Bad `--lang`: clap-style → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr cognitive backend/providers/yahoo.py` | happy (single file) | 0 | [`01-happy.*`](./cognitive.probes/) |
| P02 | `tldr cognitive backend/providers` | happy-scale (directory) | 0 | [`02-happy-scale.*`](./cognitive.probes/) |
| P03 | N/A: PATH defaults to `.`. | — | — | [`03-missing-arg.*`](./cognitive.probes/) (placeholder) |
| P04 | `tldr cognitive /no/such/dir` | failure-badpath | 1 | [`04-badpath.*`](./cognitive.probes/) |
| P05 | `tldr cognitive ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./cognitive.probes/) |
| P06 | `tldr cognitive ... -f text` | format-text | 0 | [`06-format-text.*`](./cognitive.probes/) |
| P07 | `tldr cognitive ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./cognitive.probes/) |
| P08 | `tldr cognitive ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./cognitive.probes/) |
| P09 | `tldr cognitive ... --function fetch_historical_data` | function-filter | 0 | [`09-function.*`](./cognitive.probes/) |
| P10 | `tldr cognitive ... --function no_such_function` | function-not-found (silent) | 0 | [`10-function-not-found.*`](./cognitive.probes/) |
| P11 | `tldr cognitive ... --threshold 0` | threshold-zero (all violations) | 0 | [`11-threshold-zero.*`](./cognitive.probes/) |
| P12 | `tldr cognitive ... --threshold 9999` | threshold-high (no violations) | 0 | [`12-threshold-high.*`](./cognitive.probes/) |
| P13 | `tldr cognitive ... --high-threshold 5 --threshold 1` | high-threshold-low | 0 | [`13-high-threshold-low.*`](./cognitive.probes/) |
| P14 | `tldr cognitive ... --show-contributors --function ...` | contributors-detail | 0 | [`14-show-contributors.*`](./cognitive.probes/) |
| P15 | `tldr cognitive ... --include-cyclomatic` | cyclomatic-comparison | 0 | [`15-include-cyclomatic.*`](./cognitive.probes/) |
| P16 | `tldr cognitive ... --top 1` | top-one | 0 | [`16-top-one.*`](./cognitive.probes/) |
| P17 | `tldr cognitive ... --top 0` | top-zero (all) | 0 | [`17-top-zero.*`](./cognitive.probes/) |
| P18 | `tldr cognitive ... --exclude '*.test.py' --exclude '__init__.py'` | exclude-globs | 0 | [`18-exclude.*`](./cognitive.probes/) |
| P19 | `tldr cognitive ... --max-files 1` | max-files cap | 0 | [`19-max-files-low.*`](./cognitive.probes/) |
| P20 | `tldr cognitive ... --include-hidden` | include-hidden | 0 | [`20-include-hidden.*`](./cognitive.probes/) |
| P21 | `tldr cognitive ... -l brainfuck` | bad-lang | 2 | [`21-bad-lang.*`](./cognitive.probes/) |
| P22 | `tldr cognitive ... -l typescript` | lang-mismatch (with warning) | 0 | [`22-lang-mismatch.*`](./cognitive.probes/) |
| P23 | `tldr cognitive ... -q` | quiet | 0 | [`23-quiet.*`](./cognitive.probes/) |
| P24 | `tldr cognitive <empty-tmp-dir>` | empty-dir (no warning) | 0 | [`24-empty-dir.*`](./cognitive.probes/) |

### Observations

- **P01** — `yahoo.py` (single file): 5 functions reported, max cognitive=14 (`fetch_intraday_chart` at line 87), 0 violations at default threshold=15. Progress on stderr: `"Calculating cognitive complexity for backend/providers/yahoo.py..."`.
- **P02** — `backend/providers/` (4 files): 23 functions total, all under threshold 15. Different progress: `"Analyzing 4 files in backend/providers..."`.
- **P03** — **N/A.** PATH defaults to `.`.
- **P04** — stderr `"Error: Path does not exist: /no/such/dir"`, exit `1`. **Wording differs from other commands:** `tldr churn` says `"Path not found:"`, `tldr available` says `"File not found:"`. Three "missing path" variations across the CLI.
- **P05** — stderr `"Error: --format sarif not supported by cognitive. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format: `"Cognitive Complexity (N functions, M violations)"` header, then a table `# Score Nest Status Function File`. Compact, readable.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by cognitive. ..."`, exit `1`.
- **P09** — `--function fetch_historical_data`: filters to just that one function. `functions[]` contains one entry.
- **P10** — **SILENT FAILURE:** `--function no_such_function` returns `{ functions: [], violations: [], summary: { all zeros }, NO warnings }`. Exit 0. NO error. **Agents must inspect `summary.total_functions > 0`** to distinguish "function found and analyzed" from "function name didn't match anything."
- **P11** — `--threshold 0`: 383 lines — every function flagged as violation (since cognitive > 0 always). `compliance_rate` should be 0% or near it.
- **P12** — `--threshold 9999`: 0 violations. Output identical structure to P02 (no flagged functions).
- **P13** — `--high-threshold 5 --threshold 1`: many `threshold_status: "severe"` and "warning" classifications. Tests the bucketing.
- **P14** — `--show-contributors --function fetch_historical_data`: adds `contributors[]` array per function with `{ line, construct, base_increment, nesting_increment, nesting_level }`. Each construct (e.g., `"if"`, `"for"`, `"try"`) gets a row showing its contribution to the total.
- **P15** — `--include-cyclomatic`: adds `cyclomatic` field per function (alongside `cognitive`). Allows direct comparison of the two metrics. For `fetch_intraday_chart`: cognitive=14, cyclomatic=8 (cognitive penalizes nesting more heavily than cyclomatic).
- **P16** — `--top 1`: 1 function in `functions[]`, but `summary.total_functions` still 23. Truncation affects display only.
- **P17** — `--top 0` (all): includes all 23 functions. Same data as P02 (which has 23 functions under default --top 50).
- **P18** — `--exclude '*.test.py' --exclude '__init__.py'`: 21 functions (down from 23) — `__init__.py` had 2 small functions that were excluded.
- **P19** — `--max-files 1`: limits to 1 file analyzed. `summary.total_functions` reflects only that 1 file's count.
- **P20** — `--include-hidden`: same as default in this scope (no dotfiles present).
- **P21** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P22** — `-l typescript` on Python-only dir: exit 0 with `warnings: ["No supported source files found in backend/providers"]`. **WARNING-WITH-EMPTY-RESULT pattern** — distinct from P10/P24 which return empty WITHOUT a warnings field. Agents can detect "wrong language" via the warning string.
- **P23** — `-q` suppresses the `"Analyzing N files in..."` progress message.
- **P24** — Empty dir: same empty shape as P10 — `functions: []`, `violations: []`, summary zeros — but NO `warnings` field. **Cannot distinguish empty-dir from function-not-found from JSON shape alone.**

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/cognitive.rs` (~155 lines)
- `crates/tldr-core/src/metrics/cognitive.rs` (`analyze_cognitive`, `merge_cognitive_reports`)
- `crates/tldr-core/src/metrics/walker.rs` (`walk_source_files`, `WalkOptions`)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/cognitive.rs:23-69
#[derive(Debug, Args)]
pub struct CognitiveArgs {
    #[arg(default_value = ".")] pub path: PathBuf,
    #[arg(long)] pub function: Option<String>,  // No short flag (collision avoidance)
    #[arg(long, short = 'l')] pub lang: Option<Language>,
    #[arg(long, default_value = "15")] pub threshold: u32,
    #[arg(long, default_value = "25")] pub high_threshold: u32,
    #[arg(long)] pub show_contributors: bool,
    #[arg(long)] pub include_cyclomatic: bool,
    #[arg(long, default_value = "50")] pub top: usize,
    #[arg(long, short = 'e')] pub exclude: Vec<String>,
    #[arg(long)] pub include_hidden: bool,
    #[arg(long, default_value = "0")] pub max_files: usize,
}
```
Reveals: `--function` deliberately has NO short flag (per docstring: "Note: --function is the long form; -f short flag is NOT used to avoid collision with --format"). This is a cross-command pattern — `-f` is reserved for `--format` globally.

**File vs directory dispatch:**
```rust
// cognitive.rs:85-144
let report = if self.path.is_file() {
    let _validated_path = validate_file_path(self.path.to_str().unwrap_or_default(), None)?;
    ... analyze_cognitive(&self.path, &options)?
} else if self.path.is_dir() {
    let walk_options = WalkOptions { lang: self.lang, exclude: ..., ... };
    let (files, walk_warnings) = walk_source_files(&self.path, &walk_options)?;
    let mut reports = Vec::new();
    for file in &files { ... analyze_cognitive(file, &options) ... }
    merge_cognitive_reports(reports, &options)
} else {
    return Err(anyhow::anyhow!("Path does not exist: {}", self.path.display()));
};
```
Reveals: explicit three-way branch (file / dir / neither). `validate_file_path` is only called in the FILE branch — directory traversal validation happens via `walk_source_files`. The "Path does not exist" message is the `else` arm.

**Empty result has three distinct shapes:** (NOT documented in --help)
- File analysis with function-not-found: empty result, no warnings (because `analyze_cognitive` succeeded but the function filter matched nothing).
- Empty dir: `walk_source_files` returns `(empty Vec, no warnings)` → `merge_cognitive_reports` produces empty result.
- Language-mismatch dir: `walk_source_files` returns `(empty Vec, warnings: ["No supported source files found in <path>"])` → the warning is preserved.

This is intentional: the walker distinguishes "you gave me a path with no matching files for the language" from "you gave me a path that's just empty." Source confirms in `metrics/walker.rs`.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `cognitive` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route cognitive.rs` returns 0 matches. Every call walks + parses + scores from scratch.

---

## Architectural Deep Dive

- **Under the hood:** SonarQube cognitive complexity algorithm. For each function, walks the AST, increments a counter for each control-flow construct (`if`, `for`, `while`, `switch`, `try/catch`, recursion) PLUS extra penalty for nested constructs. Cognitive ≠ cyclomatic: cognitive penalizes nesting depth (a deeply-nested loop scores higher than a flat one), cyclomatic counts decision points equally.
- **Performance:** Cold per call. ~50ms per file × N files. Dominated by tree-sitter parse. NO daemon caching.
- **LLM cognitive load:** Replaces "scan for deeply-nested functions worth refactoring." The `--show-contributors` flag emits per-line contributions to the score — invaluable for agents that want to suggest specific refactors (extract this inner loop, flatten this nested if).

---

## Intent & Routing

- **User/Agent Goal:** identify functions that are mentally hard to follow — candidates for refactoring, additional tests, or breaking up. Cognitive complexity is the modern (post-SonarQube) successor to cyclomatic.
- **When to choose this over similar tools:**
  - Over `tldr complexity`: `complexity` is cyclomatic (decision points); `cognitive` is SonarQube algorithm (penalizes nesting more heavily). Use `--include-cyclomatic` for side-by-side comparison.
  - Over `tldr halstead`: `halstead` is token-vocabulary-based difficulty; `cognitive` is structural. Different dimensions of "complexity."
  - Over `tldr explain`: `explain` deep-dives ONE function; `cognitive` ranks ALL functions in a file/dir by score.
- **Prerequisites (composition):**
  - For an actionable shortlist, use `--threshold 15 --top 10` (defaults).
  - For refactor recommendations, add `--show-contributors --function <name>` after identifying candidates.
  - For language-filtered scans on mixed projects, pass `-l <lang>` — note language mismatch returns `warnings: [...]` (P22).

---

## Agent Synthesis

> **How to use `tldr cognitive`:**
> SonarQube cognitive complexity scorer. `tldr cognitive [PATH]` returns JSON `{ functions, violations, summary, warnings? }`. Each `FunctionCognitive` has `cognitive`, `max_nesting`, `nesting_penalty`, `threshold_status` ("ok"/"warning"/"severe"). Add `--show-contributors` for per-line `{line, construct, base_increment, nesting_increment, nesting_level}` detail; `--include-cyclomatic` for side-by-side comparison; `--function <name>` to filter to one function. `--threshold` (default 15) and `--high-threshold` (default 25) drive the status classification. Default format JSON; `-f text` for table summary; `-f compact` for one-line; `sarif`/`dot` rejected. Exit codes: 0 ok (including silent empty cases), 1 path-does-not-exist / format-reject, 2 clap bad-lang.
>
> **Crucial Rules:**
> - **THREE silent-empty modes are visually similar.** Function-not-found (P10), empty-dir (P24), and lang-mismatch (P22) all return exit 0 with `functions: [], violations: [], summary: {zeros}`. The ONLY distinguishing feature: P22 includes `warnings: ["No supported source files found in <path>"]`. P10 and P24 have NO warnings field. To distinguish "function name didn't match" from "no files found", you must check both `summary.total_functions == 0` AND the file/dir context.
> - **`-f` (short for `--format`) is RESERVED globally.** This command deliberately uses `--function` (no short flag) — see source comment: "Note: --function is the long form; -f short flag is NOT used to avoid collision with --format". Cross-command pattern; do not assume `-f` works for any flag.
> - **Path-does-not-exist wording is "Path does not exist:" (capital P).** Distinct from `tldr churn` ("Path not found:"), `tldr available` ("File not found:" capital F), `tldr chop` ("file not found:" lowercase). Four different conventions across the CLI for the same error class.
> - **`--top` truncates `functions[]` but `summary.total_functions` is the full count.** P16: --top 1 shows 1 function but `summary.total_functions: 23`. Always use the summary for accurate counts (consistent with `tldr churn`, `tldr api-check`).
> - **`--show-contributors` and `--include-cyclomatic` are additive fields in JSON.** Each adds a per-function field (`contributors[]` and `cyclomatic`). When NOT set, those fields are omitted entirely (NOT null). Defensive parsing: check field presence before accessing.
> - **`threshold_status` enum has THREE values: "ok", "warning", "severe".** Tied to `--threshold` and `--high-threshold`. Cognitive ≤ threshold → "ok"; > threshold but ≤ high_threshold → "warning"; > high_threshold → "severe". Use this string for triage automation.
> - **`--max-files 0` AND `--top 0` both mean "unlimited".** Convention is consistent in this command. Different from other commands where 0 might mean "literally zero."
> - **NO daemon route.** Every call re-parses. `tldr warm` is a no-op.
> - **Cognitive ≠ Cyclomatic.** A function with deeply-nested loops scores higher in cognitive than in cyclomatic. Use `--include-cyclomatic` to see both side-by-side; agents recommending refactors should typically optimize for the cognitive number (correlates better with maintainability).
>
> **Command:** `tldr cognitive [PATH]`
>
> **With common flags:** `tldr cognitive <PATH> -l <lang> --threshold 10 --top 5 --include-cyclomatic --show-contributors -f compact` (use for the top-5 most-complex functions with full per-line breakdown and cyclomatic comparison; pipe to jq for downstream prioritization).
