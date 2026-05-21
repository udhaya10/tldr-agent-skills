# Command: `tldr invariants`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; invariants is AST-based Daikon-lite, non-semantic) |
| Target repo | N/A — fixture-driven (Stock-Monitor has no canonical pytest test suite for src + tests pairing) |
| Fixtures | `research/fixtures/invariants/{src.py, test_src.py}` (3 functions: `add`, `clamp`, `divide` + 6 pytest test functions) |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr invariants` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`invariants.probes/probe.sh`](./invariants.probes/probe.sh).

---

## Ground Truth (`tldr invariants --help`)

```text
Infer invariants from test execution traces (Daikon-lite)

Usage: tldr invariants [OPTIONS] --from-tests <FROM_TESTS> <FILE>

Arguments:
  <FILE>
          Source file containing functions to analyze

Options:
  -t, --from-tests <FROM_TESTS>
          Test file or directory for tracing

      --function <FUNCTION>
          Filter to specific function

      --min-obs <MIN_OBS>
          Minimum observations required to report an invariant

          [default: 1]

  -l, --lang <LANG>
          Language override (auto-detected if not specified).

          MUST stay typed as `Option<Language>` to match the global `--lang` / `-l` flag declared on `Cli` in `main.rs`. clap stores the value once under the long-name key; if the local arg's type diverges from the global type, accessing `lang` triggers a type-id downcast panic in `clap_builder::parser::error::Error`. (P11.BUG-AGG-2)

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
| Typical output size | medium (~350 lines for 3 funcs × 4 tests each) |

**Top-level keys (JSON, `InvariantsReport`):**
- `functions` (`array<FunctionInvariants>`) — per-function inferred invariants
- `summary` (`object`) — `{ total_observations, total_invariants, by_kind, test_files_scanned, test_functions_scanned }`

**`FunctionInvariants` shape:**
- `function_name` (`string`)
- `preconditions` (`array<Invariant>`)
- `postconditions` (`array<Invariant>`)
- `observations` (`u32`) — call count from tests

**`Invariant` shape:**
- `variable` (`string`) — `"arg0"`, `"arg1"`, ..., `"result"` (positional naming!)
- `kind` (`string`) — observed: `"type"`, `"non_null"`, `"non_negative"`, `"positive"`, `"range"`, `"relation"`
- `expression` (`string`) — human-readable form (e.g., `"arg0: int"`, `"0 <= arg0 <= 10"`, `"arg1 < arg2"`)
- `confidence` (`string`) — `"high"`, `"medium"`, `"low"` (based on observation count: 12 obs → high; 6 obs → medium)
- `observations` (`u32`) — number of calls supporting this invariant
- `counterexample_count` (`u32`) — number of observations violating it (0 for confirmed invariants)

**Empty-result shape (P10/P11):**
```json
{
  "functions": [],
  "summary": { "total_observations": 32, "total_invariants": 0, "by_kind": {},
               "test_files_scanned": 1, "test_functions_scanned": 6 }
}
```
Summary STILL populated — test files were scanned, but no function-level invariants survived the filter.

