# Command: `tldr whatbreaks`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; whatbreaks itself is non-semantic; wraps impact/importers/change-impact) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr whatbreaks` does **not** call `try_daemon_route` (verified by grep). Sub-analyses may use the daemon individually |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`whatbreaks.probes/probe.sh`](./whatbreaks.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/trace/whatbreaks.md).

---

## Ground Truth (`tldr whatbreaks --help`)

```text
Analyze what breaks if a target is changed

Usage: tldr whatbreaks [OPTIONS] <TARGET> [PATH]

Arguments:
  <TARGET>
          Target to analyze (function name, file path, or module name)

  [PATH]
          Project root directory (default: current directory)

          [default: .]

Options:
  -t, --type <TARGET_TYPE>
          Force target type (overrides auto-detection)

          Possible values:
          - function: Function name - run impact analysis
          - file:     File path - run importers + change-impact
          - module:   Module name - run importers

  -d, --depth <DEPTH>
          Maximum depth for impact/caller traversal

          [default: 3]

      --quick
          Skip slow analyses (diff-impact)

  -l, --lang <LANG>
          Programming language (auto-detect if not specified)

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
| Typical output size | small text (~6 lines) to medium JSON (~150 lines for function target with full sub-results) |

**Top-level keys (JSON, `WhatbreaksReport`):**
- `wrapper` (`string`) — always `"whatbreaks"` (self-identifier)
- `path` (`string`) — input PATH
- `target` (`string`) — input TARGET verbatim
- `target_type` (`string`) — `"function"`, `"file"`, or `"module"` (auto-detected OR forced via `--type`)
- `detection_reason` (`string`) — human-readable explanation of how target_type was determined (e.g., `"Target 'X' does not match file or module patterns (defaulting to function)"`, `"Path 'X' contains path separator"`, `"Forced via --type flag to Function"`)
- `sub_results` (`object`) — per-analysis results keyed by analysis name (`impact`, `importers`, `change-impact`)
- `summary` (`object`) — aggregated counters (`direct_caller_count`, `transitive_caller_count`, `importer_count`, `affected_test_count`)
- `total_elapsed_ms` (`float64`) — total wall-clock time

**`sub_results.<analysis>` shape:**
- `success` (`bool`) — **the failure indicator** (not exit code!). On `false`, an `error` string field is set instead of `data`.
- `data` (`object`, present when `success: true`) — analysis-specific result
- `error` (`string`, present when `success: false`) — error message from the underlying analyzer
- `elapsed_ms` (`float64`)

**Sub-analyses dispatched by target_type:**
- `function` → `impact` (caller traversal up to `--depth`)
- `file` → `importers` + `change-impact` (the latter is "slow" and is skipped by `--quick`)
- `module` → `importers` only

**Text format (`-f text`):** ultra-minimal:
```text
What Breaks: <target> (<target_type>)

