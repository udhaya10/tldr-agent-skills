# Command: `tldr bugbot`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; bugbot orchestrates multiple sub-analyses, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr bugbot` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |
| Scoping decision | Used `--no-tools` for most probes to skip L1 tool integration (clippy/cargo-audit/etc.) and keep runs fast |

Re-run all evidence via [`bugbot.probes/probe.sh`](./bugbot.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/fix/bugbot.md).

---

## Ground Truth (`tldr bugbot --help` + `tldr bugbot check --help`)

```text
Automated bug detection on code changes

Usage: tldr bugbot [OPTIONS] <COMMAND>

Commands:
  check  Run bugbot check on uncommitted changes
  help   Print this message or the help of the given subcommand(s)

[Global flags: -f format, -l lang, -q quiet, -v verbose, -h help]
```

```text
Run bugbot check on uncommitted changes

Usage: tldr bugbot check [OPTIONS] [PATH]

Arguments:
  [PATH]
          Project root directory
          [default: .]

Options:
      --base-ref <BASE_REF>           [default: HEAD]
      --staged                        Check only staged changes
      --max-findings <MAX_FINDINGS>   [default: 50] (0 = unlimited)
      --no-fail                       Do not fail (exit 0) even if findings exist
  -q, --quiet                         Suppress progress messages
      --no-tools                      Disable L1 commodity tool analysis
      --tool-timeout <TOOL_TIMEOUT>   [default: 60]
  -f, --format <FORMAT>               [default: json]
  -l, --lang <LANG>
  -v, --verbose  -h, --help
```

**Note:** `tldr bugbot` requires `check` subcommand — there is no default sub-action. `bugbot help` prints subcommand help.

---

## Output Shape

| Aspect | Value |
|---|---|
| Default format | `json` |
| Formats that work | `json`, `text`, `compact` (P01, P06, P07) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| Typical output size | small (~26 lines pretty JSON when no changes); LARGE on dirty repos (~70k lines when many uncommitted files) |

**Top-level keys (JSON, `BugbotCheckReport`):**
- `tool` (`string`) — always `"bugbot"`
- `mode` (`string`) — `"check"`
- `language` (`string`) — detected/specified language
- `base_ref` (`string`) — git ref diffed against
- `detection_method` (`string`) — observed `"git:uncommitted"`
- `timestamp` (`string`) — ISO 8601 UTC
- `changed_files` (`array<string>`) — ABSOLUTE paths
- `findings` (`array<Finding>`) — bug findings
- `summary` (`object`) — `{ total_findings, by_severity, by_type, files_analyzed, functions_analyzed, l1_findings, l2_findings, tools_run, tools_failed }`
- `elapsed_ms` (`u32`)
- `errors` (`array<string>`) — error messages from sub-analyses (non-fatal)
- `notes` (`array<string>`) — informational messages, e.g., `"no_changes_detected"`

**`Finding` shape:** per-finding bug-detection report; includes severity, file, line, message, type.

**Empty-result shape (P01, P11 no staged):**
```json
{
  "tool": "bugbot", "mode": "check", "language": "typescript", "base_ref": "HEAD",
  "detection_method": "git:uncommitted", "timestamp": "...", "changed_files": [],
  "findings": [], "summary": { "total_findings": 0, ... },
  "elapsed_ms": <N>, "errors": [], "notes": ["no_changes_detected"]
}
```
Exit 0. `notes: ["no_changes_detected"]` is the canonical "nothing to do" signal.