**Error shapes (ContractsError-based):**
- Missing FILE: clap-style → exit **2**
- Missing `--from-tests`: clap-style → exit **2**
- Source file not found: `"Error: file not found: /no/such/file.py"` → exit **1** (lowercase "file" — matches `tldr chop`, `tldr contracts`)
- **Test path not found:** `"Error: test path not found: /no/such/tests"` → exit **1** (**DISTINCT error variant `ContractsError::TestPathNotFound`**)
- Format reject: `"Error: --format sarif not supported by invariants. ..."` → exit **1**
- Bad `--lang`: clap-style → exit **2**
- Bad legacy `-o` value: clap-style `"invalid value 'wat' for '--output-format <OUTPUT_FORMAT>' [possible values: json, text]"` → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr invariants src.py --from-tests test_src.py` | happy | 0 | [`01-happy.*`](./invariants.probes/) |
| P02 | `tldr invariants src.py --from-tests test_src.py --function clamp` | happy-scale (filtered) | 0 | [`02-happy-scale.*`](./invariants.probes/) |
| P03 | `tldr invariants --from-tests <tests>` *(no FILE)* | failure-missing-input | 2 | [`03-missing-arg.*`](./invariants.probes/) |
| P04 | `tldr invariants /no/such/file.py --from-tests <tests>` | bad source FILE | 1 | [`04-badpath.*`](./invariants.probes/) |
| P05 | `tldr invariants ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./invariants.probes/) |
| P06 | `tldr invariants ... -f text` | format-text | 0 | [`06-format-text.*`](./invariants.probes/) |
| P07 | `tldr invariants ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./invariants.probes/) |
| P08 | `tldr invariants ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./invariants.probes/) |
| P09 | `tldr invariants ... --min-obs 5` | min-obs mid | 0 | [`09-min-obs-mid.*`](./invariants.probes/) |
| P10 | `tldr invariants ... --min-obs 999` | min-obs high (silent empty) | 0 | [`10-min-obs-high.*`](./invariants.probes/) |
| P11 | `tldr invariants ... --function no_such_function` | function-not-found (silent) | 0 | [`11-function-not-found.*`](./invariants.probes/) |
| P12 | `tldr invariants <file>` *(no --from-tests)* | missing --from-tests | 2 | [`12-missing-from-tests.*`](./invariants.probes/) |
| P13 | `tldr invariants <file> --from-tests /no/such` | bad --from-tests path | 1 | [`13-bad-from-tests.*`](./invariants.probes/) |
| P14 | `tldr invariants src.py --from-tests src.py` | --from-tests = source | 0 | [`14-from-tests-not-tests.*`](./invariants.probes/) |
| P15 | `tldr invariants ... -l brainfuck` | bad-lang | 2 | [`15-bad-lang.*`](./invariants.probes/) |
| P16 | `tldr invariants ... -l python` | lang-python explicit | 0 | [`16-lang-python.*`](./invariants.probes/) |
| P17 | `tldr invariants ... -l typescript` | lang-mismatch | 0 | [`17-lang-mismatch.*`](./invariants.probes/) |
| P18 | `tldr invariants ... -o text` | legacy output text | 0 | [`18-output-flag-text.*`](./invariants.probes/) |
| P19 | `tldr invariants ... -o wat` | bad legacy -o value | 2 | [`19-output-flag-bogus.*`](./invariants.probes/) |
| P20 | `tldr invariants src.py --from-tests <dir>` | --from-tests as directory | 0 | [`20-from-tests-dir.*`](./invariants.probes/) |
| P21 | `tldr invariants ... -q` | quiet | 0 | [`21-quiet.*`](./invariants.probes/) |
| P22 | `tldr invariants ... --min-obs 0` | min-obs zero | 0 | [`22-min-obs-zero.*`](./invariants.probes/) |

### Observations

