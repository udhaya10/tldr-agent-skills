# Command: `tldr churn`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; churn itself is git-based, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr churn` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`churn.probes/probe.sh`](./churn.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/audit/churn.md).

---

## Ground Truth (`tldr churn --help`)

```text
Analyze git-based code churn

Usage: tldr churn [OPTIONS] [PATH]

Arguments:
  [PATH]
          Directory to analyze (default: current dir)

          [default: .]

Options:
      --days <DAYS>
          Days of history to analyze

          [default: 365]

      --top <TOP>
          Maximum files to show

          [default: 20]

  -e, --exclude <EXCLUDE>
          Exclude files matching pattern (glob syntax, can be repeated)

      --authors
          Include author statistics

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
| Typical output size | medium (~270 lines pretty JSON) to heavy (~700 lines on bigger histories) |

**Top-level keys (JSON, `ChurnReport`):**
- `files` (`array<FileChurn>`) — files ranked by `commit_count` descending, truncated to `--top`
- `hotspots` (`array`) — **ALWAYS empty in v0.4.0** (the `--hotspots` flag is deprecated/ignored; use `tldr hotspots` instead)
- `authors` (`array<AuthorStats>`) — **empty unless `--authors` is set**; each entry: `{ name, email, commits, lines_added, lines_deleted, files_touched }`
- `summary` (`object`) — `{ total_files, total_commits, time_window_days, total_lines_changed, avg_commits_per_file, most_churned_file }`
- `is_shallow` (`bool`) — true when the git clone is shallow (affects accuracy of churn metrics)

**`FileChurn` shape:**
- `file` (`string`) — project-relative path
- `commit_count` (`u32`)
- `lines_added`, `lines_deleted`, `lines_changed` (`u32`) — sum of `+` and `-` lines across commits in window
- `first_commit`, `last_commit` (`string`, ISO `YYYY-MM-DD`)
- `authors` (`array<string>`) — **always populated with author emails** (NOT gated by `--authors`)
- `author_count` (`u32`)

**Empty-dir shape (P15) — special-cased per `schema-cleanup-v2 P2.BUG-10`:**
```json
{
  "root": "/tmp/...",
  "files": [],
  "authors": [],
  "hotspots": [],
  "summary": null,
  "warnings": ["Empty directory: no files to analyze"]
}
```
Exit 0. **`summary: null`** (NOT an object) and an additional top-level `warnings: [string]` field that doesn't appear in normal output. **Different shape from happy result.**

**Error shapes:**
- Path not found: `"Error: Path not found: /no/such/dir"` → exit **1** (anyhow!)
- Format reject: `"Error: --format sarif not supported by churn. ..."` → exit **1**
- Not a git repo: `"Error: Not a git repository: <path>"` → exit **1** (ChurnError::NotGitRepository)
- File-as-PATH: `"Error: Git command failed: git rev-parse --git-dir / Failed to spawn git: No such file or directory (os error 2)"` → exit **1** **(MISLEADING: git IS installed; the file path can't be a git working dir)**
- Bad `--lang`: clap-style → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr churn` *(default PATH=`.`)* | happy | 0 | [`01-happy.*`](./churn.probes/) |
| P02 | `tldr churn . --days 1000 --top 50` | happy-scale | 0 | [`02-happy-scale.*`](./churn.probes/) |
| P03 | N/A: PATH defaults to `.`, no required positional. | — | — | [`03-missing-arg.*`](./churn.probes/) (placeholder) |
| P04 | `tldr churn /no/such/dir` | failure-badpath | 1 | [`04-badpath.*`](./churn.probes/) |
| P05 | `tldr churn -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./churn.probes/) |
| P06 | `tldr churn -f text` | format-text | 0 | [`06-format-text.*`](./churn.probes/) |
| P07 | `tldr churn -f compact` | format-compact | 0 | [`07-format-compact.*`](./churn.probes/) |
| P08 | `tldr churn -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./churn.probes/) |
| P09 | `tldr churn --days 30` | days-short | 0 | [`09-days-short.*`](./churn.probes/) |
| P10 | `tldr churn --days 99999` | days-long (saturated) | 0 | [`10-days-long.*`](./churn.probes/) |
| P11 | `tldr churn --top 1` | top-one | 0 | [`11-top-one.*`](./churn.probes/) |
| P12 | `tldr churn --authors` | authors stats | 0 | [`12-authors.*`](./churn.probes/) |
| P13 | `tldr churn --exclude '*.md' --exclude 'venv/**'` | exclude-globs | 0 | [`13-exclude.*`](./churn.probes/) |
| P14 | `tldr churn <non-git-dir>` | not-a-git-repo | 1 | [`14-non-git.*`](./churn.probes/) |
| P15 | `tldr churn <empty-tmp-dir>` | empty-dir special-case | 0 | [`15-empty-dir.*`](./churn.probes/) |
| P16 | `tldr churn -l brainfuck` | bad-lang | 2 | [`16-bad-lang.*`](./churn.probes/) |
| P17 | `tldr churn -q --days 30` | quiet | 0 | [`17-quiet.*`](./churn.probes/) |
| P18 | `tldr churn --hotspots` | hidden-deprecated flag | 0 | [`18-hotspots-flag.*`](./churn.probes/) |
| P19 | `tldr churn backend/providers/yahoo.py` | file-as-path (misleading error) | 1 | [`19-file-arg.*`](./churn.probes/) |

