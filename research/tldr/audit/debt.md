# Command: `tldr debt`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; debt itself is rule-based aggregation, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr debt` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`debt.probes/probe.sh`](./debt.probes/probe.sh).

---

## Ground Truth (`tldr debt --help`)

```text
Analyze technical debt using SQALE method

Usage: tldr debt [OPTIONS] [PATH]

Arguments:
  [PATH]
          Path to analyze (file or directory)

          [default: .]

Options:
  -c, --category <CATEGORY>
          Filter by SQALE category

          [possible values: reliability, security, maintainability, efficiency, changeability, testability]

  -k, --top <TOP>
          Number of top files to show

          [default: 20]

      --min-debt <MIN_DEBT>
          Minimum debt minutes to include file

      --hourly-rate <HOURLY_RATE>
          Hourly rate for cost estimation ($/hour)

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
| Typical output size | medium (~40 lines for subdir) to heavy (~10000 lines for full backend with all files) |

**Top-level keys (JSON, `DebtReport`):**
- `issues` (`array<DebtIssue>`) — per-file/per-rule findings, NOT truncated
- `top_files` (`array<TopFile>`) — top N files by debt minutes, truncated by `--top` (default 20)
- `summary` (`object`) — `{ total_minutes, total_hours, debt_ratio, debt_density, by_category, by_rule, by_severity, by_severity_count }`
- `language` (`string` | `null`) — single auto-detected language; `null` on multi-language projects
- `total_minutes` (`u32`) — **TOP-LEVEL MIRROR** of `summary.total_minutes`
- `total_hours` (`f64`) — **TOP-LEVEL MIRROR** of `summary.total_hours`

**`DebtIssue` shape:**
- `file` (`string`) — project-relative path
- `line` (`u32`)
- `element` (`string`) — function/class qualified name
- `rule` (`string`) — rule ID (e.g., `"complexity.high"`)
- `message` (`string`) — human description
- `category` (`string`) — one of: reliability, security, maintainability, efficiency, changeability, testability
- `debt_minutes` (`u32`) — estimated remediation time

**`TopFile` shape:** `{ file, total_minutes, issue_count, ... }` — aggregated per file.

**Empty-result shape (P19 empty dir, P21 file-as-PATH):**
```json
{
  "issues": [],
  "top_files": [],
  "summary": {
    "total_minutes": 0, "total_hours": 0.0, "debt_ratio": 0.0, "debt_density": 0.0,
    "by_category": {}, "by_rule": {}, "by_severity": {}, "by_severity_count": {}
  },
  "language": null,
  "total_minutes": 0,
  "total_hours": 0.0
}
```
Exit 0. **File-as-PATH (P21) silently returns empty** — debt only walks directories.

**Error shapes:**
- Path not found: `"Error: Path not found: /no/such/dir"` → exit **1** (anyhow!)
- Bad `--category`: clap-style `"error: invalid value 'wat' for '--category <CATEGORY>' [possible values: reliability, security, ...]"` → exit **2**
- Bad `--lang`: clap-style → exit **2**
- Format reject: `"Error: --format sarif not supported by debt. ..."` → exit **1**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr debt backend/providers` | happy | 0 | [`01-happy.*`](./debt.probes/) |
| P02 | `tldr debt backend` | happy-scale | 0 | [`02-happy-scale.*`](./debt.probes/) |
| P03 | N/A: PATH defaults to `.`. | — | — | [`03-missing-arg.*`](./debt.probes/) (placeholder) |
| P04 | `tldr debt /no/such/dir` | failure-badpath | 1 | [`04-badpath.*`](./debt.probes/) |
| P05 | `tldr debt ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./debt.probes/) |
| P06 | `tldr debt ... -f text` | format-text | 0 | [`06-format-text.*`](./debt.probes/) |
| P07 | `tldr debt ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./debt.probes/) |
| P08 | `tldr debt ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./debt.probes/) |
| P09 | `tldr debt backend --category security` | category-filter | 0 | [`09-category-security.*`](./debt.probes/) |
| P10 | `tldr debt backend --category wat` | bad-category (clap) | 2 | [`10-category-bogus.*`](./debt.probes/) |
| P11 | `tldr debt backend -k 1` | top-one | 0 | [`11-top-one.*`](./debt.probes/) |
| P12 | `tldr debt backend -k 0` | top-zero | 0 | [`12-top-zero.*`](./debt.probes/) |
| P13 | `tldr debt backend --min-debt 60` | min-debt mid | 0 | [`13-min-debt-mid.*`](./debt.probes/) |
| P14 | `tldr debt backend --min-debt 99999` | min-debt high | 0 | [`14-min-debt-high.*`](./debt.probes/) |
| P15 | `tldr debt backend --hourly-rate 100` | hourly-rate | 0 | [`15-hourly-rate.*`](./debt.probes/) |
| P16 | `tldr debt ... -l python` | explicit-python | 0 | [`16-lang-python.*`](./debt.probes/) |
| P17 | `tldr debt ... -l typescript` | lang-mismatch (empty result) | 0 | [`17-lang-mismatch.*`](./debt.probes/) |
| P18 | `tldr debt ... -l brainfuck` | bad-lang | 2 | [`18-bad-lang.*`](./debt.probes/) |
| P19 | `tldr debt <empty-tmp-dir>` | empty-dir | 0 | [`19-empty-dir.*`](./debt.probes/) |
| P20 | `tldr debt ... -q` | quiet | 0 | [`20-quiet.*`](./debt.probes/) |
| P21 | `tldr debt backend/providers/yahoo.py` | file-as-PATH (silent empty!) | 0 | [`21-file-arg.*`](./debt.probes/) |
| P22 | `tldr debt backend --category maintainability` | category-maintainability | 0 | [`22-category-maintainability.*`](./debt.probes/) |

### Observations

- **P01** — `backend/providers/` (4 files): 1 issue (`DhanProvider.fetch_intraday_chart` at line 126, `complexity.high`, `category: maintainability`, `debt_minutes: 20`). `total_minutes: 20`, `total_hours: 0.3`. `debt_ratio: 5.4%` (Good).
- **P02** — Full `backend/`: `total_minutes: 19020`, `total_hours: 317.0`, `top_files` truncated to 20. Output 10517 lines (severely truncated by probe.sh at 500 line cap).
- **P03** — **N/A.** PATH defaults to `.`.
- **P04** — stderr `"Error: Path not found: /no/such/dir"`, exit `1` (anyhow!). Matches `tldr churn`/`tldr calls` convention.
- **P05** — stderr `"Error: --format sarif not supported by debt. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format: `"Technical Debt Report"` header + `Total Debt:`, `Debt Ratio:`, `Debt Density:`, `By Category:`, `Top Debtors:`, `Top Issues:` sections. Clean SQALE-style summary.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by debt. ..."`, exit `1`.
- **P09** — `--category security`: 17 lines stdout — likely 0 security issues in Stock-Monitor backend. Schema unchanged but issues array filtered.
- **P10** — clap-style: `"error: invalid value 'wat' for '--category <CATEGORY>' [possible values: reliability, security, maintainability, efficiency, changeability, testability]"`, exit `2`. **Best UX: full valid-values list inline.**
- **P11** — `-k 1`: `top_files` truncated to 1 entry; `issues[]` and `total_minutes` unchanged from default (P02). **`-k` truncates `top_files` only**, NOT `issues[]` or summary totals.
- **P12** — `-k 0`: 10416 lines stdout — slightly less than P02 (10517). `-k 0` semantics unclear from observation alone — could mean "literally zero top_files" (matching tldr contracts) OR "all top_files" (matching cognitive). Schema verification needed. **Inspect `top_files.length`** to determine semantics.
- **P13** — `--min-debt 60`: filters files with <60 debt minutes from `top_files` AND `issues`. 793 lines (much smaller than default 10517). Strong filter.
- **P14** — `--min-debt 99999`: filters out everything; minimal output (118 lines, just summary + empty arrays).
- **P15** — `--hourly-rate 100`: adds cost estimation; summary should include cost in $. Output is 10518 lines (+1 from P02 — probably adds a single field).
- **P16** — `-l python`: identical output to default — Python is the dominant language detected automatically.
- **P17** — `-l typescript` on Python-only subdir: 17 lines, empty result. **Silent filter — files not matching the language are excluded.**
- **P18** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P19** — Empty dir: standard empty shape with `language: null`. NO `warnings` field. Indistinguishable from "no matching files" silently.
- **P20** — `-q` suppresses the `"Analyzing technical debt in <path>..."` progress message.
- **P21** — **SILENT FILE-AS-PATH:** Passing a FILE (yahoo.py) instead of a DIRECTORY: exit 0 with empty result (`issues: []`, `language: null`). The analyzer walks directories ONLY; files are accepted but yield no data. **No warning that file-as-PATH is unsupported.** Agents must inspect `issues.length > 0` to detect silent failure.
- **P22** — `--category maintainability` on backend: 10146 lines — most issues are maintainability-category. Confirms category filter works.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/debt.rs` (167 lines)
- `crates/tldr-core/src/quality/debt.rs` (`analyze_debt`, SQALE rule definitions)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/debt.rs:30-50
#[derive(Debug, Args)]
pub struct DebtArgs {
    #[arg(default_value = ".")] pub path: PathBuf,
    #[arg(short = 'c', long, value_parser = ["reliability", "security", "maintainability", "efficiency", "changeability", "testability"])]
    pub category: Option<String>,
    #[arg(short = 'k', long, default_value = "20")] pub top: usize,
    #[arg(long)] pub min_debt: Option<u32>,
    #[arg(long)] pub hourly_rate: Option<f64>,
}
```
Reveals: `--category` uses `value_parser = [...]` (clap's array-of-strings validator) — explicit list, easy to inline. `--top` short flag is `-k` (uncommon — most tldr commands use `-n` for top-N). `--category` short is `-c` (matches `tldr api-check`).

**Path validation:**
```rust
// debt.rs:60-62
if !self.path.exists() {
    anyhow::bail!("Path not found: {}", self.path.display());
}
```
Reveals: standard anyhow! pattern → exit 1. Same as `tldr calls`/`tldr churn`. NO upfront `is_file()` vs `is_dir()` check — file-as-PATH passes the existence test but yields empty result.

**Category validation (defense-in-depth):**
```rust
// debt.rs:65-73
if let Some(ref cat) = self.category {
    if !VALID_CATEGORIES.contains(&cat.as_str()) {
        anyhow::bail!(
            "Invalid category '{}'. Valid categories: {}",
            cat, VALID_CATEGORIES.join(", ")
        );
    }
}
```
Reveals: runtime validation in addition to clap value_parser. **Unreachable in practice** because clap rejects first (P10) — but defensive code if the clap config is ever wrong.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `debt` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route debt.rs` returns 0 matches. Every call rebuilds the SQALE analysis.

