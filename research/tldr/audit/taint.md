# Command: `tldr taint`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; taint uses CFG/DFG internal engines, non-semantic) |
| Target repo | N/A — fixture-driven per Journal 04 §13 (SQL/web/shell sinks) |
| Fixtures | `research/fixtures/taint/sinks.py` (6 functions: vulnerable_sql, safe_sql, vulnerable_shell, vulnerable_eval, safe_function, vulnerable_path) |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr taint` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`taint.probes/probe.sh`](./taint.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/audit/taint.md).

---

## Ground Truth (`tldr taint --help`)

```text
Analyze taint flows to detect security vulnerabilities

Usage: tldr taint [OPTIONS] <FILE> <FUNCTION>

Arguments:
  <FILE>
          Source file to analyze

  <FUNCTION>
          Function name to analyze

Options:
  -l, --lang <LANG>
          Programming language (auto-detected from file extension if not specified)

  -v, --verbose
          Show verbose output with tainted variables per block

  -f, --format <FORMAT>
          Output format

          Supported by every command: json, text, compact.

          Command-specific formats (rejected at runtime by other commands): sarif  — only: vuln, clones dot    — only: calls, impact, hubs, inheritance, clones, deps

          cli-error-clarity-v2 (P2.BUG-5): possible values are hidden on the global help to avoid promising sarif/dot for every subcommand. Run `tldr <cmd> --help` to confirm what a specific command emits, and see `validate_format_for_command` in `output.rs` for the source of truth.

          [default: json]

  -q, --quiet
          Suppress progress output

  -h, --help
          Print help (see a summary with '-h')
```

---

## Output Shape

| Aspect | Value |
|---|---|
| Default format | `json` |
| Formats that work | `json`, `text` (P01, P06) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| **Format BROKEN** | **`compact` returns pretty JSON (same as `tldr resources` bug)** |
| Typical output size | small (~20 lines pretty JSON) |

**Top-level keys (JSON, `TaintReport`):**
- `function` (`string`) — input function name echoed
- `tainted_vars` (`object`, keyed by block ID as string) — per-CFG-block tainted variable lists. Block IDs are strings (`"0"`, `"1"`, `"2"`).
- `sources` (`array<Source>`) — detected taint sources (input points)
- `sinks` (`array<Sink>`) — detected dangerous sinks (output points)
- `flows` (`array<Flow>`) — source-to-sink connections (often empty even when sources + sinks present!)
- `sanitized_vars` (`array<string>`) — variables that pass through sanitizers

**`Source` shape:** `{ var, line, source_type, statement }`. Observed `source_type` values: `"file_read"`.

**`Sink` shape:** `{ var, line, sink_type, tainted (bool), statement }`. Observed `sink_type` values: `"sql_query"`, `"shell_exec"`, `"file_open"`. `tainted: true` only when taint flow reaches the sink.

**Empty-result shape (P14 safe_function):**
```json
{
  "function": "safe_function",
  "tainted_vars": { "0": [], "1": [], "2": [] },
  "sources": [], "sinks": [], "flows": [], "sanitized_vars": []
}
```
Exit 0. `tainted_vars` keys (block IDs) ARE present even with no taint — CFG blocks exist.

**Error shapes:**
- Missing FUNCTION: clap-style → exit **2**
- File not found: `"Error: File not found: /no/such/file.py"` → exit **1** (anyhow! — capital `F` "File")
- Function not found: `"Error: Function not found: <name>"` → exit **20** (TldrError::FunctionNotFound — matches `tldr complexity`/`tldr explain`)
- Directory as FILE: `"Error: Is a directory (os error 21)"` → exit **1** (**raw OS error leaks — same bug as `tldr resources`**)
- Format reject: `"Error: --format sarif not supported by taint. ..."` → exit **1**
- Bad `--lang`: clap-style → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr taint sinks.py vulnerable_sql` | happy (sink found, NO source) | 0 | [`01-happy.*`](./taint.probes/) |
| P02 | `tldr taint sinks.py vulnerable_shell` | happy-scale (shell sink) | 0 | [`02-happy-scale.*`](./taint.probes/) |
| P03 | `tldr taint sinks.py` *(no FUNCTION)* | failure-missing-input | 2 | [`03-missing-arg.*`](./taint.probes/) |
| P04 | `tldr taint /no/such/file.py vulnerable_sql` | failure-badpath | 1 | [`04-badpath.*`](./taint.probes/) |
| P05 | `tldr taint ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./taint.probes/) |
| P06 | `tldr taint ... -f text` | format-text | 0 | [`06-format-text.*`](./taint.probes/) |
| P07 | `tldr taint ... -f compact` | **format-compact BROKEN (pretty JSON)** | 0 | [`07-format-compact.*`](./taint.probes/) |
| P08 | `tldr taint ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./taint.probes/) |
| P09 | `tldr taint ... --verbose` | **--verbose IGNORED** | 0 | [`09-verbose.*`](./taint.probes/) |
| P10 | `tldr taint ... no_such_function` | function-not-found | 20 | [`10-function-not-found.*`](./taint.probes/) |
| P11 | `tldr taint ... -l python` | explicit-python | 0 | [`11-lang-python.*`](./taint.probes/) |
| P12 | `tldr taint ... -l typescript` | lang-mismatch (function-not-found) | 20 | [`12-lang-mismatch.*`](./taint.probes/) |
| P13 | `tldr taint ... -l brainfuck` | bad-lang | 2 | [`13-bad-lang.*`](./taint.probes/) |
| P14 | `tldr taint sinks.py safe_function` | no-taint baseline | 0 | [`14-safe-function.*`](./taint.probes/) |
| P15 | `tldr taint sinks.py safe_sql` | safe parameterized SQL (sink STILL detected!) | 0 | [`15-safe-sql.*`](./taint.probes/) |
| P16 | `tldr taint sinks.py vulnerable_eval` | eval sink | 0 | [`16-eval-sink.*`](./taint.probes/) |
| P17 | `tldr taint sinks.py vulnerable_path` | file-open sink WITH source + tainted=true | 0 | [`17-path-sink.*`](./taint.probes/) |
| P18 | `tldr taint ... -q` | quiet | 0 | [`18-quiet.*`](./taint.probes/) |
| P19 | `tldr taint README.md anything` | non-source-md (silent Python fallback) | 20 | [`19-non-source-md.*`](./taint.probes/) |
| P20 | `tldr taint <fixture-dir> vulnerable_sql` | directory-as-FILE (raw OS error) | 1 | [`20-directory-arg.*`](./taint.probes/) |