Direct callers:     N
Transitive callers: M
```

**Target-not-found shape (P18):**
```json
{
  "wrapper": "whatbreaks", "path": "backend",
  "target": "no_such_function_anywhere",
  "target_type": "function",
  "detection_reason": "Target 'X' does not match file or module patterns (defaulting to function)",
  "sub_results": {
    "impact": {
      "success": false,
      "error": "Function not found: no_such_function_anywhere",
      "elapsed_ms": 131.83
    }
  },
  "summary": { "direct_caller_count": 0, ... },
  "total_elapsed_ms": 4162.65
}
```
**Exit code 0** — the failure is buried in `sub_results.impact.success: false`. Agents MUST inspect sub-result success flags; cannot rely on the process exit code.

**Error shapes:**
- Missing TARGET: clap-style `"error: the following required arguments were not provided: <TARGET> …"` → exit **2**
- Path not found: `"Error: Path not found: /no/such/dir"` → exit **1** (uses `require_directory`)
- Path is a file: `"Error: whatbreaks requires a directory; got file 'X'. Pass the project root or omit the argument to use the current directory."` → exit **1** (cli-error-clarity-v2)
- Bad `--type`: clap-style with valid-values list → exit **2**
- Bad `--lang`: clap-style → exit **2**
- Format reject: standard sarif/dot not-supported → exit **1**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr whatbreaks fetch_historical_data backend -l python` | happy (auto-function) | 0 | [`01-happy-function.*`](./whatbreaks.probes/) |
| P02 | `tldr whatbreaks backend/providers/base.py backend -l python` | happy (auto-file) | 0 | [`02-happy-file.*`](./whatbreaks.probes/) |
| P03 | `tldr whatbreaks` *(no TARGET)* | failure-missing-input | 2 | [`03-missing-arg.*`](./whatbreaks.probes/) |
| P04 | `tldr whatbreaks foo /no/such/dir` | failure-badpath | 1 | [`04-badpath.*`](./whatbreaks.probes/) |
| P05 | `tldr whatbreaks ... -f sarif` | format-reject | 1 | [`05-format-reject-sarif.*`](./whatbreaks.probes/) |
| P06 | `tldr whatbreaks ... -f text` | format-text (minimal) | 0 | [`06-format-text.*`](./whatbreaks.probes/) |
| P07 | `tldr whatbreaks ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./whatbreaks.probes/) |
| P08 | `tldr whatbreaks ... -f dot` | format-reject-dot | 1 | [`08-format-reject-dot.*`](./whatbreaks.probes/) |
| P09 | `tldr whatbreaks <file> --type function` | force-function-on-file (fails inside sub-result) | 0 | [`09-type-function.*`](./whatbreaks.probes/) |
| P10 | `tldr whatbreaks <fn> --type file` | force-file-on-function (empty sub-result) | 0 | [`10-type-file.*`](./whatbreaks.probes/) |
| P11 | `tldr whatbreaks <dotted> --type module` | force-module | 0 | [`11-type-module.*`](./whatbreaks.probes/) |
| P12 | `tldr whatbreaks ... --type widget` | bad-type (clap) | 2 | [`12-type-bogus.*`](./whatbreaks.probes/) |
| P13 | `tldr whatbreaks ... -d 1` | depth-one | 0 | [`13-depth-one.*`](./whatbreaks.probes/) |
| P14 | `tldr whatbreaks ... -d 10` | depth-ten | 0 | [`14-depth-ten.*`](./whatbreaks.probes/) |
| P15 | `tldr whatbreaks <file> --quick` | quick (skip change-impact) | 0 | [`15-quick.*`](./whatbreaks.probes/) |
| P16 | `tldr whatbreaks foo backend/providers/base.py` | file-as-path (clear error) | 1 | [`16-file-as-path.*`](./whatbreaks.probes/) |
| P17 | `tldr whatbreaks ... -l brainfuck` | bad-lang | 2 | [`17-bad-lang.*`](./whatbreaks.probes/) |
| P18 | `tldr whatbreaks no_such_function_anywhere backend` | target-not-found (exit 0) | 0 | [`18-target-not-found.*`](./whatbreaks.probes/) |
| P19 | `tldr whatbreaks ... -q` | quiet | 0 | [`19-quiet.*`](./whatbreaks.probes/) |
| P20 | `tldr whatbreaks backend.providers.base backend -l python` | module-autodetect (misclassified as function!) | 0 | [`20-module-autodetect.*`](./whatbreaks.probes/) |

### Observations

- **P01** — `fetch_historical_data` auto-detected as `function`; runs `impact`. Result: `targets: 3` (3 defs exist), `direct_callers: 7`, `transitive_callers: 11`, `affected_test_count: 0`. Detection reason: `"Target 'fetch_historical_data' does not match file or module patterns (defaulting to function)"`. **Detection is by elimination: anything not file-shaped or module-shaped is a function.**
- **P02** — `backend/providers/base.py` (contains `/`) auto-detected as `file`; runs `importers` + `change-impact`. Total elapsed ~8186ms (importers ~150ms + change-impact ~4014ms). Detection reason: `"Path 'X' contains path separator"`.
- **P03** — stderr `"error: the following required arguments were not provided: <TARGET>"`, exit `2`.
- **P04** — stderr `"Error: Path not found: /no/such/dir"`, exit `1` (require_directory helper, but for nonexistent path the message format is the simpler bail).
- **P05** — stderr `"Error: --format sarif not supported by whatbreaks. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format is **strikingly minimal**: 4 lines for a function target. Just `What Breaks: <target> (<type>)` header + `Direct callers:` + `Transitive callers:` counts. No per-caller list in text mode. Progress messages on stderr show the target type detection result.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by whatbreaks. Use --format json. DOT is only emitted by: clones, deps, calls, impact, hubs, inheritance."`, exit `1`.
- **P09** — `--type function` on a file path (`backend/providers/base.py`): exit `0` but `sub_results.impact.success: false` with `error: "Function not found: backend/providers/base.py"`. **The wrapper EXIT CODE is 0 even though the inner analysis failed.**
- **P10** — `--type file` on a function name (`fetch_historical_data`): exit 0 with empty `change-impact.data.changed_files: []` and `importers.data.importers: []`. No failure indicator. **Silent empty result for misclassified targets.**
- **P11** — `--type module` on `backend.providers.base`: correctly runs `importers`, finds 3 importers (`__init__.py`, `dhan.py`, `yahoo.py`). Successful module-target path.
- **P12** — clap-style: `"error: invalid value 'widget' for '--type <TARGET_TYPE>' [possible values: function, file, module]"`, exit `2`.
- **P13** — `-d 1` (depth 1): smaller output (~113 lines) than default `-d 3` (P01: 145 lines) — depth IS effective.
- **P14** — `-d 10` (depth 10): same as `-d 3` (145 lines) on this scope. The depth caps at "no more callers reachable" — increasing past natural saturation has no effect.
- **P15** — `--quick` on a file target: skips `change-impact` (elapsed_ms 0.0 — but the sub_result key is still present with empty data). Total elapsed drops from 8186ms (P02) to 4184ms (50% saving).
- **P16** — **Best-in-class error:** `"Error: whatbreaks requires a directory; got file 'backend/providers/base.py'. Pass the project root or omit the argument to use the current directory."`, exit `1`. Same require_directory helper as `tldr hubs`.
- **P17** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P18** — **target-not-found returns exit 0**, with `sub_results.impact.success: false` AND `error: "Function not found: no_such_function_anywhere"` buried inside. **Agents must check `sub_results.<analysis>.success` to detect failures.** The outer process exit code is misleading.
- **P19** — `-q` suppresses both `"Analyzing what breaks if..."` AND `"Target type: ... (...)"` progress messages on stderr. Stdout JSON unaffected.
- **P20** — **Module auto-detection footgun:** `backend.providers.base` (a dotted Python module path) WITHOUT `--type` is auto-classified as `function`, NOT `module`. Detection reason: `"Target 'X' contains '.' but first part 'backend' is not a directory (qualified function name)"`. The check is PATH-relative: when PATH=`backend`, the engine looks for `backend/backend` (which doesn't exist), so treats `backend.providers.base` as a qualified function name like `Class.method`. **Fix:** use `--type module` explicitly for dotted module paths, OR run from one directory up.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/whatbreaks.rs` (119 lines — small wrapper)
- `crates/tldr-core/src/analysis/whatbreaks.rs` (target-type detection + sub-analysis dispatch)
- `crates/tldr-cli/src/path_validation.rs` (`require_directory`)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/whatbreaks.rs:53-77
#[derive(Debug, Args)]
pub struct WhatbreaksArgs {
    pub target: String,
    #[arg(default_value = ".")] pub path: PathBuf,
    #[arg(long = "type", short = 't', value_enum)]
    pub target_type: Option<TargetTypeArg>,
    #[arg(long, short = 'd', default_value = "3")] pub depth: usize,
    #[arg(long)] pub quick: bool,
    #[arg(long, short = 'l')] pub lang: Option<Language>,
}
```
Reveals: `target_type` is clap `ValueEnum` (clean rejection with valid-values list). `quick` is a plain boolean flag (no =value accepted, but always defaults to false so no toggle-off issue). No format-affecting flags beyond the global `-f`.

**Path validation via shared helper:**
```rust
// whatbreaks.rs:86
require_directory(&self.path, "whatbreaks")?;
```
Reveals: same `cli-error-clarity-v2` helper as `tldr hubs` — bad path AND file-as-path both yield clear errors with recovery hints.

**Wrapper pattern (the whole logic is ~30 lines):**
```rust
// whatbreaks.rs:81-118 (excerpt)
pub fn run(&self, format: OutputFormat, quiet: bool) -> Result<()> {
    require_directory(&self.path, "whatbreaks")?;
    let options = WhatbreaksOptions {
        depth: self.depth,
        quick: self.quick,
        language: self.lang,
        force_type: self.target_type.map(|t| t.into()),
    };
    let report = whatbreaks_analysis(&self.target, &self.path, &options)?;
    ...
}
```
Reveals: `whatbreaks` is a thin CLI shim — all decision logic (target-type detection, sub-analysis dispatch, error encapsulation) is in `tldr-core::analysis::whatbreaks::whatbreaks_analysis`. The engine returns a `WhatbreaksReport` with sub-result success flags rather than propagating individual failures as outer-level errors. **This is the structural reason exit 0 may hide inner failures.**

**Sub-result error encapsulation:**
The `sub_results` object always uses the `{ success, data | error, elapsed_ms }` envelope per analysis. Even when a sub-analysis errors, the outer `whatbreaks_analysis` returns Ok with the failure captured. This is intentional (so partial results from successful sub-analyses are preserved) but means **outer exit code = 0 does NOT imply all sub-analyses succeeded.**

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `whatbreaks` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route whatbreaks.rs` returns 0 matches. **But** the sub-analyses (`impact`, `importers`, `change-impact`) each have their OWN daemon-routing semantics — when whatbreaks runs them as a sub-step, they may individually hit the daemon. Net effect: `tldr daemon start && tldr warm` DOES benefit whatbreaks (via sub-analyses), even though the wrapper itself doesn't directly call `try_daemon_route`.

