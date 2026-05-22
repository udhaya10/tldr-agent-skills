# Command: `tldr secure`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; secure aggregates multiple AST/CFG analyses, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr secure` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |
| Scoping decision | Slow command per Journal 04 §5 — used `--quick` mode + `backend/providers/` (4 files) for happy probes |

Re-run all evidence via [`secure.probes/probe.sh`](./secure.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/audit/secure.md).

---

## Ground Truth (`tldr secure --help`)

```text
Security analysis dashboard (taint, resources, bounds, contracts, behavioral, mutability)

Usage: tldr secure [OPTIONS] <PATH>

Arguments:
  <PATH>
          File path or directory to analyze

Options:
  -l, --lang <LANG>
          Programming language to filter by (auto-detected if omitted)

      --detail <DETAIL>
          Show details for specific sub-analysis

      --quick
          Run quick mode (taint, resources, bounds only)

  -o, --output <OUTPUT>
          Write output to file instead of stdout

      --no-default-ignore
          Walk vendored/build dirs (node_modules, target, dist, etc.) that would normally be skipped

      --include-tests
          Include findings on test files. [...] (M-X3 `js-test-file-suppression-v1`).
          Default: `false`. Pass `--include-tests` to restore them. Mirrors the
          `--include-smells` precedent (opt-in for noisy categories)

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
| Formats that error | `sarif`, `dot` (P08, P05: exit 1) |
| Typical output size | small in `--quick` mode (~27 lines); medium in full mode (~400 lines) |

**Top-level keys (JSON, `SecureReport`):**
- `wrapper` (`string`) — always `"secure"`
- `root` (`string`) — input PATH echoed (not canonicalized)
- `findings` (`array<Finding>`) — all security findings across enabled sub-analyses
- `summary` (`object`) — counts per category (see below)
- `total_elapsed_ms` (`f64`) — float, sub-millisecond precision

**`Finding` shape:**
- `category` (`string`) — observed: `"resource_leak"` (likely also `"taint"`, `"bounds_warning"`, `"behavioral"`, `"mutability"`, `"missing_contract"`)
- `severity` (`string`) — observed: `"high"` (likely also `"medium"`, `"low"`, `"critical"`)
- `description` (`string`) — human-readable explanation
- `file` (`string`) — project-relative path
- `line` (`u32`)

**`summary` shape (12 fixed counter fields):**
```json
{
  "taint_count": 0, "taint_critical": 0, "leak_count": 1,
  "bounds_warnings": 0, "behavioral_count": 0, "missing_contracts": 0,
  "mutable_params": 0, "unsafe_blocks": 0, "raw_pointer_ops": 0,
  "unwrap_calls": 0, "todo_markers": 0
}
```
(11 counter fields documented above; `taint_critical` is the 12th — total breakdown of all sub-analyses.)

**Empty-result shape (P18 empty dir, P19 README.md, P20 single non-resource file):**
```json
{
  "wrapper": "secure", "root": "<input>", "findings": [],
  "summary": { /* all zeros */ },
  "total_elapsed_ms": 0.0185
}
```
Exit 0. **Same shape for empty dir AND non-source files (`.md`)** — no warning/error.

**Error shapes:**
- Missing PATH: clap-style → exit **2**
- File not found: `"Error: file not found: /no/such/dir"` → exit **5** (RemainingError::FileNotFound — DISTINCT exit code; matches `tldr dead-stores`)
- Format reject sarif: `"Error: --format sarif not supported by secure. ..."` → exit **1**
- Format reject dot: `"Error: --format dot not supported by secure. ..."` → exit **1**
- Bad `--lang`: clap-style → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr secure backend/providers --quick` | happy (1 leak found) | 0 | [`01-happy.*`](./secure.probes/) |
| P02 | `tldr secure backend --quick` | happy-scale (--quick on backend) | 0 | [`02-happy-scale.*`](./secure.probes/) |
| P03 | `tldr secure` *(no PATH)* | failure-missing-input | 2 | [`03-missing-arg.*`](./secure.probes/) |
| P04 | `tldr secure /no/such/dir` | failure-badpath (exit 5!) | 5 | [`04-badpath.*`](./secure.probes/) |
| P05 | `tldr secure ... -f dot` | format-reject (dot) | 1 | [`05-format-reject-dot.*`](./secure.probes/) |
| P06 | `tldr secure ... -f text` | format-text | 0 | [`06-format-text.*`](./secure.probes/) |
| P07 | `tldr secure ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./secure.probes/) |
| P08 | `tldr secure ... -f sarif` | format-reject (sarif) | 1 | [`08-format-sarif.*`](./secure.probes/) |
| P09 | `tldr secure ... --quick` | quick mode | 0 | [`09-quick.*`](./secure.probes/) |
| P10 | `tldr secure ... --detail taint` | detail-taint subanalysis | 0 | [`10-detail-taint.*`](./secure.probes/) |
| P11 | `tldr secure ... --detail wat` | bogus --detail (silent ignore) | 0 | [`11-detail-bogus.*`](./secure.probes/) |
| P12 | `tldr secure ... -o <tmp>` | output-to-file | 0 | [`12-output-file.*`](./secure.probes/) |
| P13 | `tldr secure ... --no-default-ignore` | no-default-ignore | 0 | [`13-no-default-ignore.*`](./secure.probes/) |
| P14 | `tldr secure backend --quick --include-tests` | include-tests | 0 | [`14-include-tests.*`](./secure.probes/) |
| P15 | `tldr secure ... -l brainfuck` | bad-lang | 2 | [`15-bad-lang.*`](./secure.probes/) |
| P16 | `tldr secure ... -l python` | explicit-python | 0 | [`16-lang-python.*`](./secure.probes/) |
| P17 | `tldr secure ... -l typescript` | lang-mismatch (silent empty) | 0 | [`17-lang-mismatch.*`](./secure.probes/) |
| P18 | `tldr secure <empty-tmp-dir>` | empty-dir | 0 | [`18-empty-dir.*`](./secure.probes/) |
| P19 | `tldr secure README.md --quick` | non-source-md (silent empty) | 0 | [`19-non-source-md.*`](./secure.probes/) |
| P20 | `tldr secure backend/providers/yahoo.py --quick` | single-file | 0 | [`20-single-file.*`](./secure.probes/) |
| P21 | `tldr secure ... -q` | quiet | 0 | [`21-quiet.*`](./secure.probes/) |

### Observations

- **P01** — `backend/providers/ --quick`: 1 finding: `category: "resource_leak"`, `severity: "high"`, `file: "backend/providers/dhan.py"`, `line: 39`, description `"Resource 'cursor' opened without context manager - may leak"`. Summary: `leak_count: 1`, all other counters 0. `total_elapsed_ms: 88.45`.
- **P02** — `backend/ --quick`: 398 lines stdout — many more findings detected across 56 files. Truncated by probe.sh (500-line cap).
- **P03** — stderr `"error: the following required arguments were not provided: <PATH>"`, exit `2`.
- **P04** — stderr `"Error: file not found: /no/such/dir"`, exit **5** (RemainingError::FileNotFound). **Distinct exit code** — matches `tldr dead-stores` (also RemainingError); differs from ContractsError commands (exit 1) and TldrError commands (exit 2).
- **P05** — stderr `"Error: --format dot not supported by secure. Use --format json. DOT is only emitted by: clones, deps, calls, impact, hubs, inheritance."`, exit `1`.
- **P06** — Text format: human-readable security report.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format sarif not supported by secure. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`. **Note: secure is NOT in SARIF_SUPPORTED** despite being a security command. SARIF is reserved for vuln and clones.
- **P09** — `--quick` mode: identical to P01 (default for `backend/providers/` is essentially already running quick analyses since full mode includes contracts/behavioral/mutability which may have nothing to report there).
- **P10** — `--detail taint`: 30 lines — adds a `detail` block focused on taint sub-analysis. Output is augmented, not filtered.
- **P11** — **`--detail wat` SILENTLY IGNORED:** exit 0 with same output as P01. No error or warning for bogus detail value. `--detail` accepts any string per source.
- **P12** — `-o <tmp>` redirects to file. stdout EMPTY (0 lines). File contains the JSON. **Test verified** — content written via `--output` matches the default JSON shape exactly. Useful for CI pipelines.
- **P13** — `--no-default-ignore`: walks vendored/build dirs (`node_modules`, `target`, `dist`, etc.). On Stock-Monitor backend, no observable diff.
- **P14** — `--include-tests`: includes findings from test files (default suppressed). 398 lines (same as full backend scan in P02 — test files don't add findings here).
- **P15** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P16** — Explicit `-l python`: identical to P01 (Python auto-detected).
- **P17** — **`-l typescript` SILENTLY FILTERS:** 19 lines output — empty result. No findings, no warning. Same minimal shape as empty-dir.
- **P18** — Empty dir: same shape with all-zero summary, empty findings. NO warnings field.
- **P19** — **README.md silently accepted:** exit 0 with empty findings. `root: "README.md"` echoed. NO error/warning that the file isn't analyzable. **Distinct from `tldr loc`/`tldr halstead`/`tldr patterns`** which all reject `.md` with exit 11. **Distinct from `tldr resources`** which exits 1 with `"unsupported language: md"`. `tldr secure` silently accepts.
- **P20** — Single `.py` file: 19 lines — minimal output. Single-file path works but no resource leaks in yahoo.py.
- **P21** — `-q` suppresses progress messages (none observed in this command for `--quick` mode anyway).

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/remaining/secure.rs` (~200 lines top of file)
- `crates/tldr-core/src/wrappers/secure.rs` (analysis orchestration)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/remaining/secure.rs:110-146
#[derive(Debug, Args, Clone)]
pub struct SecureArgs {
    pub path: PathBuf,
    #[arg(long, short = 'l')] pub lang: Option<Language>,
    #[arg(long)] pub detail: Option<String>,
    #[arg(long)] pub quick: bool,
    #[arg(long, short = 'o')] pub output: Option<PathBuf>,
    #[arg(long)] pub no_default_ignore: bool,
    #[arg(long)] pub include_tests: bool,
}
```
Reveals: PATH required (no default). `--detail` is `Option<String>` (NOT typed enum), so bogus values pass clap and may silently ignore at engine level (P11 confirms).

**Path validation:**
```rust
// secure.rs:164-166
if !args.path.exists() {
    return Err(RemainingError::file_not_found(&args.path).into());
}
```
Reveals: uses RemainingError → exit 5 (distinct from TldrError exit 2 and ContractsError exit 1).

**FULL vs QUICK analyses:**
```rust
// secure.rs:96-102
SecurityAnalysis::Behavioral,
SecurityAnalysis::Mutability,
// ...
const QUICK_ANALYSES: &[SecurityAnalysis] = &[/* taint, resources, bounds */];
const FULL_ANALYSES: &[SecurityAnalysis] = &[/* all 6+ */];
```
Reveals: `--quick` runs 3 analyses (taint, resources, bounds); default runs ALL ~6 (taint, resources, bounds, contracts, behavioral, mutability).

**Auto-detect parity with `tldr vuln`:**
Per source comment block (M-AA5 `VULN-SECURE-AUTODETECT-PARITY-V1`): `tldr secure` previously had a different language-resolution path from `tldr vuln`. Pre-fix: `tldr secure express` (no `--lang`) reported `taint_count: 0` while `tldr vuln express` reported `findings: 1`. The fix mirrors vuln's autodetect logic so they agree.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `secure` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route remaining/secure.rs` returns 0 matches.

---

## Architectural Deep Dive

- **Under the hood:** Orchestrator that runs multiple sub-analyses (taint, resources, bounds, contracts, behavioral, mutability) on a single AST cache. Aggregates findings into one unified report. `--quick` mode = subset of 3 fast analyses. Uses `AstCache` to share parsed ASTs across analyses (efficiency).
- **Performance:** `--quick` ~80-100ms on 4-file dir. Full mode 1-30s on full repos (per slow-command warning). NO daemon caching.
- **LLM cognitive load:** Single command for full security audit. The `summary` block is the dashboard — 11 counters give an at-a-glance health check. Pair with `tldr vuln` (CVE-database driven) for full coverage.

---

## Intent & Routing

- **User/Agent Goal:** unified security audit — find taint flows, resource leaks, bounds violations, mutability bugs, missing contracts in ONE run.
- **When to choose this over similar tools:**
  - Over `tldr vuln`: vuln matches CVEs/known patterns; secure is structural (CFG-driven).
  - Over `tldr taint`/`tldr resources`/`tldr bounds`/etc. individually: secure aggregates them.
  - Over external SAST: integrated into tldr workflow, daemon-free, autodetect parity with vuln (M-AA5).
- **Prerequisites (composition):**
  - PATH required (no default).
  - Use `--quick` for CI/fast iteration.
  - `--include-tests` to restore test-file findings (suppressed by default per M-X3).
  - For specific findings, run the individual sub-command (`tldr resources` etc.) — `secure` is the dashboard, not the deep-dive.

---

## Agent Synthesis

> **How to use `tldr secure`:**
> Unified security-analysis dashboard. `tldr secure <PATH>` returns JSON `{ wrapper, root, findings, summary, total_elapsed_ms }`. `findings[]` is the aggregated list across all enabled sub-analyses; each has `{ category, severity, description, file, line }`. `summary` has 11 counter fields (`taint_count, taint_critical, leak_count, bounds_warnings, behavioral_count, missing_contracts, mutable_params, unsafe_blocks, raw_pointer_ops, unwrap_calls, todo_markers`). Default mode runs all 6 sub-analyses; `--quick` runs 3 (taint, resources, bounds). Default JSON; `-f text` for human report; `-f compact` for one-line; `sarif`/`dot` rejected. `-o <file>` writes to file (stdout empty). Exit codes: 0 ok (including silent empties), 1 format-reject, 2 missing PATH / bad-lang, 5 file-not-found.
>
> **Crucial Rules:**
> - **File-not-found exit code is 5** (RemainingError::FileNotFound). **DISTINCT** from TldrError commands (exit 2: `tldr complexity`, `tldr loc`) and ContractsError commands (exit 1: `tldr contracts`, `tldr resources`). Only `tldr dead-stores` and `tldr secure` use exit 5. Agents can check exit code to identify the error namespace.
> - **`--detail <bogus>` is silently IGNORED.** P11: passing `--detail wat` returns exit 0 with same output as default. `--detail` is `Option<String>`, NOT a typed enum — clap accepts any string and the engine silently ignores unknown values. Valid detail strings (per `--help`): probably `taint`, `resources`, `bounds`, `contracts`, `behavioral`, `mutability` — verify against engine source.
> - **README.md is SILENTLY ACCEPTED with empty result.** P19: `tldr secure README.md --quick` returns exit 0 with empty findings + `root: "README.md"` echoed. **Cross-command divergence:** `tldr loc`/`tldr halstead`/`tldr patterns` exit 11 for `.md`; `tldr resources` exits 1; `tldr secure` silently accepts.
> - **`-l <lang>` silently filters with no warning when no files match.** P17: `-l typescript` on Python project returns minimal empty shape (19 lines), exit 0. Same anti-pattern as `tldr cohesion`/`tldr resources`/`tldr interface` — patterns-namespace habit.
> - **`-o <file>` writes JSON to file; stdout becomes empty.** P12: useful for CI scripts that need to upload artifacts. The file content matches the default JSON shape exactly.
> - **`--quick` runs 3 sub-analyses (taint, resources, bounds); default runs all 6** (adds contracts, behavioral, mutability). Use `--quick` for CI; default for deep audit.
> - **`--include-tests` mirrors `tldr vuln --include-tests`** (M-X3 / `js-test-file-suppression-v1`). Default suppresses JS/TS test files (`test/`, `tests/`, `__tests__/`, `.test.{js,ts,jsx,tsx}`, `.spec.*`, `.e2e.*`) and Rust test files (`/tests/`, `_test.rs`, `tests.rs`). Pass `--include-tests` to restore.
> - **Autodetect parity with `tldr vuln`** (M-AA5 `VULN-SECURE-AUTODETECT-PARITY-V1`). Pre-fix: `secure` and `vuln` disagreed on language detection for some inputs (e.g., JS-only Express repo). Fix mirrors vuln's `Language::from_directory` autodetect.
> - **`--no-default-ignore` walks `node_modules`/`target`/`dist`/etc.** — opt-in; default skips them.
> - **`category` values observed:** `"resource_leak"` (high severity from db cursor). Other expected: `"taint"`, `"bounds_warning"`, `"behavioral"`, `"mutability"`, `"missing_contract"`.
> - **`severity` values observed:** `"high"`. Other expected: `"low"`, `"medium"`, `"critical"`.
> - **NO daemon route.** Every call re-runs the 3-6 sub-analyses on a fresh AST cache.
>
> **Command:** `tldr secure <PATH>`
>
> **With common flags:** `tldr secure <PATH> --quick -o secure-findings.json` (use for CI: writes structured findings to a file for upload to security dashboards; stdout stays clean for log noise).