### Observations

- **P01** — Stock-Monitor root: 2649 files, 156 commits, time_window=365 days, total_lines_changed=1060365. Top hub: `webui/src/features/chart/components/ChartView.jsx` (49 commits, +9755/−1461 lines). `is_shallow: false`.
- **P02** — `--days 1000 --top 50`: same 156 commits (the repo doesn't have 1000 days of history — it caps at the actual log range), but 50 files shown instead of 20. Different output size from P01.
- **P03** — **N/A.** `ChurnArgs.path` defaults to `.`.
- **P04** — stderr `"Error: Path not found: /no/such/dir"`, exit `1` (anyhow!). Same convention as `tldr calls`/`tldr dead`.
- **P05** — stderr `"Error: --format sarif not supported by churn. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format renders a tabular summary header `"Churn Analysis (N files, D days)"`, total commits row, "Most churned" line, then a table `#  Commits  +Lines  -Lines  Auth  Last  File`. Compact, scannable.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by churn. ..."`, exit `1`.
- **P09** — `--days 30`: 2429 files (subset), 82 commits (subset of 156). Confirms `--days` filters the time window. `total_lines_changed: 876485` (vs P01's 1060365).
- **P10** — `--days 99999`: identical to P01 (`total_commits: 156, total_lines_changed: 1060365`). **Saturates at repo history length** — going past actual history adds nothing. `time_window_days` field echoes the user-supplied value (99999) even though only 365 days of history exist.
- **P11** — `--top 1`: 1 file in `files[]`, but `summary.total_files` still 2649 and `summary.total_commits` still 156. `--top` does NOT change the underlying counts — only truncates the displayed array.
- **P12** — `--authors`: top-level `authors[]` populated with `{ name, email, commits, lines_added, lines_deleted, files_touched }` per author. Without `--authors`, `authors: []`. Note: each per-file `FileChurn.authors` (emails only) is populated REGARDLESS of the flag.
- **P13** — `--exclude '*.md' --exclude 'venv/**'`: comma-separated NOT required (repeatable flag). Glob patterns are matched against project-relative paths. Output structure unchanged; matching files are omitted from `files[]` and from `total_lines_changed`.
- **P14** — Non-git directory: stderr `"Error: Not a git repository: /tmp/..."`, exit `1` (`ChurnError::NotGitRepository`). Clear, actionable.
- **P15** — Empty dir: **special-case stub output** (NOT an error). `summary: null` and `warnings: ["Empty directory: no files to analyze"]`. Per `schema-cleanup-v2 P2.BUG-10`: pre-fix, an empty mktemp tree would have raised "Not a git repository" — this short-circuit avoids that confusing case. **Different shape from happy result.**
- **P16** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`. **Note:** `--lang` is the global flag; `churn` doesn't actually USE the lang value (it's git-based, language-agnostic) — but clap still validates it, so a bad value rejects before churn runs.
- **P17** — `-q` suppresses the `"Analyzing churn in . (last 365 days)..."` progress message.
- **P18** — `--hotspots` (hidden flag): exit 0, output **byte-identical to P01** (same 276 stdout lines, same MD5 — verify). The flag is declared with `hide = true` and the `include_hotspots` parameter is passed to `analyze_churn` but the result is always `hotspots: []`. **Deprecated; use `tldr hotspots` instead** (per source-comment line 48).
- **P19** — **Misleading error:** stderr `"Error: Git command failed: git rev-parse --git-dir / Failed to spawn git: No such file or directory (os error 2)"`, exit `1`. The "Failed to spawn git" message wrongly suggests git is missing; the real issue is the FILE PATH can't be a git working directory (`git rev-parse --git-dir` exits non-zero, and the error gets wrapped). **Recovery hint:** pass a DIRECTORY, not a file.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/churn.rs` (~360 lines)
- `crates/tldr-core/src/quality/churn.rs` (`analyze_churn`, `ChurnError`, `is_git_repository`)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/churn.rs:26-51
#[derive(Debug, Args)]
pub struct ChurnArgs {
    #[arg(default_value = ".")] pub path: PathBuf,
    #[arg(long, default_value = "365")] pub days: u32,
    #[arg(long, default_value = "20")] pub top: usize,
    #[arg(long, short = 'e')] pub exclude: Vec<String>,
    #[arg(long)] pub authors: bool,
    #[arg(long, hide = true)] pub hotspots: bool,  // deprecated, ignored
}
```
Reveals: `--hotspots` is hidden via `hide = true` AND documented as "ignored" in source. Other flags are clap-typed as expected.

**Empty-dir short-circuit (P15 root cause):**
```rust
// churn.rs:66-84
if self.path.is_dir() && is_directory_empty(&self.path) {
    let stub = serde_json::json!({
        "root": self.path.display().to_string(),
        "files": [], "authors": [], "hotspots": [],
        "summary": serde_json::Value::Null,
        "warnings": ["Empty directory: no files to analyze"],
    });
    ...
    return Ok(());
}
```
Reveals: emits a **stub JSON** with `summary: null` and a `warnings` array that ISN'T in the normal `ChurnReport` schema. This is intentional (schema-cleanup-v2 P2.BUG-10) — empty dirs are a benign edge case, not an error. **But agents that schema-validate the output should accept `summary` as either null or `ChurnSummary`.**

**Deprecated `--hotspots`:**
```rust
// churn.rs:48-51
/// Deprecated: use `tldr hotspots` instead. This flag is ignored.
#[arg(long, hide = true)]
pub hotspots: bool,
```
Reveals: the `include_hotspots` argument IS passed through to `analyze_churn` (line 99), but the core analyzer doesn't populate the `hotspots` array based on this flag — the field is always empty in v0.4.0. P18 verifies output is byte-identical.

**Path-not-found shape (P04):**
```rust
// (in tldr-core analyze_churn / is_git_repository)
// → bubbled up as anyhow! "Path not found: <path>"
```
Reveals: the engine returns a plain anyhow error → exit 1. NOT a typed RemainingError (which would map to exit 5).

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `churn` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route churn.rs` returns 0 matches. Every call shells out to `git log` and re-parses.

---

## Architectural Deep Dive

- **Under the hood:** Shells out to `git log` over the specified time window, extracts per-file commit/line-change stats, aggregates per author (when `--authors` set). The shallow-clone detector (`check_shallow_clone`, `is_degenerate_shallow`) checks `.git/shallow` to flag truncated histories.
- **Performance:** Cold per call (no daemon). Dominated by `git log` IO — ~1-3s on Stock-Monitor (2649 files, 156 commits). Larger repos with more history scale linearly with commit count.
- **LLM cognitive load:** Replaces `git log --stat | awk` workflows. Returns structured top-N list with line-change deltas and dates — actionable for prioritizing refactoring (high-churn + high-complexity = "hotspot"). Pair with `tldr hotspots` for the cross-product analysis (this command alone doesn't compute hotspots despite the deprecated flag).

---

## Intent & Routing

- **User/Agent Goal:** identify files that change frequently — candidates for refactoring, additional tests, or design review.
- **When to choose this over similar tools:**
  - Over `tldr hotspots`: `hotspots` combines churn × complexity for the "where do bugs hide?" matrix; `churn` is just the git history view.
  - Over `git log --stat`: structured JSON output, time-window filtering, author aggregation, top-N truncation built-in.
  - Over `tldr temporal`: `temporal` shows file CO-CHANGE patterns (which files change together); `churn` is per-file individual frequency.
- **Prerequisites (composition):**
  - PATH must be inside a git working tree. Non-git dirs error; file-as-PATH produces a misleading "Failed to spawn git" error (P19).
  - For shallow clones, expect partial results; `is_shallow: true` flags the limitation in the JSON.

---

## Agent Synthesis

> **How to use `tldr churn`:**
> Git-history-based file-frequency analyzer. `tldr churn [PATH]` returns JSON `{ files, hotspots, authors, summary, is_shallow }`. `files[]` is ranked descending by `commit_count` and truncated to `--top` (default 20). `--days N` filters the window (default 365); `--exclude '<glob>'` repeats to filter file patterns. `--authors` adds top-level `authors[]` aggregation (per-file `FileChurn.authors` is populated regardless). Default JSON; `-f text` for human table; `-f compact` for one-line; `sarif`/`dot` rejected. Exit codes: 0 ok (including empty-dir special-case), 1 path-not-found / not-a-git-repo / format-reject / file-as-path, 2 bad `--lang`.
>
> **Crucial Rules:**
> - **`hotspots[]` is ALWAYS empty in v0.4.0.** The `--hotspots` flag is declared (`hide = true`) and the parameter is passed to `analyze_churn`, but no hotspot data is ever populated. Source-comment marks it "Deprecated: use `tldr hotspots` instead. This flag is ignored." P18 verified byte-identical output to default. Don't rely on this field.
> - **`--days N` saturates at actual repo history.** Passing `--days 99999` on a repo with 156 commits gives the same data as `--days 365` (P10). The `time_window_days` field echoes the user-supplied value verbatim regardless of saturation. To detect saturation, compare `summary.total_commits` across two `--days` values.
> - **Empty dir is a SPECIAL CASE with a different schema** (`schema-cleanup-v2 P2.BUG-10`). The output has `summary: null` (NOT an object) and an additional top-level `warnings: ["Empty directory: no files to analyze"]` field that doesn't exist in normal output. Exit 0, NOT an error. Agents schema-validating the response must accept `summary` as `null | ChurnSummary`.
> - **File-as-PATH yields MISLEADING error.** P19: passing `yahoo.py` instead of a directory produces `"Error: Git command failed: git rev-parse --git-dir / Failed to spawn git: No such file or directory (os error 2)"`. The "Failed to spawn git" wording wrongly suggests git is missing; actual issue is the file path can't be a git working dir. Always pass a DIRECTORY.
> - **`--top` truncates `files[]` but does NOT change `summary.total_*`.** `total_files`, `total_commits`, `total_lines_changed` always reflect the full window. To get "total files matching exclude/days but before --top truncation", use `summary.total_files` (P11).
> - **`-l/--lang` is parsed by clap but UNUSED by churn.** Bad values still reject (exit 2 — P16), but valid values are ignored. Churn is language-agnostic (operates on git diffs).
> - **`--authors` and per-file `FileChurn.authors` are independent.** Each `FileChurn.authors[]` is always populated with email strings; the top-level `authors[]` (with full stats) only appears when `--authors` is passed (P12).
> - **`is_shallow: true` flags truncated histories.** Shallow clones produce incomplete churn data; the JSON warns explicitly. CI agents in shallow checkouts should run `git fetch --unshallow` first.
> - **Path-not-found exit code is 1** (anyhow!). Cross-command convention; matches `tldr calls`/`tldr dead`. Distinct from `tldr definition`'s exit 5.
> - **NO daemon route.** Every call shells out to git.
>
> **Command:** `tldr churn [PATH]`
>
> **With common flags:** `tldr churn <PATH> --days 180 --top 30 --exclude '*.lock' --exclude 'vendor/**' --authors -f compact` (use for a focused 6-month view with author attribution; pipe to jq for downstream tooling).
