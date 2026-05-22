# Command: `tldr patterns`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; patterns is AST-based, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr patterns` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`patterns.probes/probe.sh`](./patterns.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/audit/patterns.md).

---

## Ground Truth (`tldr patterns --help`)

```text
Detect design patterns and coding conventions

Usage: tldr patterns [OPTIONS] [PATH]

Arguments:
  [PATH]
          Path to file or directory to analyze (default: current directory)

          [default: .]

Options:
  -l, --lang <LANG>
          Programming language (auto-detect if not specified)

  -c, --category <CATEGORY>
          Filter to specific pattern category

      --min-confidence <MIN_CONFIDENCE>
          Minimum confidence threshold (0.0-1.0)

          [default: 0.5]

      --max-files <MAX_FILES>
          Maximum files to analyze (0 = unlimited)

          [default: 1000]

      --no-constraints
          Skip LLM constraint generation

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
| Typical output size | medium (~85 lines for 4-file dir; ~275 lines for full backend) |

**Top-level keys (JSON, `PatternsReport`):**

ALWAYS present:
- `metadata` (`object`) — `{ files_analyzed, files_skipped, files_partial, duration_ms, language_distribution: { files_by_language, patterns_by_language }, patterns_before_filter, patterns_after_filter, confidence_threshold }`
- `conflicts` (`array`) — conflicting pattern detections
- `constraints` (`array`) — LLM-consumable constraint statements (omitted with `--no-constraints`)
- `naming` (`object`) — `{ functions, classes, constants, private_prefix, consistency_score }` cross-cutting naming-convention summary
- `import_patterns` (`object`) — import-organization summary
- `type_coverage` (`object`) — type-annotation density summary

**Conditionally present** (only when patterns detected):
- `error_handling` (`object`) — `{ custom_errors, exception_types, try_catch, ... }`
- `api_conventions` (`object`)
- `resource_management` (`object`)
- `validation` (`object`)

Each conditional section contains a `patterns: [{ pattern_id, confidence, evidence: [{ file, line, snippet }] }]` array of detected patterns.

**Empty-result shape (P16 max-files=0, P21 empty dir):**
```json
{
  "metadata": {
    "files_analyzed": 0, "files_skipped": 0, "files_partial": 0, "duration_ms": 0,
    "language_distribution": { "files_by_language": {}, "patterns_by_language": {} },
    "patterns_before_filter": 0, "patterns_after_filter": 0,
    "confidence_threshold": 0.5
  }
}
```
**ONLY `metadata` is present** — no `naming`, `constraints`, etc. when no files analyzed.

**Error shapes:**
- Path not found: `"Error: Path not found: /no/such/dir"` → exit **2** (TldrError::PathNotFound)
- Bad `--category`: clap-style `"error: invalid value 'wat' for '--category <CATEGORY>': Unknown pattern category: wat"` → exit **2**
- Bad `--lang`: clap-style → exit **2**
- Non-source single file: `"Error: Unsupported language: md"` → exit **11** (**SHOWS JUST THE EXTENSION** — shortest unsupported-language wording in audit suite)
- Format reject: `"Error: --format sarif not supported by patterns. ..."` → exit **1**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr patterns backend/providers` | happy | 0 | [`01-happy.*`](./patterns.probes/) |
| P02 | `tldr patterns backend` | happy-scale | 0 | [`02-happy-scale.*`](./patterns.probes/) |
| P03 | N/A: PATH defaults to `.`. | — | — | [`03-missing-arg.*`](./patterns.probes/) (placeholder) |
| P04 | `tldr patterns /no/such/dir` | failure-badpath | 2 | [`04-badpath.*`](./patterns.probes/) |
| P05 | `tldr patterns ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./patterns.probes/) |
| P06 | `tldr patterns ... -f text` | format-text | 0 | [`06-format-text.*`](./patterns.probes/) |
| P07 | `tldr patterns ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./patterns.probes/) |
| P08 | `tldr patterns ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./patterns.probes/) |
| P09 | `tldr patterns ... --category naming` | category-filter (naming) | 0 | [`09-category-naming.*`](./patterns.probes/) |
| P10 | `tldr patterns ... --category error-handling` | category-filter (error) | 0 | [`10-category-error.*`](./patterns.probes/) |
| P11 | `tldr patterns ... --category wat` | bad-category | 2 | [`11-category-bogus.*`](./patterns.probes/) |
| P12 | `tldr patterns ... --min-confidence 0.0` | min-conf zero (all patterns) | 0 | [`12-min-conf-zero.*`](./patterns.probes/) |
| P13 | `tldr patterns ... --min-confidence 1.0` | min-conf perfect (strict) | 0 | [`13-min-conf-perfect.*`](./patterns.probes/) |
| P14 | `tldr patterns ... --min-confidence 0.5` | min-conf default | 0 | [`14-min-conf-mid.*`](./patterns.probes/) |
| P15 | `tldr patterns backend --max-files 1` | max-files cap | 0 | [`15-max-files-low.*`](./patterns.probes/) |
| P16 | `tldr patterns ... --max-files 0` | **max-files 0 = LITERALLY ZERO** | 0 | [`16-max-files-zero.*`](./patterns.probes/) |
| P17 | `tldr patterns ... --no-constraints` | skip constraints | 0 | [`17-no-constraints.*`](./patterns.probes/) |
| P18 | `tldr patterns ... -l brainfuck` | bad-lang | 2 | [`18-bad-lang.*`](./patterns.probes/) |
| P19 | `tldr patterns ... -l python` | lang-python explicit | 0 | [`19-lang-python.*`](./patterns.probes/) |
| P20 | `tldr patterns ... -l typescript` | lang-mismatch (metadata-only result) | 0 | [`20-lang-mismatch.*`](./patterns.probes/) |
| P21 | `tldr patterns <empty-tmp-dir>` | empty-dir (metadata-only) | 0 | [`21-empty-dir.*`](./patterns.probes/) |
| P22 | `tldr patterns README.md` | non-source-md (extension-only error) | 11 | [`22-non-source-md.*`](./patterns.probes/) |
| P23 | `tldr patterns ... -q` | quiet | 0 | [`23-quiet.*`](./patterns.probes/) |
| P24 | `tldr patterns backend/providers/yahoo.py` | single file | 0 | [`24-single-file.*`](./patterns.probes/) |

### Observations

- **P01** — `backend/providers/` (4 files): `naming: { functions: "snake_case", classes: "pascal_case", constants: "mixed", private_prefix: "_", consistency_score: 0.867 }`. `patterns_before_filter: 6, patterns_after_filter: 3` (3 patterns at confidence ≥ 0.5). Includes `conflicts, constraints, import_patterns, type_coverage`.
- **P02** — Full `backend/`: 10 top-level keys (includes `api_conventions`, `error_handling`, `resource_management`, `validation` — conditional sections present when patterns detected).
- **P03** — **N/A.** PATH defaults to `.`.
- **P04** — stderr `"Error: Path not found: /no/such/dir"`, exit `2` (TldrError::PathNotFound). Matches `tldr loc`/`tldr complexity`/`tldr imports`.
- **P05** — stderr `"Error: --format sarif not supported by patterns. ..."`, exit `1`.
- **P06** — Text format: human-readable summary with section headers.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by patterns. ..."`, exit `1`.
- **P09** — `--category naming`: same top-level keys as P01 — confirms `naming` is in the always-present cross-cutting set. `--category` filter affects which conditional sections are populated, NOT which always-present sections appear.
- **P10** — `--category error-handling`: same shape as P01 (no `error_handling` key because none detected in providers/). **Filter doesn't add keys; it limits which patterns get detected.**
- **P11** — clap-style with parse_category error: `"error: invalid value 'wat' for '--category <CATEGORY>': Unknown pattern category: wat"`, exit `2`. Custom value_parser injects the error message; valid categories aren't enumerated in the error.
- **P12** — `--min-confidence 0.0`: `patterns_after_filter: 6` (all 6 detected patterns pass). Output 139 lines.
- **P13** — `--min-confidence 1.0`: `patterns_after_filter: 1` (only one pattern at perfect confidence). 47 lines.
- **P14** — Default (`--min-confidence 0.5`): identical to P01 (which uses default).
- **P15** — `--max-files 1`: limits to 1 file. 59 lines.
- **P16** — **SOURCE-COMMENT DRIFT — `--max-files 0` literally means ZERO, not unlimited.** Per `--help`: `"Maximum files to analyze (0 = unlimited)"`. Empirical: `files_analyzed: 0, files_by_language: {}, patterns_before_filter: 0`. **Bug:** the help text claims `0 = unlimited` but the engine treats 0 as a literal cap of zero files. Output is `metadata`-only (no naming/constraints/etc.).
- **P17** — `--no-constraints`: removes `constraints` array from output. 58 lines vs 84.
- **P18** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P19** — Explicit `-l python`: identical to default.
- **P20** — `-l typescript` on Python project: 15 lines, METADATA-ONLY shape (`files_analyzed: 0, files_by_language: {}`). **Silent filter — files not matching the language are excluded; engine returns metadata-only.**
- **P21** — Empty dir: same metadata-only shape as P20.
- **P22** — Non-source single file `README.md`: stderr `"Error: Unsupported language: md"`, exit `11`. **EXTENSION-ONLY wording** (just "md") — shortest in the audit suite. Compare: `tldr loc` says `"Unsupported language: README.md"`; `tldr complexity` says `"Unsupported language: Could not detect language for: /path/README.md"`.
- **P23** — `-q` suppresses the `"Analyzing patterns in <path>..."` progress message.
- **P24** — Single file `yahoo.py`: 83 lines (similar to dir P01). Schema same as directory mode.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/detect_patterns.rs` (87 lines)
- `crates/tldr-core/src/patterns/...` (per-category pattern detectors, format module)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/detect_patterns.rs:27-51
#[derive(Debug, Args)]
pub struct PatternsArgs {
    #[arg(default_value = ".")] pub path: PathBuf,
    #[arg(long, short = 'l')] pub lang: Option<Language>,
    #[arg(long, short = 'c', value_parser = parse_category)] pub category: Option<PatternCategory>,
    #[arg(long, default_value = "0.5")] pub min_confidence: f64,
    #[arg(long, default_value = "1000")] pub max_files: usize,
    #[arg(long)] pub no_constraints: bool,
}
```
Reveals: `--category` uses custom `parse_category` value_parser (calls `s.parse()` on PatternCategory enum). Default `--max-files: 1000` (NOT 0). Default `--min-confidence: 0.5`.

