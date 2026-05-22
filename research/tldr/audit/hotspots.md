# Command: `tldr hotspots`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; hotspots is git+AST hybrid, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr hotspots` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`hotspots.probes/probe.sh`](./hotspots.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/audit/hotspots.md).

---

## Ground Truth (`tldr hotspots --help`)

```text
Identify churn x complexity hotspots

Usage: tldr hotspots [OPTIONS] [PATH]

Arguments:
  [PATH]
          Directory to analyze (default: current directory)

          [default: .]

Options:
      --days <DAYS>
          Days of git history to analyze

          [default: 365]

      --top <TOP>
          Number of hotspots to return

          [default: 20]

      --by-function
          Analyze at function level (default: file level)

      --show-trend
          Include complexity trend analysis

      --min-commits <MIN_COMMITS>
          Minimum commits to be considered a hotspot

          [default: 3]

  -e, --exclude <EXCLUDE>
          Exclude patterns (glob syntax, can be repeated)

      --threshold <THRESHOLD>
          Minimum hotspot score threshold (0.0 to 1.0)

      --since <SINCE>
          Since date (ISO format, e.g., 2024-01-01)

      --recency-halflife <RECENCY_HALFLIFE>
          Exponential decay half-life in days (default: 90, 0 = no decay)

          [default: 90]

      --include-bots
          Include bot/automated commits in churn analysis (default: filtered)

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
| Typical output size | medium (~330 lines pretty JSON for top-20) |

**Top-level keys (JSON, `HotspotsReport`):**
- `hotspots` (`array<HotspotEntry>`) — ranked top-N by `hotspot_score`
- `summary` (`object`) — `{ total_files_analyzed, total_commits, time_window_days, hotspot_concentration, recommendation, total_bot_commits_filtered, avg_knowledge_fragmentation }`
- `metadata` (`object`) — `{ path, days, by_function, min_commits, is_shallow, bot_commits_filtered, recency_halflife, scoring_weights, algorithm_version }`

**`HotspotEntry` shape (file-level, default):**
- `file` (`string`) — project-relative path
- `churn_score` (`float64`, 0.0–1.0)
- `complexity_score` (`float64`, 0.0–1.0)
- `hotspot_score` (`float64`, 0.0–1.0) — composite blend per `scoring_weights`
- `commit_count` (`u32`)
- `lines_changed` (`u32`)
- `complexity` (`u32`) — cognitive complexity (matches `tldr cognitive`)
- `recommendation` (`string`) — human-readable like `"Critical: High churn + high complexity + fragmented knowledge. Prioritize refactoring."`
- `relative_churn` (`float64`), `knowledge_fragmentation` (`float64`), `current_loc` (`u32`), `author_count` (`u32`)

**`--by-function` adds** `function` and `line` fields per entry.

**`scoring_weights`** (`metadata.scoring_weights`): `{ churn, complexity, knowledge_fragmentation, temporal_coupling }`. Default observed: `{ churn: 0.412, complexity: 0.412, knowledge_fragmentation: 0.176, temporal_coupling: 0.0 }`. `algorithm_version: 2`.

**Empty-result shape (P18, --threshold 0.99 with no hotspots):**
```json
{
  "hotspots": [],
  "summary": { "total_files_analyzed": 152, "total_commits": 1178, "hotspot_concentration": 21.1, "recommendation": "Changes are well distributed across the codebase.", ... },
  "metadata": { ... }
}
```
Exit 0. NO `warnings` field. Summary still populated (analysis ran).

**Error shapes:**
- Path not found: `"Error: Path not found: <path>"` → exit **1** (anyhow!)
- Not a git repo: `"Error: Not a git repository: <path>"` → exit **1** (**diverges from `tldr churn` which special-cases empty dirs with exit 0 + warning**)
- Format reject: `"Error: --format sarif not supported by hotspots. ..."` → exit **1**
- Bad `--lang`: clap-style → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr hotspots` *(default PATH=`.`)* | happy | 0 | [`01-happy.*`](./hotspots.probes/) |
| P02 | `tldr hotspots backend --top 50` | happy-scale | 0 | [`02-happy-scale.*`](./hotspots.probes/) |
| P03 | N/A: PATH defaults to `.`. | — | — | [`03-missing-arg.*`](./hotspots.probes/) (placeholder) |
| P04 | `tldr hotspots /no/such/dir` | failure-badpath | 1 | [`04-badpath.*`](./hotspots.probes/) |
| P05 | `tldr hotspots -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./hotspots.probes/) |
| P06 | `tldr hotspots -f text` | format-text | 0 | [`06-format-text.*`](./hotspots.probes/) |
| P07 | `tldr hotspots -f compact` | format-compact | 0 | [`07-format-compact.*`](./hotspots.probes/) |
| P08 | `tldr hotspots -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./hotspots.probes/) |
| P09 | `tldr hotspots --days 30` | days-short | 0 | [`09-days-short.*`](./hotspots.probes/) |
| P10 | `tldr hotspots --days 99999` | days-long | 0 | [`10-days-long.*`](./hotspots.probes/) |
| P11 | `tldr hotspots --top 1` | top-one | 0 | [`11-top-one.*`](./hotspots.probes/) |
| P12 | `tldr hotspots --by-function --top 5` | function-level | 0 | [`12-by-function.*`](./hotspots.probes/) |
| P13 | `tldr hotspots --show-trend` | show-trend | 0 | [`13-show-trend.*`](./hotspots.probes/) |
| P14 | `tldr hotspots --min-commits 1` | min-commits low | 0 | [`14-min-commits-low.*`](./hotspots.probes/) |
| P15 | `tldr hotspots --min-commits 999` | min-commits high (empty) | 0 | [`15-min-commits-high.*`](./hotspots.probes/) |
| P16 | `tldr hotspots --exclude '*.md' --exclude 'venv/**'` | exclude-globs | 0 | [`16-exclude.*`](./hotspots.probes/) |
| P17 | `tldr hotspots --threshold 0.5` | threshold mid | 0 | [`17-threshold-mid.*`](./hotspots.probes/) |
| P18 | `tldr hotspots --threshold 0.99` | threshold high (empty) | 0 | [`18-threshold-high.*`](./hotspots.probes/) |
| P19 | `tldr hotspots --since 2026-01-01` | since-date | 0 | [`19-since.*`](./hotspots.probes/) |
| P20 | `tldr hotspots --since not-a-date` | since invalid (silent ignore!) | 0 | [`20-since-bad.*`](./hotspots.probes/) |
| P21 | `tldr hotspots --recency-halflife 0` | no-decay | 0 | [`21-no-decay.*`](./hotspots.probes/) |
| P22 | `tldr hotspots --include-bots` | include-bots | 0 | [`22-include-bots.*`](./hotspots.probes/) |
| P23 | `tldr hotspots -l brainfuck` | bad-lang | 2 | [`23-bad-lang.*`](./hotspots.probes/) |
| P24 | `tldr hotspots <non-git-dir>` | not-a-git-repo | 1 | [`24-non-git.*`](./hotspots.probes/) |
| P25 | `tldr hotspots <empty-tmp-dir>` | empty-dir (errors out!) | 1 | [`25-empty-dir.*`](./hotspots.probes/) |
| P26 | `tldr hotspots -q` | quiet | 0 | [`26-quiet.*`](./hotspots.probes/) |

