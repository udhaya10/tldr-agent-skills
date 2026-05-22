# Command: `tldr diagnostics`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; diagnostics shells out to external tools, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| External tools detected | `pyright 1.1.409`, `ruff 0.15.12` |
| Daemon state at probe time | N/A — `tldr diagnostics` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |
| Scoping decision | Used `--timeout 10` on most probes (default 60 wastes CI time); single file in P01 for fastest happy path |

Re-run all evidence via [`diagnostics.probes/probe.sh`](./diagnostics.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/fix/diagnostics.md).

---

## Ground Truth (`tldr diagnostics --help`)

```text
Run type checking and linting

Usage: tldr diagnostics [OPTIONS] [PATH]

Arguments:
  [PATH]                  [default: .]

Options:
  -l, --lang <LANG>
      --tools <TOOLS>     Specific tools to run (comma-separated, e.g., "pyright,ruff")
      --no-typecheck      Skip type checking (linters only)
      --no-lint           Skip linting (type checkers only)
  -s, --severity <SEVERITY>  [error|warning|info|hint] [default: hint]
      --ignore <IGNORE>   Ignore specific error codes (comma-separated)
      --output <OUTPUT>   [sarif|github-actions]
      --project           Analyze entire project (not just specified path)
      --max-annotations <N>  [default: 50]
      --timeout <TIMEOUT>    [default: 60]
      --strict            Fail on warnings (not just errors)
      --baseline <BASELINE>  Compare against baseline file
      --save-baseline <SAVE_BASELINE>
  -f, --format <FORMAT>  [default: json]
  -q, --quiet  -v, --verbose  -h, --help
```

**Source-documented exit codes (from `diagnostics.rs:40-41`):**
- `60`: No diagnostic tools available for language
- `61`: All tools failed to run

---

## Output Shape

| Aspect | Value |
|---|---|
| Default format | `json` |
| Formats that work | `json`, `text`, `compact` (P01, P06, P07) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1 via `validate_format_for_command`) — but `--output sarif` IS supported separately! |
| `--output` formats | `sarif` (SARIF 2.1.0), `github-actions` (workflow commands) |
| Typical output size | small (~21 lines pretty JSON; SARIF ~16; GitHub Actions ~3 lines per file) |

**Top-level keys (JSON, `DiagnosticsReport`):**
- `diagnostics` (`array<Diagnostic>`) — all findings
- `summary` (`object`) — `{ errors, warnings, info, hints, total }`
- `tools_run` (`array<ToolRun>`) — `{ name, version, success, duration_ms, diagnostic_count, error }`
- `files_analyzed` (`u32`)

**`Diagnostic` shape:**
- `file` (`string`) — ABSOLUTE path
- `line` (`u32`), `column` (`u32`), `end_line` (`u32`), `end_column` (`u32`)
- `severity` (`string`) — `"error"`, `"warning"`, `"info"`, `"hint"`
- `message` (`string`) — human-readable
- `code` (`string`) — tool-specific code (e.g., `"reportMissingImports"`, `"E902"`)
- `source` (`string`) — tool name (e.g., `"pyright"`, `"ruff"`)
- `url` (`string` | `null`) — documentation URL for the rule

**`--output sarif`** emits SARIF 2.1.0 schema:
```json
{
  "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/.../sarif-schema-2.1.0.json",
  "version": "2.1.0",
  "runs": [{ "tool": { "driver": { "name": "tldr-diagnostics", "version": "0.4.0", ... } }, "results": [...] }]
}
```

**`--output github-actions`** emits GitHub Actions workflow commands:
```text
::group::Diagnostics Summary
Errors: N, Warnings: N, Info: N, Hints: N
::endgroup::
::error file=X,line=Y::message
::warning file=X,line=Y::message
```