**Error shapes:**
- Missing subcommand: prints `--help` to stderr + exit **2** (clap)
- Bad path (auto-detect fails): `"Error: Could not detect language. Use --lang <LANG>"` → exit **1** (bail!)
- Bad `--base-ref`: `"Error: Failed to list base-ref changes"` → exit **1**
- Non-git dir: `"Error: Failed to list uncommitted changes"` → exit **1**
- Empty dir (no source files to detect): `"Error: Could not detect language. Use --lang <LANG>"` → exit **1**
- Format reject: `"Error: --format sarif not supported by bugbot check. ..."` → exit **1**
- Bad `--lang`: clap-style → exit **2**
- **Findings detected (without `--no-fail`):** `"Error: bugbot: N finding(s) detected"` → exit **1**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr bugbot check` | happy (TypeScript autodetect, 0 changes) | 0 | [`01-happy.*`](./bugbot.probes/) |
| P02 | `tldr bugbot check . --no-tools` | happy-scale | 0 | [`02-happy-scale.*`](./bugbot.probes/) |
| P03 | `tldr bugbot` *(no subcommand)* | failure-missing-subcommand | 2 | [`03-missing-arg.*`](./bugbot.probes/) |
| P04 | `tldr bugbot check /no/such/dir --no-tools` | failure-badpath (lang-detect fail) | 1 | [`04-badpath.*`](./bugbot.probes/) |
| P05 | `tldr bugbot check ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./bugbot.probes/) |
| P06 | `tldr bugbot check ... -f text` | format-text | 0 | [`06-format-text.*`](./bugbot.probes/) |
| P07 | `tldr bugbot check ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./bugbot.probes/) |
| P08 | `tldr bugbot check ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./bugbot.probes/) |
| P09 | `tldr bugbot check ... --base-ref HEAD~1` | base-ref to past commit | 0 | [`09-base-ref.*`](./bugbot.probes/) |
| P10 | `tldr bugbot check ... --base-ref not-a-ref` | bad base-ref | 1 | [`10-base-ref-bogus.*`](./bugbot.probes/) |
| P11 | `tldr bugbot check ... --staged` | staged-only | 0 | [`11-staged.*`](./bugbot.probes/) |
| P12 | `tldr bugbot check ... --max-findings 1` | max-findings 1 | 0 | [`12-max-findings-low.*`](./bugbot.probes/) |
| P13 | `tldr bugbot check ... --max-findings 0` | max-findings unlimited | 0 | [`13-max-findings-zero.*`](./bugbot.probes/) |
| P14 | `tldr bugbot check ... --no-fail` | no-fail (don't exit 1 on findings) | 0 | [`14-no-fail.*`](./bugbot.probes/) |
| P15 | `tldr bugbot check ... --tool-timeout 1` | tool timeout short | 0 | [`15-tool-timeout-short.*`](./bugbot.probes/) |
| P16 | `tldr bugbot check ... -l brainfuck` | bad-lang | 2 | [`16-bad-lang.*`](./bugbot.probes/) |
| P17 | `tldr bugbot check ... -l python` | **explicit python (uncovers 4 dirty Python files → exit 1 with findings)** | 1 | [`17-lang-python.*`](./bugbot.probes/) |
| P18 | `tldr bugbot check ... -l typescript` | lang-typescript (silent empty) | 0 | [`18-lang-mismatch.*`](./bugbot.probes/) |
| P19 | `tldr bugbot check ... -q` | quiet | 0 | [`19-quiet.*`](./bugbot.probes/) |
| P20 | `tldr bugbot check <non-git-dir> --no-tools` | non-git dir | 1 | [`20-non-git.*`](./bugbot.probes/) |
| P21 | `tldr bugbot check <empty-tmp-dir> --no-tools` | empty-dir (lang-detect fail) | 1 | [`21-empty-dir.*`](./bugbot.probes/) |

### Observations

- **P01** — Default behavior: `language: "typescript"` (auto-detected for Stock-Monitor because the webui/ dir contains more TS files than backend Python files), `changed_files: []`, `notes: ["no_changes_detected"]`. `elapsed_ms: 131264` — **131 seconds** including first-run baseline scan. **`tldr bugbot` is the SLOWEST command in the suite on first run** because of PM-34 first-run detection that auto-scans the baseline.
- **P02** — Same as P01 — identical output for `.` and `./` PATH.
- **P03** — **Special case:** No subcommand prints the help text to stderr + exit `2`. Different from most "missing-arg" probes that just clap-error.
- **P04** — `tldr bugbot check /no/such/dir`: stderr `"Error: Could not detect language. Use --lang <LANG>"`, exit `1` (bail!). **No path.exists() check upfront** — the engine calls `Language::from_directory` which returns None for non-existent paths, then bails. **Misleading error** — agent might think it's a lang issue, not a path issue. Recovery: verify path exists.
- **P05** — stderr `"Error: --format sarif not supported by bugbot check. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format: 2 lines — minimal text summary.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by bugbot check. ..."`, exit `1`.
- **P09** — `--base-ref HEAD~1`: diffs against parent commit. 26 lines (no uncommitted changes affecting analysis).
- **P10** — stderr `"Error: Failed to list base-ref changes"`, exit `1`. Generic error — doesn't echo the invalid ref name. Recovery hint should be added by user.
- **P11** — `--staged`: filters to staged-only changes. Empty in this scope.
- **P12** — `--max-findings 1`: limits report to 1 finding. Empty result so no observable effect here.
- **P13** — `--max-findings 0`: unlimited. Same as default for empty result.
- **P14** — `--no-fail`: even if findings exist, exit 0. Same in empty-result case.
- **P15** — `--tool-timeout 1`: 1-second timeout per L1 tool. Same result with `--no-tools` already disabling L1 tools. Note: `--no-tools` flag would be ignored here too.
- **P16** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P17** — **MAJOR FINDING:** `-l python` (override autodetect): detects **4 uncommitted Python files in Stock-Monitor root** (`fix_dateutil.py`, `fix_db.py`, `test.py`, `test_logger.py`), runs analysis on them. Output is **72,385 lines** with detailed `findings`. Exit `1` with stderr `"Error: bugbot: 1 finding(s) detected"`. **Without `--no-fail`, ANY findings cause exit 1.** Critical for CI gating.
- **P18** — `-l typescript`: silently produces empty-result shape (no uncommitted TS files in this scope). Same anti-pattern as elsewhere.
- **P19** — `-q` suppresses progress message (P06's `"Detecting typescript changes in <path>..."`).
- **P20** — Non-git dir: stderr `"Error: Failed to list uncommitted changes"`, exit `1`. **Confirms bugbot REQUIRES git** — uses `git diff` under the hood.
- **P21** — Empty dir: stderr `"Error: Could not detect language. Use --lang <LANG>"`, exit `1`. Same as P04.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/bugbot/check.rs` (~200+ lines)
- `crates/tldr-cli/src/commands/bugbot/types.rs` (`BugbotCheckReport`, `BugbotFinding`)
- `crates/tldr-cli/src/commands/bugbot/first_run.rs` (PM-34 first-run baseline)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/bugbot/check.rs:33-66
#[derive(Debug, Args)]
pub struct BugbotCheckArgs {
    #[arg(default_value = ".")] pub path: PathBuf,
    #[arg(long, default_value = "HEAD")] pub base_ref: String,
    #[arg(long)] pub staged: bool,
    #[arg(long, default_value = "50")] pub max_findings: usize,
    #[arg(long)] pub no_fail: bool,
    #[arg(long, short)] pub quiet: bool,
    #[arg(long, default_value_t = false)] pub no_tools: bool,
    #[arg(long, default_value_t = 60)] pub tool_timeout: u64,
}
```
Reveals: `--quiet -q` is on the LOCAL args (not just global) — this command has a LOCAL `quiet` field. Default `--max-findings 50` (NOT 1000 like other commands). Default `--tool-timeout 60`.

**Language detection (bail-on-fail):**
```rust
// check.rs:80-88
let language = match lang {
    Some(l) => l,
    None => match Language::from_directory(&self.path) {
        Some(l) => l,
        None => {
            bail!("Could not detect language. Use --lang <LANG>");
        }
    },
};
```
Reveals: unlike most commands which silently fall back to Python, `tldr bugbot check` BAILS when autodetect fails. Best-in-class behavior for ambiguous repos.

**PM-34 first-run baseline (the 131-second hit):**
```rust
// check.rs:94-108
let is_first_run = {
    use super::first_run::{detect_first_run, run_first_run_scan, FirstRunStatus};
    match detect_first_run(&project) {
        FirstRunStatus::FirstRun => {
            let progress_fn = |msg: &str| writer.progress(msg);
            match run_first_run_scan(&project, &progress_fn) {
                Ok(result) => { ... }
            }
        }
    }
};
```
Reveals: on first run for a project, bugbot scans the FULL baseline (not just changed files) to establish a reference point. **One-time cost** — subsequent invocations don't re-baseline.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `bugbot` (or `bugbot check`) is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route bugbot/check.rs` returns 0 matches.

---

## Architectural Deep Dive

- **Under the hood:** Reads `git diff` (against `--base-ref` or staged via `--staged`), extracts changed files. For each changed file, runs L1 (commodity tools like clippy/cargo-audit per language) AND L2 (tldr's own analyses: taint, resources, complexity drift, etc.). Aggregates findings into `summary.l1_findings` + `l2_findings`. First-run on a new repo triggers full baseline scan (PM-34, slow).
- **Performance:** Cold first-run ~2 minutes on Stock-Monitor (baseline scan). Subsequent runs ~10-30s depending on `--no-tools`. NO daemon caching for bugbot specifically.
- **LLM cognitive load:** PR-gating CI tool. Returns exit 1 on ANY findings unless `--no-fail` is set — perfect for `tldr bugbot check && git push` workflows. The L1 vs L2 split helps prioritize (L1 is the commodity tool noise; L2 is tldr-specific deep findings).

---

## Intent & Routing

- **User/Agent Goal:** detect bugs in UNCOMMITTED code changes (or staged, or against any ref) before commit/push. CI-gate friendly.
- **When to choose this over similar tools:**
  - Over `tldr fix-diagnose` / `tldr fix-check`: bugbot is git-diff-driven (changed code only); fix-* analyze the WHOLE codebase.
  - Over `tldr secure`/`tldr vuln`: those are full-scan SAST; bugbot focuses on the diff.
  - Over external linters: aggregates L1 (commodity tools) + L2 (tldr analyses) in one report.
- **Prerequisites (composition):**
  - Project MUST be in a git working tree (P20: non-git dir fails).
  - First run takes ~2min on real codebases (PM-34 baseline scan).
  - For pre-commit hooks, use `--staged --no-fail` to inspect findings without aborting commit.
  - For CI fail-on-findings, OMIT `--no-fail`.

---

## Agent Synthesis

> **How to use `tldr bugbot`:**
> Git-diff-driven bug detector for changed code. `tldr bugbot check [PATH]` runs analyses on `git diff <--base-ref>` or `--staged` files. Returns JSON `{ tool: "bugbot", mode: "check", language, base_ref, detection_method, timestamp, changed_files (ABSOLUTE), findings, summary, elapsed_ms, errors, notes }`. `summary` includes `l1_findings` (commodity tools) and `l2_findings` (tldr analyses) — total = both. Default `--max-findings 50`, `--tool-timeout 60`. Default JSON; `-f text` for 2-line summary; `-f compact` for one-line; `sarif`/`dot` rejected. Exit codes: 0 ok (no findings, OR `--no-fail`), 1 path-not-found / non-git / no-source / bad-base-ref / findings-detected / format-reject, 2 missing subcommand / bad-lang.
>
> **Crucial Rules:**
> - **`tldr bugbot` requires a subcommand.** `tldr bugbot` alone prints help to stderr + exit 2. Use `tldr bugbot check`.
> - **FINDINGS CAUSE EXIT 1 BY DEFAULT.** P17: 1 finding detected → exit 1 with stderr `"Error: bugbot: 1 finding(s) detected"`. For CI: omit `--no-fail` (gates on findings). For pre-commit hooks where you want to see findings without aborting: pass `--no-fail`.
> - **Project MUST be a git working tree.** P20: non-git dir → `"Error: Failed to list uncommitted changes"`, exit 1. P10: invalid base-ref → `"Error: Failed to list base-ref changes"`, exit 1.
> - **First-run baseline scan takes ~2 MINUTES on real codebases** (PM-34 fix). The detection auto-scans the entire repo on first invocation. Subsequent runs are fast (~10-30s). **Bake this latency into CI planning.**
> - **Bad path produces a MISLEADING language error** (P04: `"Could not detect language. Use --lang <LANG>"`). The engine calls `Language::from_directory` on a non-existent path; no upfront `path.exists()` check. **Verify path exists externally** before invoking.
> - **Auto-detect prefers the dominant language**, which on Stock-Monitor is TypeScript (webui/). Pass `-l python` explicitly if you want Python-focused analysis. **`-l` is NOT silently ignored here** — P17 shows it CHANGES behavior dramatically (4 uncommitted Python files surfaced, 1 finding emitted).
> - **`--max-findings 0` means UNLIMITED** (matches `tldr cognitive`/`halstead`/`loc`; differs from `tldr contracts --limit 0` and `tldr patterns --max-files 0`).
> - **`detection_method` field signals the diff source:** observed `"git:uncommitted"`. Likely also `"git:staged"` with `--staged`, `"git:base_ref"` with `--base-ref`. Use for downstream filtering.
> - **`changed_files` is ABSOLUTE PATHS** (P17 shows `/Users/.../Stock-Monitor/...`). Strip prefix manually for portable output.
> - **`-q` is a LOCAL flag on `bugbot check`** (separate from global `-q`). Source: `BugbotCheckArgs.quiet`. Both work equivalently.
> - **NO daemon route.** Every call walks git diff + sub-analyses.
>
> **Command:** `tldr bugbot check [PATH] [--base-ref REF | --staged]`
>
> **With common flags:** `tldr bugbot check --staged --no-fail -l python -f compact | jq '.summary.total_findings'` (use for pre-commit hooks: scan staged changes, don't abort commit, just emit finding count).