### Observations

- **P01** — Stock-Monitor root: 152 files analyzed, 1178 commits, top hotspot `backend/api.py` (score 0.87, 43 commits, complexity 281, "Critical"). `hotspot_concentration: 21.1%`. `recommendation: "Changes are well distributed across the codebase."`
- **P02** — `backend/ --top 50`: similar shape with 50 hotspots. `algorithm_version: 2`, `scoring_weights: { churn: 0.412, complexity: 0.412, knowledge_fragmentation: 0.176, temporal_coupling: 0.0 }`.
- **P03** — **N/A.** PATH defaults to `.`.
- **P04** — stderr `"Error: Path not found: /no/such/dir"`, exit `1` (anyhow!). Matches `tldr churn`/`tldr calls` convention.
- **P05** — stderr `"Error: --format sarif not supported by hotspots. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format: `"Hotspots Analysis (N files, D days)"` header + table `# Score Churn Cmplx Commits Cog Priority File` + footer summary. Color-coded with priority labels (Critical/High/Medium/Low).
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by hotspots. ..."`, exit `1`.
- **P09 / P10** — `--days 30` and `--days 99999` produce same line count (329) — likely because `recency_halflife: 90` makes commits beyond ~270 days contribute negligibly. The default `--days 365` already captures most of the signal.
- **P11** — `--top 1`: 1 hotspot in `hotspots[]`. Summary unchanged.
- **P12** — `--by-function --top 5`: each entry has additional `function` and `line` fields. Function-level hotspots are MUCH more granular: top hotspot `fetch_and_store_ticker_data` at `market_data.py:194` (score 0.99).
- **P13** — `--show-trend`: same line count as default — trend data probably added to each hotspot entry. (Inspection would confirm; size suggests it's additive.)
- **P14** — `--min-commits 1`: same line count as default. The min-commits=3 default already includes most files.
- **P15** — `--min-commits 999`: 24 lines — most files filtered out. Schema unchanged; just empty hotspots.
- **P16** — `--exclude '*.md' --exclude 'venv/**'`: filters matching files from analysis. Output size similar.
- **P17** — `--threshold 0.5`: only hotspots ≥ 0.5 score appear. Output similar size in this scope.
- **P18** — `--threshold 0.99`: `hotspots: []` (empty). Summary STILL populated with `total_files_analyzed: 152, total_commits: 1178, recommendation: "Changes are well distributed..."`. Exit 0. **Empty hotspots is NOT an error.**
- **P19** — `--since 2026-01-01`: filters commits to those since 2026-01-01.
- **P20** — **SILENT IGNORE:** `--since not-a-date` returns exit 0 with output IDENTICAL to default (no since filter applied). **No error or warning that the date couldn't be parsed.** Major silent failure mode.
- **P21** — `--recency-halflife 0`: disables exponential decay (all commits weighted equally regardless of age). Subtle effect — output is 328 lines vs 329 default.
- **P22** — `--include-bots`: includes bot commits in churn analysis (default filters them out). Stock-Monitor has 0 bot commits so output identical.
- **P23** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P24** — Non-git dir: stderr `"Error: Not a git repository: /tmp/..."`, exit `1`. Matches `tldr churn` error wording.
- **P25** — **DIVERGES FROM `tldr churn`:** Empty dir returns `"Error: Not a git repository: <path>"`, exit `1`. `tldr churn` for the same empty dir returns exit 0 with a warning-only result (per `schema-cleanup-v2 P2.BUG-10` special-case). **`tldr hotspots` does NOT have this special-case.** Inconsistency for adjacent commands.
- **P26** — `-q` suppresses the `"Analyzing hotspots in . (last 365 days)..."` progress message.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/hotspots.rs` (~227 lines)
- `crates/tldr-core/src/quality/hotspots.rs` (`analyze_hotspots`, scoring)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/hotspots.rs:17-61
#[derive(Debug, Args)]
pub struct HotspotsArgs {
    #[arg(default_value = ".")] pub path: PathBuf,
    #[arg(long, default_value = "365")] pub days: u32,
    #[arg(long, default_value = "20")] pub top: usize,
    #[arg(long)] pub by_function: bool,
    #[arg(long)] pub show_trend: bool,
    #[arg(long, default_value = "3")] pub min_commits: u32,
    #[arg(long, short = 'e')] pub exclude: Vec<String>,
    #[arg(long)] pub threshold: Option<f64>,
    #[arg(long)] pub since: Option<String>,  // ← String, no clap validation
    #[arg(long, default_value = "90")] pub recency_halflife: f64,
    #[arg(long)] pub include_bots: bool,
}
```
Reveals: `--since` is `Option<String>` (NOT typed `Date`) — clap accepts any string, validation deferred to engine. P20 confirms: invalid dates are silently dropped instead of erroring.

**No path validation upfront:**
The CLI's `run()` doesn't check `path.exists()` upfront. Validation happens inside `analyze_hotspots` via shelled-out git commands. Bad path → "Path not found" (P04); non-git dir → "Not a git repository" (P24).

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `hotspots` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route hotspots.rs` returns 0 matches. Combines `git log` (shell out) + tree-sitter complexity (in-process).

---

## Architectural Deep Dive

- **Under the hood:** Combines `tldr churn` data (git log) with `tldr cognitive` complexity scores. Per-file (or per-function with `--by-function`): churn_score = normalized commit count; complexity_score = normalized cognitive; hotspot_score = weighted blend per `scoring_weights`. Recency decay via exponential half-life (default 90 days). Knowledge fragmentation = how many distinct authors touched the file.
- **Performance:** O(git log) + O(parse complexity per file). ~2-5s on Stock-Monitor. NO daemon caching.
- **LLM cognitive load:** **The single most actionable refactor signal in the audit suite.** Hotspots = files that are BOTH complex AND frequently changed = highest bug risk + highest payoff per refactor hour. Pair with `tldr complexity <fn>` or `tldr explain <fn>` to drill into specific top-N hotspots.

---

## Intent & Routing

- **User/Agent Goal:** prioritize refactor effort by finding files/functions that are both complex AND frequently changed (Adam Tornhill's hotspot model).
- **When to choose this over similar tools:**
  - Over `tldr churn`: churn is just the git frequency; hotspots multiplies it by complexity. Use hotspots for prioritization, churn for raw frequency.
  - Over `tldr complexity`/`tldr cognitive`: those give complexity in isolation; hotspots filters to "complex AND being actively modified".
  - Over `tldr debt`: debt is SQALE-rule-based; hotspots is metric × git-frequency. Different prioritization signals.
- **Prerequisites (composition):**
  - PATH must be inside a git working tree (non-git dirs and empty dirs error — P24, P25).
  - For granular refactor planning, use `--by-function` (P12).
  - For deeper investigation of top hotspots, pipe names into `tldr complexity <fn>` or `tldr explain <fn>`.

---

## Agent Synthesis

> **How to use `tldr hotspots`:**
> Adam-Tornhill-style churn × complexity prioritizer. `tldr hotspots [PATH]` returns JSON `{ hotspots, summary, metadata }`. Each `HotspotEntry` has `file, churn_score, complexity_score, hotspot_score, commit_count, lines_changed, complexity, recommendation, relative_churn, knowledge_fragmentation, current_loc, author_count`. With `--by-function`, adds `function` and `line`. Default `--top 20`, `--days 365`, `--min-commits 3`, `--recency-halflife 90`. Bot commits filtered by default; `--include-bots` to include. Default JSON; `-f text` for prioritized table; `-f compact` for one-line; `sarif`/`dot` rejected. Exit codes: 0 ok (including empty hotspots), 1 path-not-found / not-a-git-repo / format-reject, 2 bad-lang.
>
> **Crucial Rules:**
> - **`--since <invalid-date>` is SILENTLY IGNORED.** P20: `--since not-a-date` returns exit 0 with output IDENTICAL to default (no since filter applied). No error, no warning. The `since` argument is `Option<String>` (not typed); engine-side validation silently drops invalid inputs. **Fix:** use strict ISO format (e.g., `2024-01-01`) and verify the `metadata.days` or filter applied.
> - **Empty dir ERRORS OUT (exit 1), diverging from `tldr churn`'s graceful handling.** P25: `tldr hotspots <empty-dir>` returns `"Error: Not a git repository"` exit 1; `tldr churn <empty-dir>` returns exit 0 with `warnings: ["Empty directory: no files to analyze"]`. **Cross-command inconsistency** for the same input.
> - **`hotspot_score` is the composite signal**, blended per `metadata.scoring_weights`. Default weights observed: churn 0.412, complexity 0.412, knowledge_fragmentation 0.176, temporal_coupling 0.0. To re-weight, you'd need to recompute client-side from the per-component scores.
> - **`--by-function` adds `function` and `line` per entry.** Function-level granularity is MUCH more actionable for specific refactor recommendations (P12). Default file-level is good for "which file to attack first"; function-level for "which function inside that file".
> - **`--days N` may be MOSTLY a no-op due to recency-halflife decay.** With `--recency-halflife 90` (default), commits older than ~270 days contribute < 12.5% weight. P09 (days=30) and P10 (days=99999) produced same output. To turn off decay, use `--recency-halflife 0` (P21).
> - **`recommendation` field is the actionable string** per hotspot. Examples: `"Critical: High churn + high complexity + fragmented knowledge. Prioritize refactoring."` Useful for direct LLM consumption in refactor suggestions.
> - **`knowledge_fragmentation`** = author dispersion (higher = more distinct authors). Hotspots with high fragmentation AND high churn signal "tribal knowledge debt" — multiple people don't know the whole file.
> - **`algorithm_version: 2`** is the current implementation. Pin against this when scripting; future versions may change scoring.
> - **Path-not-found exit code is 1** (anyhow! — matches `tldr churn`/`tldr calls`).
> - **NO daemon route.** Every call shells out to git AND re-parses for complexity.
>
> **Command:** `tldr hotspots [PATH]`
>
> **With common flags:** `tldr hotspots <PATH> --by-function --top 10 --threshold 0.5 --days 180 -f text` (use for function-level refactor prioritization over the last 6 months, surfacing only meaningful-score hotspots in human-readable form).