- **P01** — `src.py + test_src.py`: 3 functions, 32 total observations, 39 invariants. For `add`: 12 observations, inferred `arg0: int` (high), `arg0 >= 0` (high), `0 <= arg0 <= 10` (range, high), plus mirror for `arg1`. Postcondition `result >= 0`, `3 <= result <= 30`. Daikon-lite working as advertised.
- **P02** — `--function clamp`: filters to one function only. 14 observations for `clamp`. Reports relation invariant `arg1 < arg2` (lo < hi) — the engine detects cross-argument relationships.
- **P03** — stderr `"error: the following required arguments were not provided: <FILE>"`, exit `2`.
- **P04** — stderr `"Error: file not found: /no/such/file.py"`, exit `1` (lowercase "file" — ContractsError::FileNotFound).
- **P05** — stderr `"Error: --format sarif not supported by invariants. ..."`, exit `1`.
- **P06** — Text format: per-function block with `"Function: add (12 observations)\n  Requires: arg0: int [high]\n  ...\n  Ensures: result > 0 [high]\n"`. Summary footer: `"32 observations, 39 invariants\n  By kind: non_null: 10, range: 8, positive: 5, relation: 2, type: 10, non_negative: 4"`.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by invariants. ..."`, exit `1`.
- **P09** — `--min-obs 5`: same output as P01 (354 lines) — all invariants in the fixture had ≥5 observations.
- **P10** — `--min-obs 999`: `functions: []` (empty) but `summary.total_observations: 32, test_files_scanned: 1, test_functions_scanned: 6` STILL POPULATED. Distinguishable from "no tests scanned" by these counts.
- **P11** — `--function no_such_function`: `functions: []` and `summary.total_observations: 0`. Exit 0 — silent empty. **`test_functions_scanned: 6` remains** indicating tests were parsed but the target function wasn't called.
- **P12** — stderr `"error: the following required arguments were not provided: --from-tests <FROM_TESTS>"`, exit `2`.
- **P13** — **DISTINCT ERROR:** stderr `"Error: test path not found: /no/such/tests"`, exit `1` (ContractsError::TestPathNotFound). **Differs from source-file-not-found wording** — agents can disambiguate which path failed validation.
- **P14** — `--from-tests src.py` (passing source as tests): exit 0 with 10-line output — empty result. Engine scans for call sites; source file doesn't have calls TO ITSELF.
- **P15** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P16** — Explicit `-l python`: identical to auto-detect.
- **P17** — `-l typescript` on Python: 354 lines (same as P01!). **`--lang` filter is SILENTLY IGNORED for this command** — engine processes the file regardless. Same anti-pattern as `tldr cohesion`/`tldr coupling`/`tldr interface`.
- **P18** — Legacy `-o text`: identical to `-f text` (P06).
- **P19** — clap-style with valid-values: `"error: invalid value 'wat' for '--output-format <OUTPUT_FORMAT>' [possible values: json, text]"`, exit `2`. Note `-o` only accepts `json` or `text` — NO compact/dot/sarif via legacy flag.
- **P20** — `--from-tests` pointing to fixtures DIRECTORY: walks all .py files in it. 354 lines — same as single-file P01 since fixture dir only contains src.py + test_src.py.
- **P21** — `-q` suppresses the `"Inferring invariants for X from Y..."` progress message.
- **P22** — `--min-obs 0`: same as default (default is 1, but 0 also includes everything). No empty-result.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/contracts/invariants.rs` (~240 lines top of file)
- `crates/tldr-core/src/contracts/invariants/...` (observation extraction, invariant inference)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/contracts/invariants.rs:73-107
#[derive(Debug, Args)]
pub struct InvariantsArgs {
    pub file: PathBuf,
    #[arg(long = "from-tests", short = 't')] pub from_tests: PathBuf,
    #[arg(long = "output-format", short = 'o', hide = true, default_value = "json")]
    pub output_format: ContractsOutputFormat,
    #[arg(long)] pub function: Option<String>,
    #[arg(long, default_value = "1")] pub min_obs: u32,
    #[arg(long, short = 'l')] pub lang: Option<Language>,
}
```
Reveals: TWO required positional/long args: `FILE` AND `--from-tests` (both required, no defaults). Legacy `-o` shorthand exists with custom value parser. Source comment on `lang` (P11.BUG-AGG-2) warns it MUST stay `Option<Language>` to match global clap registration — type-id downcast panic risk.