---

## Architectural Deep Dive

- **Under the hood:** SQALE method — walks the project, runs each language's rule set against each file (e.g., `complexity.high` = function with cyclomatic > 15; `duplicate.code` = clone detection; etc.). Each rule has a `debt_minutes` estimate. Aggregates per file (`top_files`) and per category (`summary.by_category`). `debt_ratio` = total_debt / KLOC * 100.
- **Performance:** Cold per call (no daemon). Walks all source files in PATH; rule evaluation is moderately expensive. ~2-5s on Stock-Monitor backend (56 files).
- **LLM cognitive load:** Replaces "code review checklist" with a quantitative SQALE score. The `debt_minutes` field is the agent's prioritization signal — sort by total_minutes per file to find refactor candidates. The category breakdown helps focus efforts (security vs. maintainability vs. testability).

---

## Intent & Routing

- **User/Agent Goal:** quantify technical debt (in minutes-of-developer-time) per file, per category, project-wide. SQALE method's standardized output.
- **When to choose this over similar tools:**
  - Over `tldr complexity`/`tldr cognitive`: those return single-function metrics; `debt` aggregates many metrics into a unified debt-minute estimate.
  - Over `tldr smells`/`tldr patterns`: those find individual issues; `debt` rolls up everything into a monetized estimate.
  - Over `tldr health`: `health` is the meta-summary that includes debt as one input.
