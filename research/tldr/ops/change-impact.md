# Command: `tldr change-impact`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; uses call graph + git diff, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr change-impact` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`change-impact.probes/probe.sh`](./change-impact.probes/probe.sh).

---

## Ground Truth (`tldr change-impact --help`)

```text
Find tests affected by code changes

Usage: tldr change-impact [OPTIONS] [PATH]

Arguments:
  [PATH]                                       [default: .]

Options:
  -l, --lang <LANG>
  -F, --files <FILES>                          Explicit list of changed files (comma-separated)
  -b, --base <BASE>                            Git base branch for diff (e.g., "origin/main")
      --staged                                 Only consider staged files
      --uncommitted                            All uncommitted changes (staged + unstaged)
  -d, --depth <DEPTH>                          [default: 10]
      --include-imports                        Include import graph
      --test-patterns <TEST_PATTERNS>          Custom test file patterns (comma-separated globs)
      --runner <RUNNER>                        [pytest|pytest-k|jest|go-test|cargo-test]
  -f, --format <FORMAT>                        [default: json]
  -q, --quiet  -v, --verbose  -h, --help
```

**Detection-method priority (per source `determine_detection_method`):** `--files` > `--base` > `--staged` > `--uncommitted` > default `git:HEAD`.

---

## Output Shape

| Aspect | Value |
|---|---|
| Default format | `json` |
| Formats that work | `json`, `text`, `compact` (P01, P06, P07) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| `--runner` formats | `pytest, pytest-k, jest, go-test, cargo-test` — emit per-runner command strings (not JSON) |
| Typical output size | small (~14 lines pretty JSON; runner output is single space-separated string) |

**Top-level keys (JSON, `ChangeImpactReport`):**
- `changed_files` (`array<string>`) — files detected as changed
- `affected_tests` (`array<string>`) — test files affected
- `affected_test_functions` (`array<string>`) — individual test functions affected
- `affected_functions` (`array<string>`) — non-test functions touched by ripple
- `detection_method` (`string`) — observed: `"git:HEAD"`, `"explicit"`. Likely also `"git:base"`, `"git:staged"`, `"git:uncommitted"`.
- `metadata` (`object`) — `{ language, call_graph_nodes, call_graph_edges, analysis_depth }`
- `status` (`object`) — `{ kind: "NoChanges" | "ChangesDetected" | ... }`

**`--runner <X>` output mode (P17, P18, P20):** REPLACES JSON output with per-runner command-line strings (e.g., pytest: space-separated test files; jest: `--findRelatedTests file1 file2`; cargo-test: filter strings). When no tests are affected: EMPTY OUTPUT (P17: 0 lines stdout).

**Empty-result shape (P01, no changes):**
```json
{
  "changed_files": [], "affected_tests": [], "affected_test_functions": [],
  "affected_functions": [], "detection_method": "git:HEAD",
  "metadata": { "language": "typescript", "call_graph_nodes": 11853, "call_graph_edges": 11853, "analysis_depth": 10 },
  "status": { "kind": "NoChanges" }
}
```
Exit 0.