**Error shapes:**
- Bad path: **exit 0 with ruff's `E902 io-error` warning** (NO upfront path validation — engine shells out to tools, tools report the path error)
- No tools installed for language: `"Note: No diagnostic tools available for Python. Install one of: pyright (pip install pyright), ruff (pip install ruff)"` → exit **60** (TldrError::NoToolsAvailable — distinct exit code)
- Format reject sarif: `"Error: --format sarif not supported by diagnostics. Use --format json. SARIF is only emitted by: vuln, clones."` → exit **1** (note: `-f sarif` is REJECTED but `--output sarif` is SUPPORTED — different paths!)
- Bad `--severity`: clap-style `"[possible values: error, warning, info, hint]"` → exit **2**
- Bad `--output`: clap-style `"[possible values: sarif, github-actions]"` → exit **2**
- Bad `--lang`: clap-style → exit **2**
- **Errors found**: exit **1** (P01: 2 missing-import errors → exit 1)
- **Strict mode finds warnings**: exit **1** (per source `--strict` "Fail on warnings")

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr diagnostics yahoo.py --timeout 10` | happy (pyright+ruff find errors) | 1 | [`01-happy.*`](./diagnostics.probes/) |
| P02 | `tldr diagnostics backend/providers --timeout 10` | happy-scale | 1 | [`02-happy-scale.*`](./diagnostics.probes/) |
| P03 | N/A: PATH defaults to `.`. | — | — | [`03-missing-arg.*`](./diagnostics.probes/) (placeholder) |
| P04 | `tldr diagnostics /no/such/dir` | bad-path (NO upfront validation!) | 0 | [`04-badpath.*`](./diagnostics.probes/) |
| P05 | `tldr diagnostics ... -f sarif` | -f sarif REJECTED | 1 | [`05-format-reject-sarif.*`](./diagnostics.probes/) |
| P06 | `tldr diagnostics ... -f text` | format-text | 1 | [`06-format-text.*`](./diagnostics.probes/) |
| P07 | `tldr diagnostics ... -f compact` | format-compact | 1 | [`07-format-compact.*`](./diagnostics.probes/) |
| P08 | `tldr diagnostics ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./diagnostics.probes/) |
| P09 | `tldr diagnostics ... --tools ruff` | tools=ruff only | 0 | [`09-tools-ruff.*`](./diagnostics.probes/) |
| P10 | `tldr diagnostics ... --tools wat` | bogus tool → no tools avail (exit 60!) | 60 | [`10-tools-bogus.*`](./diagnostics.probes/) |
| P11 | `tldr diagnostics ... --no-typecheck` | skip type-check (ruff only) | 0 | [`11-no-typecheck.*`](./diagnostics.probes/) |
| P12 | `tldr diagnostics ... --no-lint` | skip lint (pyright only) | 1 | [`12-no-lint.*`](./diagnostics.probes/) |
| P13 | `tldr diagnostics ... -s error` | severity error filter | 0 | [`13-severity-error.*`](./diagnostics.probes/) |
| P14 | `tldr diagnostics ... -s wat` | bad severity | 2 | [`14-severity-bogus.*`](./diagnostics.probes/) |
| P15 | `tldr diagnostics ... --ignore E501,F401` | ignore codes | 0 | [`15-ignore-codes.*`](./diagnostics.probes/) |
| P16 | `tldr diagnostics ... --output sarif` | SARIF output (SUPPORTED!) | 0 | [`16-output-sarif.*`](./diagnostics.probes/) |
| P17 | `tldr diagnostics ... --output github-actions` | GitHub Actions format | 0 | [`17-output-github-actions.*`](./diagnostics.probes/) |
| P18 | `tldr diagnostics ... --output wat` | bad --output | 2 | [`18-output-bogus.*`](./diagnostics.probes/) |
| P19 | `tldr diagnostics ... --project` | project flag | 0 | [`19-project-flag.*`](./diagnostics.probes/) |
| P20 | `tldr diagnostics ... --strict` | strict mode | 0 | [`20-strict.*`](./diagnostics.probes/) |
| P21 | `tldr diagnostics ... --timeout 1` | timeout 1s (tool may fail) | 1 | [`21-timeout-tiny.*`](./diagnostics.probes/) |
| P22 | `tldr diagnostics ... -l brainfuck` | bad-lang | 2 | [`22-bad-lang.*`](./diagnostics.probes/) |
| P23 | `tldr diagnostics ... -l python` | explicit python | 0 | [`23-lang-python.*`](./diagnostics.probes/) |
| P24 | `tldr diagnostics <empty-tmp-dir>` | empty-dir (silent accept) | 0 | [`24-empty-dir.*`](./diagnostics.probes/) |
| P25 | `tldr diagnostics README.md` | non-source-md (silent accept) | 0 | [`25-non-source-md.*`](./diagnostics.probes/) |
| P26 | `tldr diagnostics ... -q` | quiet | 0 | [`26-quiet.*`](./diagnostics.probes/) |