**Path validation (BOTH validated upfront with distinct errors):**
```rust
// invariants.rs:115-128
if !self.file.exists() {
    return Err(ContractsError::FileNotFound { path: self.file.clone() }.into());
}
if !self.from_tests.exists() {
    return Err(ContractsError::TestPathNotFound { path: self.from_tests.clone() }.into());
}
```
Reveals: TWO distinct error variants for the two paths — the wording differs (`"file not found:"` vs `"test path not found:"`) so agents can tell which path is bad.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `invariants` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route invariants.rs` returns 0 matches.

---

## Architectural Deep Dive

- **Under the hood:** Daikon-lite static implementation. Walks the test file(s) AST → finds calls to functions defined in the source file → extracts argument literal values from those call sites. Aggregates argument values across calls → infers invariants per argument (type stability, non-null, non-negative, positive, range bounds, cross-arg relations). Same for return values (when tests have `assert call() == X` patterns). Confidence assigned by observation count (12+ → high, 6 → medium, fewer → low).
- **Performance:** Cold per call. ~1ms per test file. NO daemon caching.
- **LLM cognitive load:** Surfaces the IMPLICIT contracts that test data exercises. Complements `tldr contracts` (which infers from CODE patterns); `invariants` infers from TEST DATA. Together they triangulate the actual function contract. Useful for "what does my test suite actually establish?" audits.

---

## Intent & Routing

- **User/Agent Goal:** extract behavioral invariants of functions from observed test call values — what types, what ranges, what relations hold across all tested calls.
- **When to choose this over similar tools:**
  - Over `tldr contracts`: contracts infers from code patterns (asserts, type annotations); invariants infers from test execution data. Use both for triangulation.
  - Over `tldr coverage`: coverage tells you which lines/branches were exercised; invariants tells you what VALUES were exercised.
  - Over manual test review: aggregates dozens of test calls into a single inferred contract per function.
- **Prerequisites (composition):**
  - Need an existing test suite with literal-value arguments — generated/parametrized tests may produce thinner inferences.
  - Pair with `tldr contracts <file> <fn>` to compare CODE-inferred contracts vs TEST-inferred invariants — divergence = test gaps or contract drift.

---

## Agent Synthesis

> **How to use `tldr invariants`:**
> Daikon-lite test-trace invariant inferrer. `tldr invariants <FILE> --from-tests <TESTS>` returns JSON `{ functions, summary }`. Each `FunctionInvariants` has `function_name, preconditions[], postconditions[], observations`. Each `Invariant` has `variable` (positional `arg0`, `arg1`, ..., `result`), `kind` (`type`, `non_null`, `non_negative`, `positive`, `range`, `relation`), `expression` (human-readable), `confidence` (`high`/`medium`/`low`), `observations`, `counterexample_count`. `summary` includes `test_files_scanned` and `test_functions_scanned`. Default `--min-obs 1`. Default JSON; `-f text` for per-function `Requires: ... [confidence]\n Ensures: ... [confidence]` block; `-f compact` for one-line; `sarif`/`dot` rejected. Exit codes: 0 ok (including silent empties), 1 file-not-found / test-path-not-found / format-reject, 2 missing arg / bad-lang / bad legacy -o.
>
> **Crucial Rules:**
> - **Source vs test path errors are DISTINGUISHABLE.** `tldr invariants` validates BOTH paths upfront with separate error variants: `"file not found:"` (ContractsError::FileNotFound, exit 1) for the source FILE, `"test path not found:"` (ContractsError::TestPathNotFound, exit 1) for `--from-tests`. Agents can parse stderr to identify which path failed.
> - **`--lang <X>` is silently IGNORED.** P17: `-l typescript` on a Python source returns the same Python output as default. The engine processes the file regardless of the flag. Same anti-pattern as `tldr cohesion`/`tldr coupling`/`tldr interface`. The source comment (P11.BUG-AGG-2) explains the flag MUST exist for clap type consistency — even though it doesn't affect behavior here.
> - **Variables are NAMED POSITIONALLY.** `arg0`, `arg1`, `arg2`, ..., `result`. NOT by the actual parameter names from the source signature. Mapping `arg0 → value` requires inspecting the source file or `tldr extract`'s `params` field.
> - **Confidence buckets by observation count:** roughly ≥10 → `high`, 5-9 → `medium`, fewer → `low` (empirically observed; not externally documented). Use `--min-obs N` to filter; default 1 = report everything.
> - **`--min-obs 999` returns empty `functions[]` BUT summary still populated.** P10: `summary.total_observations: 32, test_files_scanned: 1, test_functions_scanned: 6` indicate tests were scanned successfully — distinguishable from "no tests parsed" cases by these counts.
> - **`--from-tests` accepts file OR directory.** Directory walks all source files in it (P20).
> - **`kind` values observed:** `type` (inferred parameter type), `non_null`, `non_negative` (`x >= 0`), `positive` (`x > 0`), `range` (`a <= x <= b`), `relation` (`arg1 < arg2`). The relation kind is the most valuable Daikon insight — cross-argument relationships.
> - **Legacy `-o` only supports `json` and `text`** (NO compact/dot/sarif via legacy flag). P19: clap rejects `-o compact` despite global -f supporting it.
> - **Test functions ARE counted, but only call sites contribute.** `test_functions_scanned: 6` (6 test functions in fixture); `total_observations: 32` (total call sites to source functions across all tests).
> - **NO daemon route.** Every call re-parses both source and tests.
>
> **Command:** `tldr invariants <FILE> --from-tests <TESTS> [--function <NAME>] [--min-obs N]`
>
> **With common flags:** `tldr invariants src.py --from-tests tests/ --min-obs 5 -f compact | jq '.functions[] | { function_name, high_confidence_invariants: ([.preconditions[], .postconditions[]] | map(select(.confidence == "high"))) }'` (use for filtering to only high-confidence invariants per function — most actionable for contract verification).