**Error shapes:**
- Path not found: `"Error: Path not found: /no/such/dir"` → exit **1**
- File as PATH: `"Error: change-impact requires a directory; got file '<file>'. Pass the project root or omit the argument to use the current directory."` → exit **1** (best-in-class wording via `cli-error-clarity-v2 P2.BUG-4`)
- Bad `--base` ref: `"ERROR: change-impact: no baseline (Invalid argument base: Branch '<X>' not found. fatal: Needed a single revision\n\nHint: Check branch name with: git branch -a). Try --files <path> or --base <ref>."` → exit **3** (distinct exit code!)
- Empty / non-git dir: `"ERROR: change-impact: no baseline (Invalid argument git: Git diff failed: ...)"` → exit **3**
- Format reject sarif/dot: `"Error: --format sarif not supported by change-impact. ..."` → exit **1**
- Bad `--runner`: clap-style with full list `[pytest, pytest-k, jest, go-test, cargo-test]` → exit **2**
- Bad `--lang`: clap-style → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr change-impact` | happy (default git:HEAD, no changes) | 0 | [`01-happy.*`](./change-impact.probes/) |
| P02 | `tldr change-impact -F <files>` | happy-scale (explicit files) | 0 | [`02-happy-scale.*`](./change-impact.probes/) |
| P03 | N/A: PATH defaults to `.`. | — | — | [`03-missing-arg.*`](./change-impact.probes/) (placeholder) |
| P04 | `tldr change-impact /no/such/dir` | failure-badpath | 1 | [`04-badpath.*`](./change-impact.probes/) |
| P05 | `tldr change-impact -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./change-impact.probes/) |
| P06 | `tldr change-impact -f text` | format-text | 0 | [`06-format-text.*`](./change-impact.probes/) |
| P07 | `tldr change-impact -f compact` | format-compact | 0 | [`07-format-compact.*`](./change-impact.probes/) |
| P08 | `tldr change-impact -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./change-impact.probes/) |
| P09 | `tldr change-impact --base origin/main` | bad git base (exit 3 with hint) | 3 | [`09-base-flag.*`](./change-impact.probes/) |
| P10 | `tldr change-impact --base HEAD~1` | base HEAD~1 | 0 | [`10-base-head-1.*`](./change-impact.probes/) |
| P11 | `tldr change-impact --staged` | staged-only | 0 | [`11-staged.*`](./change-impact.probes/) |
| P12 | `tldr change-impact --uncommitted` | uncommitted | 0 | [`12-uncommitted.*`](./change-impact.probes/) |
| P13 | `tldr change-impact -F <file> --depth 1` | shallow depth | 0 | [`13-depth-low.*`](./change-impact.probes/) |
| P14 | `tldr change-impact -F <file> --depth 0` | depth zero | 0 | [`14-depth-zero.*`](./change-impact.probes/) |
| P15 | `tldr change-impact -F <file> --include-imports` | include-imports (default true) | 0 | [`15-include-imports.*`](./change-impact.probes/) |
| P16 | `tldr change-impact -F <file> --test-patterns '...'` | custom test patterns | 0 | [`16-test-patterns.*`](./change-impact.probes/) |
| P17 | `tldr change-impact -F <file> --runner pytest` | pytest runner output (empty when 0 tests) | 0 | [`17-runner-pytest.*`](./change-impact.probes/) |
| P18 | `tldr change-impact -F <file> --runner jest` | jest runner output | 0 | [`18-runner-jest.*`](./change-impact.probes/) |
| P19 | `tldr change-impact --runner wat` | bad runner | 2 | [`19-runner-bogus.*`](./change-impact.probes/) |
| P20 | `tldr change-impact -F <file> --runner cargo-test` | cargo-test runner | 0 | [`20-runner-cargo.*`](./change-impact.probes/) |
| P21 | `tldr change-impact -l brainfuck` | bad-lang | 2 | [`21-bad-lang.*`](./change-impact.probes/) |
| P22 | `tldr change-impact -l python` | explicit python | 0 | [`22-lang-python.*`](./change-impact.probes/) |
| P23 | `tldr change-impact -l typescript` | explicit typescript | 0 | [`23-lang-mismatch.*`](./change-impact.probes/) |
| P24 | `tldr change-impact <file>` | file-as-PATH (best error!) | 1 | [`24-file-as-path.*`](./change-impact.probes/) |
| P25 | `tldr change-impact <empty-git-dir>` | empty git dir (no HEAD) | 3 | [`25-empty-dir.*`](./change-impact.probes/) |
| P26 | `tldr change-impact <non-git>` | non-git dir | 3 | [`26-non-git.*`](./change-impact.probes/) |
| P27 | `tldr change-impact -q` | quiet | 0 | [`27-quiet.*`](./change-impact.probes/) |

### Observations

- **P01** — Stock-Monitor root, no uncommitted changes: `changed_files: [], status: { kind: "NoChanges" }, detection_method: "git:HEAD"`. `metadata.language: "typescript"` (autodetect picks webui/), `call_graph_nodes: 11853`. Exit 0.
- **P02** — `-F backend/providers/yahoo.py,backend/providers/dhan.py`: STILL `changed_files: []`! `detection_method: "explicit"` but the files weren't accepted. Likely the autodetected language (typescript) filtered them out — explicit Python files don't match the TS call graph. **Silent lang-filter.**
- **P03** — **N/A.** PATH defaults to `.`.
- **P04** — stderr `"Error: Path not found: /no/such/dir"`, exit `1`. Standard wording.
- **P05** — stderr `"Error: --format sarif not supported by change-impact. ..."`, exit `1`.
- **P06** — Text format: 9 lines — `"Change Impact Analysis\n======================\n\nDetection: git:HEAD\nChanged: 0 files\n\nAffected Tests: 0 files, 0 functions\n  No tests affected.\n\nCall Graph: 11853 edges\nTraversal Depth: 10"`. Clean tabular.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by change-impact. ..."`, exit `1`.
- **P09** — **EXIT 3 (distinct!):** stderr `"ERROR: change-impact: no baseline (Invalid argument base: Branch 'origin/main' not found. fatal: Needed a single revision\n\nHint: Check branch name with: git branch -a). Try --files <path> or --base <ref>."` Includes BOTH the git error AND a hint to try `--files` or check `--base`. **Best-in-ops error message.** Distinct exit code 3 (not 1 or 2 — likely TldrError variant for "no baseline").
- **P10** — `--base HEAD~1`: works, no changes from HEAD~1 to HEAD in this scope.
- **P11** — `--staged`: works, no staged changes.
- **P12** — `--uncommitted`: works.
- **P13** — `--depth 1`: shallow traversal; `metadata.analysis_depth: 1`.
- **P14** — `--depth 0`: depth zero; `analysis_depth: 0`. **No traversal.**
- **P15** — `--include-imports`: per `--help`, default is true. Setting it explicitly has no observable diff.
- **P16** — `--test-patterns '*_test.py,test_*.py'`: custom globs accepted.
- **P17** — `--runner pytest`: **OUTPUT IS EMPTY** (0 lines stdout) when no affected tests. Runner mode REPLACES JSON output with a runner-formatted string; empty when no tests affected.
- **P18** — `--runner jest`: same empty result.
- **P19** — clap-style: `"error: invalid value 'wat' for '--runner <RUNNER>' [possible values: pytest, pytest-k, jest, go-test, cargo-test]"`, exit `2`.
- **P20** — `--runner cargo-test`: empty output.
- **P21** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P22** — `-l python` explicit: `metadata.language: "python", call_graph_nodes: 2715` (different graph from TS autodetect's 11853). Confirms `-l` IS effective.
- **P23** — `-l typescript`: same as P01 autodetect.
- **P24** — **BEST-IN-CLASS error:** `tldr change-impact backend/providers/yahoo.py` (file as PATH): stderr `"Error: change-impact requires a directory; got file 'backend/providers/yahoo.py'. Pass the project root or omit the argument to use the current directory."`, exit `1`. Source comment `cli-error-clarity-v2 P2.BUG-4`: replaces cryptic "Git: Not a directory (os error 20)" with this clear message.
- **P25** — Empty (fresh `git init`) dir: stderr `"ERROR: change-impact: no baseline (Invalid argument git: Git diff failed: fatal: ambiguous argument 'HEAD': unknown revision or path not in the working tree...). Try --files <path> or --base <ref>."`, exit **3**. Same hint as P09.
- **P26** — Non-git dir: stderr `"ERROR: change-impact: no baseline (Invalid argument git: Git diff failed: warning: Not a git repository...)"`, exit **3**. Same shape.
- **P27** — `-q`: suppresses progress (none observed).

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/change_impact.rs` (~250+ lines)
- `crates/tldr-core/src/analysis/change_impact.rs` (call-graph + impact analysis)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/change_impact.rs:31-78
#[derive(Debug, Args)]
pub struct ChangeImpactArgs {
    #[arg(default_value = ".")] pub path: PathBuf,
    #[arg(long, short = 'l')] pub lang: Option<Language>,
    #[arg(long, short = 'F', value_delimiter = ',')] pub files: Vec<PathBuf>,
    #[arg(long, short = 'b')] pub base: Option<String>,
    #[arg(long)] pub staged: bool,
    #[arg(long)] pub uncommitted: bool,
    #[arg(long, short = 'd', default_value = "10")] pub depth: usize,
    #[arg(long, default_value = "true")] pub include_imports: bool,
    #[arg(long, value_delimiter = ',')] pub test_patterns: Vec<String>,
    #[arg(long = "output-format", short = 'o', hide = true)] pub output_format: Option<OutputFormat>,
    #[arg(long, value_enum)] pub runner: Option<RunnerFormat>,
}
```
Reveals: `--files -F` uses CAPITAL F (lower `-f` is the global format flag — no conflict here). `--base -b` for git base. Legacy hidden `-o --output-format`. `--runner` is a typed enum.

**Detection method priority (source):**
```rust
// change_impact.rs:97-110
fn determine_detection_method(&self) -> DetectionMethod {
    if !self.files.is_empty() { DetectionMethod::Explicit }
    else if let Some(base) = &self.base { DetectionMethod::GitBase { base: base.clone() } }
    else if self.staged { DetectionMethod::GitStaged }
    else if self.uncommitted { DetectionMethod::GitUncommitted }
    else { DetectionMethod::GitHead }
}
```
Reveals: clear priority — `--files` always wins. Conflicting flags (`--staged --uncommitted`) silently take the earlier flag (staged).

**File-as-path validation (P24 best-in-class wording):**
```rust
// change_impact.rs:116-119 (cli-error-clarity-v2 P2.BUG-4)
require_directory(&self.path, "change-impact")?;
```
Reveals: `require_directory` helper produces the clear error message. The source comment explicitly says "reject regular files up-front so callers don't get the cryptic 'Git: Not a directory (os error 20)' surfaced from the git invocation downstream." Premortem-driven fix.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `change-impact` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route change_impact.rs` returns 0 matches.

---

## Architectural Deep Dive

- **Under the hood:** Determines changed files via git diff or explicit list. Builds call graph (via tldr-core's call graph builder) for the project. Walks the graph FROM each changed file's defined functions, propagating "affected" status to callers up to `--depth` levels. Identifies test files via heuristic OR `--test-patterns`. Emits affected tests in JSON or per-runner CLI format.
- **Performance:** Cold call-graph build is the cost: ~1-10s on moderate codebases. NO daemon caching. Stock-Monitor TS graph has 11,853 nodes; Python has 2,715.
- **LLM cognitive load:** PR-CI optimization. The `--runner` mode is the killer feature: `tldr change-impact --base origin/main --runner pytest | xargs pytest` runs only the tests affected by the PR. Massively faster than full test suite.

---

## Intent & Routing

- **User/Agent Goal:** identify tests affected by code changes — for CI optimization (only run impacted tests) and code-review focus.
- **When to choose this over similar tools:**
  - Over `tldr impact` / `tldr calls`: impact is per-function; change-impact is git-diff-driven across multiple changed files.
  - Over `tldr bugbot`: bugbot finds BUGS in changed code; change-impact finds AFFECTED TESTS.
  - Over running full test suite: drastically faster CI.
- **Prerequisites (composition):**
  - PATH must be a DIRECTORY (P24 rejects files with best-in-class error).
  - Project must be in a git working tree (P25, P26).
  - For PR workflows: `--base origin/main` (P09 hints when ref is wrong).
  - For runner integration: `--runner pytest` pipes into pytest.

---

## Agent Synthesis

> **How to use `tldr change-impact`:**
> Git-diff-driven test-impact analyzer. `tldr change-impact [PATH]` returns JSON `{ changed_files, affected_tests, affected_test_functions, affected_functions, detection_method, metadata: { language, call_graph_nodes, call_graph_edges, analysis_depth }, status: { kind } }`. Detection method priority: `-F --files <list>` > `-b --base <ref>` > `--staged` > `--uncommitted` > default `git:HEAD`. `--runner pytest|pytest-k|jest|go-test|cargo-test` REPLACES JSON with per-runner CLI strings. Default `--depth 10`, `--include-imports true`. Default JSON; `-f text` for tabular; `-f compact` for one-line; `sarif`/`dot` rejected. Exit codes: 0 ok, 1 path-not-found / file-as-path / format-reject, 2 bad-runner / bad-lang, 3 git-baseline-failure.
>
> **Crucial Rules:**
> - **EXIT CODE 3 IS SPECIFIC TO GIT-BASELINE FAILURES.** P09 (bad --base), P25 (empty git dir), P26 (non-git dir) all return exit 3 with message format `"ERROR: change-impact: no baseline (...). Try --files <path> or --base <ref>."` **The hint is built-in** — agents seeing exit 3 should consider passing `--files` explicitly to bypass git detection.
> - **File-as-PATH error is BEST-IN-CLASS** (P24, `cli-error-clarity-v2 P2.BUG-4`): `"Error: change-impact requires a directory; got file '<file>'. Pass the project root or omit the argument to use the current directory."` Premortem-driven fix replacing cryptic git error.
> - **`-F` (CAPITAL F) is `--files`**, distinct from lowercase `-f --format`. No clap conflict — capital F is intentional.
> - **`-l <lang>` is EFFECTIVE.** P22 vs P01: `-l python` produces a different call graph (2,715 vs 11,853 TS nodes). On multi-language projects, autodetect picks the dominant language (TS on Stock-Monitor) — explicit `-l python` is REQUIRED for Python-focused analysis.
> - **`-F` explicit files don't override language autodetect.** P02: `-F backend/providers/*.py` (Python) on autodetected-TypeScript project STILL returned `changed_files: []`. Solution: combine `-F` with `-l python` to get Python files into a Python call graph.
> - **`--runner <X>` REPLACES JSON output** with per-runner CLI strings (e.g., pytest: space-separated; jest: `--findRelatedTests`; cargo-test: filter). When NO tests are affected: EMPTY stdout (P17). **Use `--runner` for direct CI integration**: `tldr change-impact --base origin/main --runner pytest | xargs pytest`.
> - **Detection priority** (source: `determine_detection_method`): `--files` > `--base` > `--staged` > `--uncommitted` > default `git:HEAD`. Conflicting flags silently take the FIRST in priority order.
> - **`--depth 0` is a VALID value** (P14) — zero traversal means changed files are reported as affected but NO callers/imports propagated. Use for "just give me changed files" workflows.
> - **PATH MUST be a directory** (P24, runtime check via `require_directory`). Use `.` or a parent dir.
> - **`metadata.call_graph_nodes`** is the project's call graph size — useful for diagnosing why analysis is slow.
> - **NO daemon route.** Every call re-builds the call graph from scratch.
>
> **Command:** `tldr change-impact [PATH] [--files <LIST> | --base <REF> | --staged | --uncommitted]`
>
> **With common flags:** `tldr change-impact --base origin/main --runner pytest -l python | xargs -r pytest -v` (use for PR CI: run only Python tests affected by the PR diff against origin/main).