### Observations

- **P01** — `yahoo.py`: pyright detects 2 missing-import errors (pandas, yfinance — likely missing from venv). `severity: "error"`, `code: "reportMissingImports"`, `source: "pyright"`. Exit **1** because errors found.
- **P02** — `backend/providers/`: 78 lines stdout — multiple errors across 4 files. Exit 1.
- **P03** — **N/A.** PATH defaults to `.`.
- **P04** — **NO UPFRONT PATH VALIDATION:** `tldr diagnostics /no/such/dir` returns **exit 0** with ruff's `E902 io-error` warning. The CLI doesn't pre-check `path.exists()` — it shells out to tools, which report the path error themselves. Exit code is "no errors found by tools" because ruff emitted a warning (not error). Distinct from most other commands which validate upfront.
- **P05** — stderr `"Error: --format sarif not supported by diagnostics. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`. **Note the inconsistency:** `-f sarif` is rejected but `--output sarif` IS supported (P16).
- **P06** — Text format: 5 lines of human-readable summary.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by diagnostics. ..."`, exit `1`.
- **P09** — `--tools ruff`: only runs ruff. `tools_run: [{ name: "ruff", version: "ruff 0.15.12", success: true, duration_ms: 110, diagnostic_count: 0 }]`. ruff finds nothing → exit 0.
- **P10** — **EXIT 60** (source-documented): `"Note: No diagnostic tools available for Python. Install one of: pyright (pip install pyright), ruff (pip install ruff)"`. When the requested tool isn't available AND no fallback tools are installed, exit code 60 with installation hint. Useful: the bogus tool name causes the "no tools" path because nothing matches.
- **P11** — `--no-typecheck`: only ruff runs (no pyright). 0 findings → exit 0.
- **P12** — `--no-lint`: only pyright runs. Errors found (same 2 missing imports) → exit 1.
- **P13** — `-s error` filters to errors only: 0 findings (ruff has only warnings/hints) → exit 0.
- **P14** — clap-style: `"error: invalid value 'wat' for '--severity <SEVERITY>' [possible values: error, warning, info, hint]"`, exit `2`.
- **P15** — `--ignore E501,F401`: ignores those codes. Same empty result.
- **P16** — **SARIF supported via `--output sarif`!** Proper SARIF 2.1.0 schema with `tool.driver.name: "tldr-diagnostics"`. **This is the THIRD command emitting SARIF** (after `vuln` and `clones`). Exit 0 when no errors.
- **P17** — `--output github-actions`: GitHub Actions workflow commands format. 3-line output: `::group::Diagnostics Summary / Errors: N, Warnings: N, ... / ::endgroup::`. CI-integrated annotation format. **Unique to this command** — no other audit/fix command emits GitHub Actions.
- **P18** — clap-style: `"error: invalid value 'wat' for '--output <OUTPUT>' [possible values: sarif, github-actions]"`, exit `2`.
- **P19** — `--project`: analyzes entire project. 0 findings on the single file scope.
- **P20** — `--strict`: fail on warnings. P20 shows 0 warnings → exit 0. With warnings present, would exit 1.
- **P21** — `--timeout 1`: 1-second per tool. Tools may not finish but errors still emitted. Exit 1.
- **P22** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P23** — Explicit `-l python`: identical to default.
- **P24** — Empty dir: exit 0 with `files_analyzed: 0, diagnostics: [], tools_run: [{ ruff, pyright }]`. **Tools ARE run on empty dir** (they each report 0 findings on empty input). Silent accept.
- **P25** — README.md: same shape as empty dir. Silent accept.
- **P26** — `-q` suppresses `"Detecting tools for Python... Running diagnostics: pyright, ruff"` progress.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/diagnostics.rs` (~150+ lines)
- `crates/tldr-core/src/diagnostics/...` (tool discovery + execution)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/diagnostics.rs:43-104
#[derive(Debug, Args)]
pub struct DiagnosticsArgs {
    #[arg(default_value = ".")] pub path: PathBuf,
    #[arg(long, short = 'l')] pub lang: Option<Language>,
    #[arg(long, value_delimiter = ',')] pub tools: Vec<String>,
    #[arg(long)] pub no_typecheck: bool,
    #[arg(long)] pub no_lint: bool,
    #[arg(long, short = 's', value_enum, default_value = "hint")] pub severity: SeverityFilter,
    #[arg(long, value_delimiter = ',')] pub ignore: Vec<String>,
    #[arg(long, value_enum)] pub output: Option<DiagnosticOutput>,
    #[arg(long)] pub project: bool,
    #[arg(long, default_value = "50")] pub max_annotations: usize,
    #[arg(long, default_value = "60")] pub timeout: u64,
    #[arg(long)] pub strict: bool,
    #[arg(long)] pub baseline: Option<PathBuf>,
    #[arg(long)] pub save_baseline: Option<PathBuf>,
}
```
Reveals: `--tools` and `--ignore` use `value_delimiter = ','` for comma-separated lists. `--output` is a SEPARATE typed enum (sarif, github-actions) — distinct from the global `-f format`. `--baseline` / `--save-baseline` enable diff-against-baseline workflows (Phase 12 — see source).