### Observations

- **P01** — `vulnerable_sql(user_id)`: detects `sink: { var: "query", line: 13, sink_type: "sql_query", tainted: false, statement: "cursor.execute(query)" }`. **`sources: []`** — the function parameter `user_id` is NOT detected as a taint source. **Insight:** the taint engine looks for EXTERNAL sources (file_read, request, input()) — function parameters are not auto-tainted. The sink IS flagged, but `tainted: false` because no source reaches it. This is a major limitation for "function-only" taint analysis.
- **P02** — `vulnerable_shell(filename)`: 2 sinks detected (one for `True` and one for `cmd` — the engine emits sinks for each var-of-interest at the call site). Same pattern: `tainted: false` because no detected source.
- **P03** — stderr `"error: the following required arguments were not provided: <FUNCTION>"`, exit `2`.
- **P04** — stderr `"Error: File not found: /no/such/file.py"`, exit `1` (anyhow!, CAPITAL F). Matches `tldr churn`/`tldr debt` pattern.
- **P05** — stderr `"Error: --format sarif not supported by taint. ..."`, exit `1`.
- **P06** — Text format: 13 lines, human-readable taint report.
- **P07** — **`-f compact` BUG: returns PRETTY JSON identical to default.** Byte-identical sizes verified (327 bytes both). Same bug class as `tldr resources` P07. Workaround: pipe to `jq -c`.
- **P08** — stderr `"Error: --format dot not supported by taint. ..."`, exit `1`.
- **P09** — **`--verbose` IGNORED:** output BYTE-IDENTICAL to P01 (verified via `diff`). The flag is parsed but has no observable effect on JSON output in this scope.
- **P10** — stderr `"Error: Function not found: no_such_function"`, exit `20` (TldrError::FunctionNotFound). Matches `tldr complexity`/`tldr explain`/`tldr impact`/`tldr available`.
- **P11** — Explicit `-l python`: identical to default (Python auto-detected).
- **P12** — `-l typescript` on `.py`: stderr `"Error: Function not found: vulnerable_sql"`, exit `20`. **Same misleading-error anti-pattern** as `tldr complexity`/`tldr dead-stores`/`tldr contracts`: TS parser walks Python source, fails to find function. Misleading — blames function name, not language mismatch.
- **P13** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P14** — `safe_function(value)`: no sources, no sinks (just `result = value * 2`). Confirms taint engine doesn't flag arithmetic-only functions.
- **P15** — **CONSERVATIVE DETECTION:** `safe_sql(user_id)` uses parameterized query `cursor.execute("...", (user_id,))`. Still emits sink: `{ var: "cursor", line: 21, sink_type: "sql_query", tainted: false, statement: "cursor.execute(...)" }`. **The engine flags ALL `cursor.execute` calls as sinks regardless of parameterization** — distinction is in the `tainted` flag (false when no source reaches). Agents must check `tainted: true` to find actual vulnerabilities.
- **P16** — `vulnerable_eval(user_expr)`: sink detected with `sink_type` (likely `"code_exec"` or similar).
- **P17** — **DETECTED FLOW:** `vulnerable_path(user_path)`: 1 source (`f` at line 46, `source_type: "file_read"`), 3 sinks (`os, user_path, full` at file_open lines), one sink marked `tainted: true` (`os` at line 44). **`flows: []` is STILL empty** even with detected taint! Engine reports the tainted flag but doesn't emit explicit flow paths. Possible source-comment-drift.
- **P18** — `-q` suppresses the `"Analyzing taint flows for <fn> in <file>..."` progress message.
- **P19** — `README.md` with FUNCTION "anything": stderr `"Error: Function not found: anything"`, exit `20`. **Confirms silent Python fallback:** `Language::from_path(README.md).unwrap_or(Language::Python)` defaults to Python; Python parser tries to parse README as Python, fails to find `anything`. No "unsupported language" error.
- **P20** — Directory as FILE: stderr `"Error: Is a directory (os error 21)"`, exit `1`. **Raw OS error leaks through** — same bug as `tldr resources` P23. The CLI checks `path.exists()` (passes for dirs) but the engine's `fs::read_to_string()` fails.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/taint.rs` (~200+ lines)
- `crates/tldr-core/src/security/taint.rs` (taint propagation engine)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/taint.rs:34-48
#[derive(Debug, Args)]
pub struct TaintArgs {
    pub file: PathBuf,
    pub function: String,
    #[arg(long, short = 'l')] pub lang: Option<Language>,
    #[arg(long, short = 'v')] pub verbose: bool,
}
```
Reveals: minimal struct. `--verbose` exists but observed not to affect output (P09).

**Silent Python fallback:**
```rust
// taint.rs:58-60
let language = self
    .lang
    .unwrap_or_else(|| Language::from_path(&self.file).unwrap_or(Language::Python));