---

## Architectural Deep Dive

- **Under the hood:** Wrapper that dispatches to one of three sub-analyses based on auto-detected (or forced) target type. The detection in `tldr-core::analysis::whatbreaks` checks (1) path-separator presence → file, (2) dot-containing + first segment is a directory → module, (3) anything else → function. Sub-results are wrapped in success/error envelopes; outer call always returns Ok unless path validation fails.
- **Performance:** Cold ~4-8s on Stock-Monitor backend depending on target type. `--quick` halves the time on file targets by skipping `change-impact`. NO direct daemon route, but sub-analyses individually benefit from warm cache.
- **LLM cognitive load:** "If I change this, what breaks?" The wrapper replaces a 2-3 step `extract → impact → importers` workflow with a single invocation. The detection_reason field tells the agent how the target was classified — useful for debugging when auto-detection misfires (P20).

---

## Intent & Routing

- **User/Agent Goal:** answer "if I change X, what else might break?" — combining impact (callers), importers (dependents), and change-impact (test fan-out) into one command.
- **When to choose this over similar tools:**
  - Over `tldr impact <fn>`: `whatbreaks` auto-dispatches to impact for function targets; if you're sure it's a function, use `impact` directly.
  - Over `tldr importers <module>`: `whatbreaks` auto-dispatches to importers for file/module targets; if you know it's a module, use `importers` directly.
  - Over running all three sub-commands manually: `whatbreaks` aggregates and produces a unified summary row.