**Source-documented exit codes (lines 39-41):**
```rust
/// - 60: No diagnostic tools available for language
/// - 61: All tools failed to run
```
Reveals: TWO distinct exit codes for tool-availability failures. P10 hit 60; we didn't probe 61 (would need all tools to crash).

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `diagnostics` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`. **SARIF via `--output sarif` is a DIFFERENT mechanism** — local to this command.

**No daemon route:** `grep -n try_daemon_route diagnostics.rs` returns 0 matches.

---

## Architectural Deep Dive

- **Under the hood:** Shells out to external language-specific tools (pyright + ruff for Python; tsc + eslint for TypeScript; cargo check + clippy for Rust; etc.). Parses their JSON output and normalizes into a unified `Diagnostic` shape. `--baseline` / `--save-baseline` enable comparing against a snapshot for "show only new issues" workflows.
- **Performance:** Cold per call. Total time = max(individual tool times). Each tool capped at `--timeout 60`. Slow if tools have to cold-start (pyright is ~2-5s).
- **LLM cognitive load:** First-class CI integration command. SARIF for GitHub/GitLab Code Scanning, GitHub Actions format for native PR annotations. `--baseline` is the actionable signal — "what's new since last commit?". The unified schema across pyright/ruff/tsc/eslint/etc. means agents can write tool-agnostic post-processing.

---

## Intent & Routing

- **User/Agent Goal:** run type checkers and linters on changed code, normalized output, CI-integration friendly.
- **When to choose this over similar tools:**
  - Over `tldr bugbot`: bugbot is git-diff driven (changed files); diagnostics is path-driven (any file/dir).
  - Over running tools directly: unified schema, baseline diff, SARIF/GitHub-Actions output formats.
  - Over `tldr secure`: secure is taint-based; diagnostics is type-check + lint.
- **Prerequisites (composition):**
  - Tools (pyright/ruff/etc.) MUST be installed in PATH. Use `--tools pyright,ruff` to pin which.
  - For CI: `--output sarif` writes SARIF; `--output github-actions` writes inline workflow commands.
  - For PR-only diff: `--baseline previous.json` shows only new issues.

---

## Agent Synthesis

> **How to use `tldr diagnostics`:**
> Type-check + lint runner with unified output. `tldr diagnostics [PATH]` returns JSON `{ diagnostics, summary, tools_run, files_analyzed }`. Each `Diagnostic` has `{ file (ABSOLUTE), line, column, end_line, end_column, severity, message, code, source, url? }`. `summary: { errors, warnings, info, hints, total }`. `tools_run[]: { name, version, success, duration_ms, diagnostic_count, error }`. Default JSON; `-f text` for summary; `-f compact` for one-line; `-f sarif`/`-f dot` REJECTED. **Use `--output sarif` (not `-f sarif`) for SARIF 2.1.0 schema** (CI consumption). `--output github-actions` emits inline workflow commands. Default `--severity hint` (show everything), `--timeout 60` per tool. Exit codes: 0 ok, 1 errors-found / format-reject, 2 bad clap arg, 60 no-tools-available, 61 all-tools-failed.
>
> **Crucial Rules:**
> - **`-f sarif` is REJECTED, but `--output sarif` is SUPPORTED.** P05 vs P16. The global format validator rejects `sarif` for `diagnostics` (correct per `validate_format_for_command`), but the local `--output` flag accepts it. Use `--output sarif` for SARIF — produces proper SARIF 2.1.0 with `tool.driver.name: "tldr-diagnostics"`. **Third command emitting SARIF** in the suite (after `vuln`, `clones`).
> - **Exit code 60 means "No diagnostic tools available"** (source-documented). P10 hit it via `--tools wat`. Error message includes installation hints: `"Install one of: pyright (pip install pyright), ruff (pip install ruff)"`. Best-in-class actionable error.
> - **Exit code 61 means "All tools failed to run"** (source-documented; not probed but documented in source comment at diagnostics.rs:40-41).
> - **`--output github-actions` is UNIQUE TO THIS COMMAND.** Emits inline `::error::` / `::warning::` workflow commands for native GitHub PR annotations. No other audit/fix command produces this.
> - **NO upfront path validation.** P04: `tldr diagnostics /no/such/dir` returns exit 0 with ruff's `E902` warning (NOT an error from the CLI itself). The engine shells out to tools and tools report the missing path. **Recovery:** verify path exists externally OR check `tools_run[].diagnostic_count` for sentinel `E902` codes.
> - **EXIT 1 ON ERRORS** (P01, P02). Like `tldr bugbot`, ANY error-severity finding causes exit 1 — perfect for CI gating. Use `--severity warning` filter or omit `--strict` to control.
> - **`--strict` fails on WARNINGS** (not just errors). Useful for "zero-warning" enforcement.
> - **`--baseline`/`--save-baseline` enable diff workflow** (Phase 12 per source). `--save-baseline baseline.json` snapshots; later `--baseline baseline.json` shows only NEW issues. Critical for managing technical debt without flooding the PR.
> - **Tool versions are echoed in `tools_run[].version`.** Observed: `"ruff 0.15.12"`, `"pyright 1.1.409"`. Pin tool versions for reproducible CI.
> - **`--tools`, `--ignore` are COMMA-SEPARATED** (value_delimiter = ',' in clap). Pass `--ignore E501,F401` not `--ignore "E501 F401"`.
> - **NO daemon route.** Tool invocations are not cached.
>
> **Command:** `tldr diagnostics [PATH]`
>
> **With common flags:** `tldr diagnostics <PATH> --tools pyright,ruff --output sarif > diagnostics.sarif` (use for CI: pin tools, output SARIF for GitHub Code Scanning upload).