**Source-comment drift — `--max-files 0`:**
Per `--help`: `"Maximum files to analyze (0 = unlimited)"`. The CLI doesn't transform 0 → unlimited before passing to `PatternConfig`. Engine treats `max_files: 0` as the literal cap. **Behavior contradicts the documentation.** Workaround: use a high value like `--max-files 999999`.

**Config construction:**
```rust
// detect_patterns.rs:65-71
let config = PatternConfig {
    min_confidence: self.min_confidence,
    max_files: self.max_files,           // ← passed through verbatim
    evidence_limit: 3,                   // ← HARDCODED, not flag-controllable
    categories: self.category.map(|c| vec![c]).unwrap_or_default(),
    generate_constraints: !self.no_constraints,
};
```
Reveals: HARDCODED `evidence_limit: 3` — at most 3 evidence entries per pattern. Not flag-controllable. `categories` is empty Vec when `--category` is omitted (= analyze all categories).

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `patterns` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route detect_patterns.rs` returns 0 matches.

---

## Architectural Deep Dive

- **Under the hood:** Walks per-file AST. Runs each registered pattern detector against the file: naming-convention classification (snake_case vs camelCase vs PascalCase), error handling (try/catch, custom errors), API conventions, validation patterns, resource management, type coverage. Each detector emits a confidence score [0.0–1.0]. Aggregates detections, filters by `--min-confidence`, generates `constraints` (LLM-consumable rule statements). `consistency_score` summarizes how uniform the naming is.
- **Performance:** Cold ~4ms per 4-file dir. NO daemon caching.
- **LLM cognitive load:** The single best command for "tell me the unwritten coding conventions of this codebase" — `naming.consistency_score`, `api_conventions`, the generated `constraints[]` array — all LLM-consumable. Pair with `tldr smells` (anti-pattern detection) for full conventions audit.

---

## Intent & Routing

- **User/Agent Goal:** infer the implicit coding conventions and design patterns used in a codebase — naming style, error handling, API conventions, validation approach.
- **When to choose this over similar tools:**
  - Over `tldr smells`: smells finds ANTI-patterns; patterns finds CONVENTIONS.
  - Over `tldr secure`: secure focuses on security; patterns is general design.
  - Over `tldr api-check`: api-check verifies API USAGE conformance; patterns extracts the conventions themselves.
- **Prerequisites (composition):**
  - For LLM workflows, the `constraints[]` array is the actionable output ("functions must be snake_case", "errors must be custom exception types") — use this directly in LLM prompts.
  - For mixed-language projects, `--lang` filters effectively (P20: -l typescript on Python produces metadata-only result).

---

## Agent Synthesis

> **How to use `tldr patterns`:**
> Convention/design-pattern inferrer. `tldr patterns [PATH]` returns JSON with ALWAYS-present `{ metadata, conflicts, constraints, naming, import_patterns, type_coverage }` and CONDITIONALLY-present `{ error_handling?, api_conventions?, resource_management?, validation? }`. Each conditional has `patterns: [{ pattern_id, confidence, evidence: [{file, line, snippet}] }]`. `naming` gives `{ functions, classes, constants, private_prefix, consistency_score }`. Default `--min-confidence 0.5`. Default JSON; `-f text` for human-readable; `-f compact` for one-line; `sarif`/`dot` rejected. Exit codes: 0 ok (including metadata-only empty), 1 format-reject, 2 path-not-found / bad-category / bad-lang, 11 unsupported-language (non-source single file).
>
> **Crucial Rules:**
> - **`--max-files 0` LITERALLY means ZERO (NOT unlimited).** P16: `--max-files 0` returns `files_analyzed: 0, patterns_before_filter: 0`. The `--help` text claims "0 = unlimited" but the engine treats 0 as the literal cap. **Source-comment drift — do NOT pass `--max-files 0`. Use a high value like `--max-files 999999` for unlimited, OR omit the flag (default is 1000).** Cross-command divergence: `tldr cognitive --top 0`, `tldr cognitive --max-files 0`, `tldr halstead --top 0`/`--max-files 0`, `tldr loc --max-files 0` ALL mean "unlimited"; only `tldr patterns --max-files 0` and `tldr contracts --limit 0` mean "literally zero".
> - **Non-source single file shows EXTENSION-ONLY in error.** P22: `tldr patterns README.md` → `"Error: Unsupported language: md"` (just "md"!). Shortest unsupported-language wording in the audit suite. Compare: `tldr loc` says `"Unsupported language: README.md"`; `tldr complexity` says `"Unsupported language: Could not detect language for: <full path>"`. Three distinct wordings now catalogued.
> - **Top-level keys are CONDITIONAL on detected patterns.** Always-present: `metadata, conflicts, constraints, naming, import_patterns, type_coverage`. Conditional (only when patterns found): `error_handling, api_conventions, resource_management, validation`. Empty/zero-file analysis: ONLY `metadata` is present. Agents must defensively check field presence.
> - **`--category` filters DETECTION, not OUTPUT keys.** P09/P10: passing `--category naming` or `--category error-handling` still returns `naming, import_patterns, type_coverage, conflicts, constraints` keys. The filter controls which pattern detectors run during the conditional-section detection; cross-cutting summaries always present.
> - **`evidence_limit: 3` is HARDCODED.** Each pattern's `evidence` array is capped at 3 entries. Not flag-controllable. Source: `detect_patterns.rs:68`.
> - **`constraints` array is the LLM-actionable output.** Each entry is a human-readable rule like `"functions must use snake_case"`. Pass `--no-constraints` to omit (saves tokens; useful for non-LLM consumers).
> - **Path-not-found exit code is 2** (TldrError::PathNotFound — matches `tldr loc`, `tldr complexity`, `tldr imports`; differs from `tldr churn`/`tldr debt` which use exit 1).
> - **`-l <lang>` is an effective filter.** P20: `-l typescript` on Python project returns metadata-only output (no patterns detected). Different from `tldr cohesion`/`tldr interface` which silently ignore the flag.
> - **NO daemon route.** Every call walks + analyzes.
>
> **Command:** `tldr patterns [PATH]`
>
> **With common flags:** `tldr patterns <PATH> --min-confidence 0.7 --no-constraints -f compact | jq '.constraints'` (use for high-confidence convention extraction without LLM constraint text; pipe to jq for actionable rule list).