```
Reveals: when language can't be auto-detected (e.g., `.md` file), the engine defaults to Python. Source-comment drift potential: README.md is parsed AS PYTHON without warning. **Worst-quality language-detection fallback** in the audit suite — `tldr contracts` does the opposite (FM-22 explicit no-silent-Python-fallback).

**Path validation:**
```rust
// taint.rs:69-71
if !self.file.exists() {
    return Err(anyhow::anyhow!("File not found: {}", self.file.display()));
}
```
Reveals: anyhow! → exit 1, capital `F` in "File not found:". No `is_file()` check upfront — directory passes `exists()` and fails later in `fs::read_to_string()`.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `taint` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route taint.rs` returns 0 matches.

---

## Architectural Deep Dive

- **Under the hood:** Builds CFG (control flow graph) + DFG (data flow graph) for the target function. Walks blocks, propagates taint from registered sources (file reads, network input, user input) through assignments. Flags variables reaching registered sinks (sql_query, shell_exec, file_open, code_exec). The `tainted` flag on each sink indicates whether taint propagation reaches it. `flows: []` would list source→sink chains; observed empty even when `tainted: true` (possible engine limitation).
- **Performance:** Cold ~10-50ms per function (CFG + DFG build is the cost). NO daemon caching.
- **LLM cognitive load:** Function-scoped security audit. Key signal: `sinks[].tainted: true` = actual vulnerability. `sinks[].tainted: false` with non-empty sinks = "use of dangerous API but no traced flow" (still review-worthy). Function parameters are NOT auto-tainted — for parameter-as-source analysis, use `tldr vuln` or `tldr secure`.

---

## Intent & Routing