- **Prerequisites (composition):**
  - For dotted Python module paths (`backend.providers.base`), supply `--type module` explicitly to avoid the auto-detect misclassification (P20).
  - For files with no `/` separator (e.g., a bare filename), supply `--type file` to override the function default.
  - PATH must be a directory (`require_directory` rejects regular files — P16).

---

## Agent Synthesis

> **How to use `tldr whatbreaks`:**
> Unified "blast radius" analyzer. `tldr whatbreaks <TARGET> [PATH]` auto-detects whether TARGET is a function (default), file (contains `/`), or module (dotted + first segment is a directory) and dispatches to `impact`, `importers`+`change-impact`, or `importers` respectively. JSON output has top-level `wrapper`, `target_type`, `detection_reason`, `sub_results` (per-analysis envelope), `summary` (aggregated counters), `total_elapsed_ms`. Use `--type {function,file,module}` to override auto-detection; `--quick` to skip the slow `change-impact` step; `--depth N` for the impact traversal depth. Exit codes: 0 ok **AND ALSO 0 when sub-analyses fail** (failure encapsulated in sub_results), 1 path-not-found / path-is-file / format-reject, 2 clap missing-arg / bad `--type` / bad `--lang`.
>
> **Crucial Rules:**
> - **Exit code 0 ≠ analysis succeeded.** Failures in sub-analyses (e.g., "Function not found") return exit 0 with `sub_results.<analysis>.success: false` AND an `error` string buried inside. Agents MUST inspect `sub_results.<key>.success` for each sub-analysis to detect failures — process exit code is misleading (P09, P18).
> - **Module auto-detection is path-relative and frequently misfires for dotted Python paths.** `backend.providers.base` with PATH=`backend` is classified as `function` (not module) because the engine looks for `backend/backend/...` and doesn't find it. **Fix:** always pass `--type module` for dotted module paths, OR cd one directory up so the first segment matches a real directory (P20).
> - **Detection by elimination defaults to function.** Anything not containing `/` and not matching the module heuristic is treated as a function. A bare filename (e.g., `base.py`) is treated as a function name (which won't be found in the call graph), yielding exit 0 with sub_results.impact.success: false. Use `--type file` for bare filenames.
> - **`--quick` skips `change-impact`** which is the slowest sub-analysis. Halves total elapsed time for file targets (P15: ~4s vs ~8s). Quick mode keeps `importers` (fast) and `impact` (when applicable).
> - **`--depth` caps at natural saturation.** P14: `-d 10` produces the same output as `-d 3` on a small scope because all reachable callers are within depth 3. No "depth was clamped" indicator in the output; agents can't detect saturation directly.
> - **Text format is ultra-minimal.** P06: just 4 lines (`What Breaks:`, `Direct callers:`, `Transitive callers:`). Per-caller details are JSON-only — use `-f json` or `-f compact` when you need actual call sites.
> - **NO daemon route at the wrapper level, but sub-analyses use the daemon.** `tldr daemon start && tldr warm` DOES speed up whatbreaks via its sub-calls to `impact`/`importers`. The wrapper itself just dispatches.
> - **`require_directory` gives best-in-class path errors.** Path-not-found yields the generic message; path-is-file yields a clear `"whatbreaks requires a directory; got file 'X'. Pass the project root or omit the argument to use the current directory."` (P16).
>
> **Command:** `tldr whatbreaks <TARGET> [PATH] -l <lang>`
>
> **With common flags:** `tldr whatbreaks <TARGET> <PATH> -l <lang> --type module --quick -f compact` (use for fast module-blast-radius lookup; `--type module` avoids the auto-detect misfire on dotted Python paths and `--quick` skips the slow change-impact pass).