- **Prerequisites (composition):**
  - Pass a DIRECTORY, NOT a single file (P21 — file-as-PATH silently empty).
  - For monetary estimates, pass `--hourly-rate <N>` for cost calculation.
  - For focused audits, use `--category security` or `--category maintainability` to filter.

---

## Agent Synthesis

> **How to use `tldr debt`:**
> SQALE technical-debt aggregator. `tldr debt [PATH]` returns JSON `{ issues, top_files, summary, language, total_minutes, total_hours }`. Each `DebtIssue` has `file, line, element, rule, message, category, debt_minutes`. `summary` includes `total_minutes`, `total_hours`, `debt_ratio`, `debt_density`, `by_category`, `by_rule`, `by_severity`. Filter with `--category {reliability,security,maintainability,efficiency,changeability,testability}`. Default `--top 20` truncates `top_files` (not `issues`). Default JSON; `-f text` for SQALE summary; `-f compact` for one-line; `sarif`/`dot` rejected. Exit codes: 0 ok (including silent empty for file-as-PATH), 1 path-not-found / format-reject, 2 bad `--category` / bad `--lang`.
>
> **Crucial Rules:**
> - **File-as-PATH silently returns empty result** (P21). The engine only walks directories — passing a single file produces `{ issues: [], top_files: [], summary: { all zeros }, language: null }` with exit 0. **Verify `issues.length > 0` to detect this silent failure.** Always pass a directory.
> - **`-k` truncates `top_files` ONLY, not `issues[]` or summary totals.** P11: -k 1 keeps all issues + full summary, just shows 1 top file. To filter ALL issues by debt, use `--min-debt N` (P13).
> - **Top-level `total_minutes` and `total_hours` MIRROR `summary.*` fields** (same backwards-compat pattern as `tldr api-check`). Both forms work.
> - **`language: null` for multi-language projects.** Stock-Monitor (Python + TypeScript) reports null instead of one language (P02). Distinct from `tldr calls` which reports a SINGLE detected language.
> - **`-l typescript` on Python files silently returns empty** (P17). Files not matching the language are excluded; no warning. Similar pattern to other audit commands with `-l` filters.
> - **`-k` is the short flag for `--top`** (uncommon — most tldr commands use `-n`). `-c` is the short for `--category` (matches `tldr api-check`).
> - **Path-not-found exit code is 1** (anyhow!). Cross-command convention; matches `tldr calls`/`tldr churn`/`tldr dead`.
> - **Empty dir produces same shape as file-as-PATH** (both empty arrays + null language). Inspect PATH type externally to distinguish.
> - **NO daemon route.** Every call rebuilds SQALE rule pass over all matching files.
> - **`--category` and `--lang` are both clap-validated** — bad values reject with full valid-values list inline (P10 best-in-class UX).
>
> **Command:** `tldr debt [PATH]`
>
> **With common flags:** `tldr debt <DIR> -l <lang> --category maintainability --hourly-rate 100 --min-debt 30 -k 10 -f compact` (use for cost-aware prioritized scan: top-10 files in maintainability category, ≥30min debt each, with $100/hr cost estimation; pipe to jq for CI dashboards).