- **User/Agent Goal:** trace taint from external sources to dangerous sinks within ONE function — find SQL injection, command injection, path traversal vulnerabilities.
- **When to choose this over similar tools:**
  - Over `tldr secure --quick`: secure aggregates many analyses across many files; taint is per-function.
  - Over `tldr vuln`: vuln matches CVE patterns; taint traces data flow.
  - Over manual review: CFG+DFG-driven, considers all paths.
- **Prerequisites (composition):**
  - Pass a single FILE; directories error with raw OS error (P20).
  - Function name must exist in the source — wrong name OR wrong language both produce exit 20.
  - **For full-file or full-project scanning, this command is NOT the right tool** — it's strictly per-function.
  - For LLM workflows, parse `sinks[].tainted` to filter actual vulnerabilities from "API usage detected".

---

## Agent Synthesis

> **How to use `tldr taint`:**
> Per-function CFG/DFG-driven taint-flow analyzer. `tldr taint <FILE> <FUNCTION>` returns JSON `{ function, tainted_vars, sources, sinks, flows, sanitized_vars }`. `tainted_vars` is keyed by CFG block ID (string `"0"`, `"1"`, ...). Each `Source` has `{ var, line, source_type, statement }`; each `Sink` has `{ var, line, sink_type, tainted (bool!), statement }`. Sink types: `sql_query, shell_exec, file_open, code_exec`. Source types: `file_read` (others likely exist). Default JSON; `-f text` for report; **`-f compact` is BROKEN (returns pretty JSON)**; `sarif`/`dot` rejected. Exit codes: 0 ok (including empty taint), 1 file-not-found / directory-arg-raw-OS-error / format-reject, 2 missing FUNCTION / bad-lang, 20 function-not-found.
>
> **Crucial Rules:**
> - **Function PARAMETERS are NOT taint sources.** P01: `vulnerable_sql(user_id)` with `cursor.execute("SELECT ... " + user_id)` flags the SQL sink but reports `sources: []` and `tainted: false`. **Major limitation** — the engine only detects EXPLICIT sources (file reads, network input, user input calls). For parameter-as-source, use `tldr vuln` or `tldr secure`.
> - **`tainted: false` on a detected sink means "API used but no flow traced".** Agents filtering for actual vulnerabilities must check `sinks[*].tainted == true`. P15: `safe_sql` (parameterized) STILL emits the sink with `tainted: false` — engine is conservative.
> - **`flows: []` may be empty even when `sinks[].tainted: true`** (P17). Possible engine limitation — the `tainted` flag indicates flow detection but explicit flow paths aren't always emitted. Don't rely on `flows[]` length to determine vulnerability count; use `sinks[].tainted` instead.
> - **`-f compact` IS BROKEN** — returns pretty JSON byte-identical to default (P07: 327 bytes both). Same bug class as `tldr resources`. Workaround: pipe through `jq -c`.
> - **`--verbose` flag is IGNORED.** P09: output is byte-identical to default. The flag is parsed by clap but has no observable effect on JSON output. Possible engine no-op or text-only effect.
> - **Silent Python fallback** (taint.rs:58-60): `Language::from_path(...).unwrap_or(Language::Python)`. README.md is parsed as Python and yields function-not-found (P19, exit 20). **No unsupported-language error.** Distinct from `tldr contracts` (FM-22 explicit-no-fallback) and `tldr halstead` (exit 11). Worst language-detection in the audit suite.
> - **`-l typescript` on `.py` yields MISLEADING "Function not found: <name>"** (exit 20). TS parser walks Python source, fails to find function. Same anti-pattern as `tldr complexity`/`tldr dead-stores`/`tldr contracts`.
> - **Directory as FILE leaks raw OS error** (`"Is a directory (os error 21)"`). Same bug as `tldr resources` P23.
> - **File-not-found wording uses CAPITAL `F`** ("Error: File not found:"). Differs from lowercase variants (`tldr chop`/`tldr contracts`/`tldr resources` use `"file not found:"`). Cross-command wording inconsistency.
> - **NO daemon route.** Every call rebuilds CFG + DFG.
> - **Function-not-found exit code is 20** (TldrError::FunctionNotFound — matches `tldr complexity`/`tldr explain`/`tldr impact`/`tldr available`).
>
> **Command:** `tldr taint <FILE> <FUNCTION>`
>
> **With common flags:** `tldr taint <FILE> <FN> | jq '.sinks | map(select(.tainted == true))'` (use to filter to ONLY actually-tainted sinks — the actionable vulnerability list, ignoring "API used but no traced flow" noise).
